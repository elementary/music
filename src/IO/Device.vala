public class BeatBox.Device : GLib.Object {
	private Mount mount;
	private double audioPercentage;
	
	public signal void device_unmounted();
	
	public Device(Mount m) {
		this.mount = m;
		
		/*int audio = 0;
		int other = 0;
		FileOperator.guess_content_type(mount.get_default_location(), ref audio, ref other);
		
		audioPercentage = (double)(audio/(other + audio));*/
	}
	
	public string getMountLocation() {
		return mount.get_default_location().get_parse_name();
	}
	
	public string getDisplayName() {
		return mount.get_name();
	}
	
	public string getUnixDevicePath() {
		if(mount.get_volume() != null)
			return mount.get_volume().get_identifier(VOLUME_IDENTIFIER_KIND_UNIX_DEVICE);
		else if(mount.get_drive() != null)
			return mount.get_drive().get_identifier(VOLUME_IDENTIFIER_KIND_UNIX_DEVICE);
		else
			return "";
	}
	
	public int64 getSize() {
		return mount.get_default_location().query_info("*", FileQueryInfoFlags.NONE).get_size();
	}
	
	public int64 getFreeSpace() {
		return (int64)0;//mount.get_default_location().query_info(FILESYSTEM_FREE, FileQueryInfoFlags.NONE).get_attribute_uint64(FILESYSTEM_FREE);
	}
	
	public int64 getUsedSpace() {
		return getSize() - getFreeSpace();
	}
	
	public GLib.Icon getIcon() {
		return mount.get_icon();
	}
	
	public bool canEject() {
		if(mount.get_drive() != null && mount.get_drive().can_eject())
			return mount.get_drive().can_eject();
		
		if(mount.get_volume() != null && mount.get_volume().can_eject())
			return mount.get_volume().can_eject();
		
		return mount.can_eject();
	}
	
	public void eject() {
		if(mount.get_drive() != null)
			mount.get_drive().eject(GLib.MountUnmountFlags.NONE, null, (AsyncReadyCallback)dummy);
		
		if(mount.get_volume() != null)
			mount.get_volume().eject(GLib.MountUnmountFlags.NONE, null, (AsyncReadyCallback)dummy);
		
		mount.eject(GLib.MountUnmountFlags.NONE, null, (AsyncReadyCallback)dummy);
		
		device_unmounted();
	}
	
	public void unmount() {
		if(canEject()) {
			eject();
		}
		else
			mount.unmount(GLib.MountUnmountFlags.NONE, null, (AsyncReadyCallback)dummy);
			
		device_unmounted();
	}
	
	public string getContentType() {
		if(getMountLocation().has_prefix("cdda://")) {
			return "cdrom";
		}
		else if(File.new_for_path(getMountLocation() + "/iTunes_Control").query_exists() ||
				File.new_for_path(getMountLocation() + "/iPod_Control").query_exists() ||
				File.new_for_path(getMountLocation() + "/iTunes/iTunes_Control").query_exists()) {
			return "ipod-old";		
		}
		else if(getMountLocation().has_prefix("afc://")) {
			return "ipod-new";
		}
		else if(File.new_for_path(getMountLocation() + "/Android").query_exists()) {
			return "android";
		}
		
		
		return "non-audio";
	}
	
	public string getDescription() {
		if(getMountLocation().has_prefix("cdda://")) {
			return "You inserted a CD-ROM.";
		}
		else if(File.new_for_path(getMountLocation() + "/iTunes_Control").query_exists() ||
				File.new_for_path(getMountLocation() + "/iPod_Control").query_exists() ||
				File.new_for_path(getMountLocation() + "/iTunes/iTunes_Control").query_exists()) {
			return "You inserted an older iPod device. This is not an iPhone or iPad";		
		}
		else if(getMountLocation().has_prefix("afc://")) {
			return "You inserted a newer iPod device, or an iPhone or iPad.";
		}
		else if(File.new_for_path(getMountLocation() + "/Android").query_exists()) {
			return "You inserted an Android device. You are pretty cool.";
		}
		
		return "You inserted a device that is not a CD nor iPod";
	}
	
	public bool isShadowed() {
		return mount.is_shadowed();
	}
	
	public bool isMedia() {
		if(mount.get_drive() != null) {
			stdout.printf("drive != null\n");
			return mount.get_drive().is_media_removable();
		}
			
		return false;
	}
	
	public void dummy(GLib.Object? source_object, GLib.AsyncResult res) {
		
	}
}
