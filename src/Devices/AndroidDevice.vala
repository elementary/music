using GPod;

public class BeatBox.AndroidDevice : GLib.Object, BeatBox.Device {
	Mount mount;
	GLib.Icon icon;
	
	public AndroidDevice(Mount mount) {
		this.mount = mount;
	}
	
	public bool initialize() {
		return false;
	}
	
	public string getContentType() {
		return "android";
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
