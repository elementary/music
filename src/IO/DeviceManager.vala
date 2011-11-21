using Gee;

public class BeatBox.DeviceManager : GLib.Object {
	VolumeMonitor vm;
	LinkedList<Device> devices;
	
	public signal void device_added(Device d);
	public signal void device_removed(Device d);
	
	public DeviceManager() {
		vm = VolumeMonitor.get();
		devices = new LinkedList<Device>();
		
		vm.mount_added.connect(mount_added);
		vm.mount_changed.connect(mount_changed);
		vm.mount_pre_unmount.connect(mount_pre_unmount);
		vm.mount_removed.connect(mount_removed);
		
		/*vmVfs = GnomeVFS.get_volume_monitor();
		vmVfs.volume_mounted.connect(gvfs_mounted);
		vmVfs.drive_connected.connect( () => { stdout.printf("drive connected\n"); });
		vmVfs.drive_disconnected.connect( () => { stdout.printf("drive disconnected\n"); });
		vmVfs.volume_unmounted.connect(gvfs_unmounted);
		
		var monitor = File.new_for_path("/home/scott/.gvfs").monitor_directory(FileMonitorFlags.NONE);
		
		monitor.changed.connect( () => { stdout.printf("changed\n"); });
		
		// gudev 
		GUdev.Client client = new GUdev.Client({"usb", null});
		client.uevent.connect(uevent_cb);*/
	}
	
	/*public void uevent_cb(string action, GUdev.Device device) {
		stdout.printf("action; %s\n", action);
			stdout.printf("device: %s\n", device.get_device_file());
	}*/
	
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
	
	public void add_mount(string path) {
		stdout.printf("added mount %s\n", path);
	}
	
	public virtual void mount_added (Mount mount) {
		stdout.printf("mount added at %s\n", mount.get_default_location().get_path());
		foreach(var dev in devices) {
			if(dev.get_path() == mount.get_default_location().get_path()) {
				return;
			}
		}
		
		Device added;
		if(mount.get_default_location().get_path().has_prefix("cdda://")) {
			added = new CDRomDevice(mount);
		}
		else if(File.new_for_path(mount.get_default_location().get_path() + "/iTunes_Control").query_exists() ||
				File.new_for_path(mount.get_default_location().get_path() + "/iPod_Control").query_exists() ||
				File.new_for_path(mount.get_default_location().get_path() + "/iTunes/iTunes_Control").query_exists()) {
			added = new iPodDevice(mount);	
		}
		else if(mount.get_default_location().get_parse_name().has_prefix("afc://")) {
			added = new iPodDevice(mount);
		}
		else if(File.new_for_path(mount.get_default_location().get_path() + "/Android").query_exists()) {
			added = new AndroidDevice(mount);
		}
		else { // not a music player, ignore it
			return;
		}
		
		if(added == null) {
			stdout.printf("added is null. initialization failed, meaning it is invalid. not using it\n");
			return;
		}
		
		added.set_mount(mount);
		
		devices.add(added);
		device_added(added);
		
		if(!added.initialize()) {
			mount_removed(added.get_mount());
		}
	}
	
	public virtual void mount_changed (Mount mount) {
		//stdout.printf("mount_changed:%s\n", mount.get_uuid());
	}
	
	public virtual void mount_pre_unmount (Mount mount) {
		//stdout.printf("mount_preunmount:%s\n", mount.get_uuid());
	}
	
	public virtual void mount_removed (Mount mount) {
		stdout.printf("mount_removed: %s\n", mount.get_default_location().get_parse_name());
		
		foreach(var dev in devices) {
			stdout.printf("comparing %s to %s\n", dev.get_path(), mount.get_default_location().get_path());
			if(dev.get_path() == mount.get_default_location().get_path()) {
				stdout.printf("removed %s\n", mount.get_default_location().get_path());
				devices.remove(dev);
				device_removed(dev);
				
				return;
			}
		}
	}
	
	public void gvfs_mounted(GnomeVFS.Volume volume) {
		stdout.printf("gvfs mounted\n");
	}
	
	public void gvfs_unmounted(GnomeVFS.Volume volume) {
		stdout.printf("gvfs unmounted\n");
	}
}
