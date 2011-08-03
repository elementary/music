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
		vm.volume_added.connect(volume_added);
		vm.volume_changed.connect(volume_changed);
		vm.volume_removed.connect(volume_removed);
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
			
			foreach(var m in mounts)
				mount_added(m);
			
			return false;
		});
		
		return null;
	}
	
	public virtual void mount_added (Mount mount) {
		foreach(var dev in devices) {
			if(dev.getMountLocation() == mount.get_default_location().get_parse_name()) {
				return;
			}
		}
		
		stdout.printf("mount_added: %s\n", mount.get_name());
		stdout.printf(" parse_name: %s\n uri: %s\n nice_name: %s\n unix_device: %s\n test: %s\n",
						mount.get_default_location().get_parse_name(),
						mount.get_default_location().get_uri(),
						mount.get_volume().get_identifier(VOLUME_IDENTIFIER_KIND_LABEL),
						mount.get_volume().get_identifier(VOLUME_IDENTIFIER_KIND_UNIX_DEVICE),
						new UnixMountEntry(mount.get_default_location().get_path(), 0).get_device_path());
		var device = new Device(mount);
		
		stdout.printf("mount preview icon: %s\n", mount.get_default_location().query_info("*", FileQueryInfoFlags.NONE).get_attribute_string(FILE_ATTRIBUTE_PREVIEW_ICON));
		
		if(device.getContentType() == "cdrom" || device.getContentType().contains("ipod") 
			|| device.getContentType() == "android") {
			devices.add(device);
			device_added(device);
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
			if(dev.getMountLocation() == mount.get_default_location().get_parse_name()) {
				devices.remove(dev);
				device_removed(dev);
				
				return;
			}
		}
	}
	
	public void mountedCallback(Object? source_object, AsyncResult res) {
		//stdout.printf("mounted %s!\n", (string)current.get_mount().guess_content_type_sync(true, null));
	}
	
	public virtual void volume_added (Volume volume) {
		//Device d = new Device(volume);
		
		//stdout.printf("volume added: %s, %s\n", volume.get_name(), volume.get_mount().guess_content_type_sync(true, null));
		
		//Timeout.add(5000, () => { stdout.printf("volume added: %s\n", volume.get_mount().guess_content_type_sync(true, null)); return false; } );
	}
	
	public virtual void volume_changed (Volume volume) {
		//stdout.printf("volume changed: %s %s\n", volume.get_name(), volume.get_mount().guess_content_type_sync(true, null));
		
		//Timeout.add(5000, () => { stdout.printf("volume changed: %s\n", volume.get_mount().guess_content_type_sync(true, null)); return false; } );
	}
	
	public virtual void volume_removed (Volume volume) {
		//stdout.printf("volume removed: %s, %S\n", volume.get_name(), volume.get_mount().guess_content_type_sync(true, null));
		
		//Timeout.add(5000, () => { stdout.printf("volume removed: %s\n", volume.get_mount().guess_content_type_sync(true, null)); return false; } );
	}
}
