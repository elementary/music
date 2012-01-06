using GPod;
using Gee;

public class BeatBox.CDRomDevice : GLib.Object, BeatBox.Device {
	Mount mount;
	GLib.Icon icon;
	
	public CDRomDevice(Mount mount) {
		this.mount = mount;
		this.icon = mount.get_icon();
	}
	
	public DevicePreferences get_preferences() {
		return new DevicePreferences(get_unique_identifier());
	}
	
	public bool start_initialization() {
		return false;
	}
	
	public void finish_initialization() {
		
		//initialized(this);
	}
	
	public string getContentType() {
		return "cdrom";
	}
	
	public string getDisplayName() {
		return mount.get_name();
	}
	
	public void setDisplayName(string name) {
		
	}
	
	public string get_fancy_description() {
		return "No Description";
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
	
	public uint64 get_capacity() {
		return (uint64)0;
	}
	
	public string get_fancy_capacity() {
		return "Unknown capacity";
	}
	
	public uint64 get_used_space() {
		return (uint64)0;
	}
	
	public uint64 get_free_space() {
		return (uint64)0;
	}
	
	public void unmount() {
		
	}
	
	public void eject() {
		
	}
	
	public void get_device_type() {
		
	}
	
	public bool supports_podcasts() {
		return false;
	}
	
	public bool supports_audiobooks() {
		return false;
	}
	
	public Collection<int> get_medias() {
		return new LinkedList<int>();
	}
	
	public Collection<int> get_podcasts() {
		return new LinkedList<int>();
	}
	
	public Collection<int> get_audiobooks() {
		return new LinkedList<int>();
	}
	
	public Collection<int> get_playlists() {
		return new LinkedList<int>();
	}
	
	public Collection<int> get_smart_playlists() {
		return new LinkedList<int>();
	}
	
	public bool sync_medias(LinkedList<int> list) {
		return false;
	}
	
	public bool sync_playlists(LinkedList<int> list) {
		return false;
	}
	
	public bool will_fit(LinkedList<int> list) {
		return false;
	}
	
	public bool transfer_to_library(LinkedList<int> list) {
		return false;
	}
	
	public bool is_syncing() {
		return false;
	}
	
	public bool is_transferring() {
		return false;
	}
	
	public void cancel_sync() {
		
	}
	
	public void cancel_transfer() {
		
	}
}
