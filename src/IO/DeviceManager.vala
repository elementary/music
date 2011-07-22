public class BeatBox.DeviceManager : GLib.Object {
	VolumeMonitor vm;
	Volume current;
	
	public DeviceManager() {
		vm = VolumeMonitor.get();
		
		vm.mount_added.connect(mount_added);
		vm.mount_changed.connect(mount_changed);
		vm.mount_pre_unmount.connect(mount_pre_unmount);
		vm.mount_removed.connect(mount_removed);
		vm.volume_added.connect(volume_added);
		vm.volume_changed.connect(volume_changed);
		vm.volume_removed.connect(volume_removed);
	}
	
	public virtual void mount_added (Mount mount) {
		stdout.printf("mount_added: %s\n", mount.get_name());
		stdout.printf(" parse_name: %s\n uri: %s\n nice_name: %s\n unix_device: %s\n",
						mount.get_default_location().get_parse_name(),
						mount.get_default_location().get_uri(),
						mount.get_volume().get_identifier(VOLUME_IDENTIFIER_KIND_LABEL),
						mount.get_volume().get_identifier(VOLUME_IDENTIFIER_KIND_UNIX_DEVICE));
		var device = new Device(mount);
		stdout.printf("is shadowed: %s\n", device.isShadowed() ? "true" : "false");
		stdout.printf(" has media: %s\n", device.isMedia() ? "true" : "false");
	}
	
	public virtual void mount_changed (Mount mount) {
		//stdout.printf("mount_changed:%s\n", mount.get_uuid());
	}
	
	public virtual void mount_pre_unmount (Mount mount) {
		//stdout.printf("mount_preunmount:%s\n", mount.get_uuid());
	}
	
	public virtual void mount_removed (Mount mount) {
		stdout.printf("mount_removed\n");
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
