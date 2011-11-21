using GPod;
using Gee;

public class BeatBox.iPodDevice : GLib.Object, BeatBox.Device {
	iTunesDB db;
	Mount mount;
	GLib.Icon icon;
	
	LinkedList<int> songs;
	
	public iPodDevice(LibraryManager lm, Mount mount) {
		this.mount = mount;
		icon = mount.get_icon();
	}
	
	public bool initialize() {
		try {
			db = iTunesDB.parse(get_path());
		}
		catch(Error err) {
			stdout.printf("Error parsing db at %s: %s\n", get_path(), err.message);
			return false;
		}
		
		var trToSo = new LinkedList<Song>();
		
		
		for(int i = 0; i < db.tracks.length(); ++i) {
			trToSo.add(new Song.from_track(db.tracks.nth_data(i)));
		}
		
		lm.add_songs(trToSo, false);
		
		foreach(var s in tSongs)
			songs.add(s.rowid);
			
		d.device_unmounted.connect( () => {
			foreach(Song s in tSongs) {
				s.unique_status_image = null;
				lm.update_songs(tSongs, false);
			}
		});
		
		return true;
	}
	
	public bool isNew() {
		return mount.get_default_location().get_parse_name().has_prefix("afc://");
	}
	
	public string getContentType() {
		if(isNew())
			return "ipod-new";
		else
			return "ipod-old";
	}
	
	public string getDisplayName() {
		return mount.get_name();
	}
	
	public void set_mount(Mount mount) {
		this.mount = mount;
	}
	
	public Mount get_mount() {
		return mount;
	}
	
	public string get_path() {
		return mount.get_default_location().get_path();
	}
	
	public void set_icon(GLib.Icon icon) {
		this.icon = icon;
	}
	
	public GLib.Icon get_icon() {
		return icon;
	}
	
	public int64 get_capacity() {
		return (int64)0;
	}
	
	public int64 get_used_space() {
		return (int64)0;
	}
	
	public int64 get_free_space() {
		return (int64)0;
	}
	
	public void unmount() {
		
	}
	
	public void eject() {
		
	}
	
	public void get_device_type() {
		
	}
}
