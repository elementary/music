using Gee;

public interface BeatBox.Device : GLib.Object {
	//private Mount mount;
	
	public signal void device_unmounted();
	public signal void progress_notification(string? message, double progress);
	
	/*public Device(Mount m) {
		this.mount = m;
		
		/*int audio = 0;
		int other = 0;
		FileOperator.guess_content_type(mount.get_default_location(), ref audio, ref other);
		
		audioPercentage = (double)(audio/(other + audio));*
		stdout.printf("created mount at %s and is type %s\n", get_path(), getContentType());
		
		if(getContentType() == "ipod-new" || getContentType() == "ipod-old") {
			var db = GPod.iTunesDB.parse(get_path());
			
			for(int i = 0; i < db.tracks.length(); ++i) {
				stdout.printf("%s %s %s\n", db.tracks.nth_data(i).title, db.tracks.nth_data(i).artist, db.tracks.nth_data(i).album);
			}
		}
	}*/
	
	public abstract bool initialize();
	public abstract string getContentType();
	public abstract string getDisplayName();
	public abstract string get_fancy_description();
	public abstract void set_mount(Mount mount);
	public abstract Mount get_mount();
	public abstract string get_path();
	public abstract void set_icon(GLib.Icon icon);
	public abstract GLib.Icon get_icon();
	public abstract uint64 get_capacity();
	public abstract string get_fancy_capacity();
	public abstract uint64 get_used_space();
	public abstract uint64 get_free_space();
	public abstract void unmount();
	public abstract void eject();
	public abstract void get_device_type();
	public abstract Collection<int> get_songs();
	public abstract Collection<int> get_playlists();
	public abstract Collection<int> get_smart_playlists();
	public abstract bool sync_songs(LinkedList<int> list);
	public abstract bool is_syncing();
	public abstract bool will_fit(LinkedList<int> list);
	
	/*public string get_path() {
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
		int64 rv;
		
		try {
			rv = mount.get_default_location().query_info("*", FileQueryInfoFlags.NONE).get_size();
		}
		catch(GLib.Error err) {
			rv = 0;
			stdout.printf("Could not fetch size of mount\n");
		}
		
		return rv;
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
	
	// This freezes up stuff START
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
	// This freezes up stuff END 
	
	public string getContentType() {
		if(get_path().has_prefix("cdda://")) {
			return "cdrom";
		}
		else if(File.new_for_path(get_path() + "/iTunes_Control").query_exists() ||
				File.new_for_path(get_path() + "/iPod_Control").query_exists() ||
				File.new_for_path(get_path() + "/iTunes/iTunes_Control").query_exists()) {
			return "ipod-old";		
		}
		else if(get_path().has_prefix("afc://")) {
			return "ipod-new";
		}
		else if(File.new_for_path(get_path() + "/Android").query_exists()) {
			return "android";
		}
		
		
		return "non-audio";
	}
	
	public string getDescription() {
		if(get_path().has_prefix("cdda://")) {
			return "You inserted a CD-ROM.";
		}
		else if(File.new_for_path(get_path() + "/iTunes_Control").query_exists() ||
				File.new_for_path(get_path() + "/iPod_Control").query_exists() ||
				File.new_for_path(get_path() + "/iTunes/iTunes_Control").query_exists()) {
			return "You inserted an older iPod device. This is not an iPhone or iPad";		
		}
		else if(get_path().has_prefix("afc://")) {
			return "You inserted a newer iPod device, or an iPhone or iPad.";
		}
		else if(File.new_for_path(get_path() + "/Android").query_exists()) {
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
		
	}*/
}
