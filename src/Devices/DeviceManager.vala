using Gee;

public class BeatBox.DeviceManager : GLib.Object {
	LibraryManager lm;
	VolumeMonitor vm;
	LinkedList<Device> devices;
	
	public signal void device_added(Device d);
	public signal void device_removed(Device d);
	
	public DeviceManager(LibraryManager lm) {
		this.lm = lm;
		vm = VolumeMonitor.get();
		devices = new LinkedList<Device>();
		
		vm.mount_added.connect(mount_added);
		vm.mount_changed.connect(mount_changed);
		vm.mount_pre_unmount.connect(mount_pre_unmount);
		vm.mount_removed.connect(mount_removed);
	}
	
	public void loadPreExistingMounts() {
		
		// this can take time if we have to rev up the cd drive
		try {
			Thread.create<void*>(get_pre_existing_mounts, false);
		}
		catch(GLib.ThreadError err) {
			stdout.printf("ERROR: could not create mount getter thread: %s \n", err.message);
		}
	}
	
	public void* get_pre_existing_mounts () {
		var mounts = new LinkedList<Mount>();
		
		foreach(var m in vm.get_mounts()) {
			mounts.add(m);
		}
		
		Idle.add( () => {
			
			foreach(var m in mounts) {
				mount_added(m);
			}
			
			return false;
		});
		
		return null;
	}
	
	public virtual void mount_added (Mount mount) {
		foreach(var dev in devices) {
			if(dev.get_path() == mount.get_default_location().get_path()) {
				return;
			}
		}
		
		Device added;
		if(mount.get_default_location().get_uri().has_prefix("cdda://")) {
			added = new CDRomDevice(lm, mount);
		}
		else if(File.new_for_path(mount.get_default_location().get_path() + "/iTunes_Control").query_exists() ||
				File.new_for_path(mount.get_default_location().get_path() + "/iPod_Control").query_exists() ||
				File.new_for_path(mount.get_default_location().get_path() + "/iTunes/iTunes_Control").query_exists()) {
			added = new iPodDevice(lm, mount);	
		}
		else if(mount.get_default_location().get_parse_name().has_prefix("afc://")) {
			added = new iPodDevice(lm, mount);
		}
		else if(File.new_for_path(mount.get_default_location().get_path() + "/Android").query_exists()) {
			added = new AndroidDevice(mount);
		}
		else { // not a music player, ignore it
			return;
		}
		
		if(added == null) {
			stdout.printf("Found device at %s is invalid. Not using it\n", mount.get_default_location().get_parse_name());
			return;
		}
		
		added.set_mount(mount);
		devices.add(added);
		
		if(added.start_initialization()) {
			added.finish_initialization();
			added.initialized.connect(deviceInitialized);
		}
		else {
			mount_removed(added.get_mount());
		}
	}
	
	void deviceInitialized(Device d) {
		stdout.printf("adding device\n");
		device_added(d);
		lm.lw.updateSensitivities();
	}
	
	public virtual void mount_changed (Mount mount) {
		//stdout.printf("mount_changed:%s\n", mount.get_uuid());
	}
	
	public virtual void mount_pre_unmount (Mount mount) {
		//stdout.printf("mount_preunmount:%s\n", mount.get_uuid());
	}
	
	public virtual void mount_removed (Mount mount) {
		foreach(var dev in devices) {
			if(dev.get_path() == mount.get_default_location().get_path()) {
				devices.remove(dev);
				device_removed(dev);
				
				// removing temp medias
				var toRemove = new LinkedList<Media>();
				foreach(int i in dev.get_medias()) {
					Media s = lm.media_from_id(i);
					if(s.isTemporary)
						toRemove.add(s);
					else
						s.unique_status_image = null;
				}
				foreach(int i in dev.get_podcasts()) {
					Media s = lm.media_from_id(i);
					if(s.isTemporary)
						toRemove.add(s);
					else
						s.unique_status_image = null;
				}
				foreach(int i in dev.get_audiobooks()) {
					Media s = lm.media_from_id(i);
					if(s.isTemporary)
						toRemove.add(s);
					else
						s.unique_status_image = null;
				}
				lm.remove_medias(toRemove, false);
				
				return;
			}
		}
	}
}
