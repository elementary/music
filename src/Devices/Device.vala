using Gee;

public interface BeatBox.Device : GLib.Object {
	//private Mount mount;
	
	public signal void initialized(Device d);
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
	
	public abstract bool start_initialization();
	public abstract void finish_initialization();
	public abstract string getContentType();
	public abstract string getDisplayName();
	public abstract void setDisplayName(string name);
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
	public abstract Collection<int> get_podcasts();
	public abstract Collection<int> get_playlists();
	public abstract Collection<int> get_smart_playlists();
	public abstract bool sync_songs(LinkedList<int> list);
	public abstract bool is_syncing();
	public abstract void cancel_sync();
	public abstract bool will_fit(LinkedList<int> list);
	
	public string get_unique_identifier() {
		Mount m = get_mount();
		string uuid = m.get_uuid();
		File root = m.get_root();
		
		stdout.printf("unique: %s,%s\n", uuid, root.get_uri());
		return uuid;
	}
}
