using GLib;

[DBus (name = "org.gnome.SettingsDaemon.MediaKeys")]
public interface GnomeMediaKeys : GLib.Object {
    public abstract void GrabMediaPlayerKeys (string application, uint32 time) throws GLib.IOError;
    public abstract void ReleaseMediaPlayerKeys (string application) throws GLib.IOError;
    public signal void MediaPlayerKeyPressed (string application, string key);
}

public class BeatBox.MediaKeyListener : GLib.Object {
	private LibraryManager lm;
	private LibraryWindow lw;
	private GnomeMediaKeys media_object;
	
	public MediaKeyListener(LibraryManager lmm, LibraryWindow lww) {
		lm = lmm;
		lw = lww;
		
        try {
            media_object = Bus.get_proxy_sync (BusType.SESSION, "org.gnome.SettingsDaemon", "/org/gnome/SettingsDaemon/MediaKeys");
        } catch (IOError e) {
            stderr.printf ("Mediakeys error: %s\n", e.message);
        }
		
        if(media_object != null) {
            media_object.MediaPlayerKeyPressed.connect(mediaKeyPressed);
            media_object.GrabMediaPlayerKeys("beatbox", (uint32)0);
        }
	}
	
	public void releaseMediaKeys() {
		media_object.ReleaseMediaPlayerKeys("beatbox");
	}
	
	private void mediaKeyPressed(dynamic Object bus, string application, string key) {
		if(application != "beatbox")
			return;
		
		if(key == "Previous") {
			lw.previousClicked();
		}
		else if(key == "Play") {
			lw.playClicked();
		}
		else if(key == "Next") {
			lw.nextClicked();
		}
		else {
			stdout.printf("Unused key pressed: %s\n", key);
		}
	}
}
