public class BeatBox.Device : GLib.Object {
	private Mount mount;
	
	private string[] mediaTypes;
	
	public Device(Mount m) {
		this.mount = m;
		
		stdout.printf("content type is %s\n", getContentType());
	}
	
	public string getMountLocation() {
		return mount.get_default_location().get_parse_name();
	}
	
	public string getDisplayName() {
		return mount.get_name();
	}
	
	public string getUnixDevicePath() {
		return mount.get_volume().get_identifier(VOLUME_IDENTIFIER_KIND_UNIX_DEVICE);
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
	
	//public GLib.Icon getIcon() {
	//	return mount.get_icon();
	//}
	
	public bool canEject() {
		return mount.can_eject();
	}
	
	private void eject() {
		if(canEject())
			mount.eject(GLib.MountUnmountFlags.NONE, null, (AsyncReadyCallback)dummy);
	}
	
	public void unmount() {
		if(canEject())
			eject();
		else
			mount.unmount(GLib.MountUnmountFlags.NONE, null, (AsyncReadyCallback)dummy);
	}
	
	public string getContentType() {
		string[] type = ContentType.guess_for_tree(mount.get_default_location());
		
		foreach(string s in type)
			stdout.printf("type: %s\n", s);
			
		return "";
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
	
	/*public string get_description() {
        string 	description = _("You have just inserted a medium");
		if (this.content_types.length() == 0){
			return description;
		}
		
		if (this.is_bluetooth()){
			description = _("You have just inserted a bluetooth device");
		}
		
		/*get only the first content_types of the device*
		string x_content_type = this.content_types.nth_data(0);
		
		/*TAKEN FROM NATUTILUS(nautilus-autorun.c) Customize greeting for well-known x-content types *
		if (x_content_type == "x-content/audio-cdda") {
			description = _("You have just inserted an Audio CD");
		} else if (x_content_type == "x-content/audio-dvd") {
			description = _("You have just inserted an Audio DVD");
		} else if (x_content_type == "x-content/video-dvd") {
			description = _("You have just inserted a Video DVD");
		} else if (x_content_type == "x-content/video-vcd") {
			description = _("You have just inserted a Video CD");
		} else if (x_content_type == "x-content/video-svcd") {
			description = _("You have just inserted a Super Video CD");
		} else if (x_content_type == "x-content/blank-cd") {
			description = _("You have just inserted a blank CD");
		} else if (x_content_type == "x-content/blank-dvd") {
			description = _("You have just inserted a blank DVD");
		} else if (x_content_type == "x-content/blank-cd") {
			description = _("You have just inserted a blank Blu-Ray disc");
		} else if (x_content_type == "x-content/blank-cd") {
			description = _("You have just inserted a blank HD DVD");
		} else if (x_content_type == "x-content/image-photocd") {
			description = _("You have just inserted a Photo CD");
		} else if (x_content_type == "x-content/image-dcf") {
			description = _("You have just inserted a medium with photos");
		} else if (x_content_type == "x-content/image-picturecd") {
			description = _("You have just inserted a Picture CD");
		} else if (x_content_type == "x-content/audio-player") {
			description = _("You have just inserted an audio player");
		}else if (x_content_type == "x-content/software") {
			description = _("You have just inserted a medium with software intended to be automatically started");
		}
		return description;
    }*/
	
	public void dummy(GLib.Object? source_object, GLib.AsyncResult res) {
		
	}
}
