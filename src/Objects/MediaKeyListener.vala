using DBus;

public class BeatBox.MediaKeyListener : GLib.Object {
	private LibraryManager lm;
	private LibraryWindow lw;
	dynamic DBus.Object media_object;
	
	public MediaKeyListener(LibraryManager lmm, LibraryWindow lww) {
		lm = lmm;
		lw = lww;
		
		try {
			DBus.Connection connection = DBus.Bus.get(DBus.BusType.SESSION);
			
			if(connection != null) {
				media_object = connection.get_object("org.gnome.SettingsDaemon", "/org/gnome/SettingsDaemon/MediaKeys", "org.gnome.SettingsDaemon.MediaKeys");
				
				if(media_object != null) {
					media_object.MediaPlayerKeyPressed.connect(mediaKeyPressed);
					media_object.GrabMediaPlayerKeys("beatbox", (uint32)0);
				}
			}
				
		}
		catch(GLib.Error err) {
			stdout.printf("Could not initialize media key listener: %s\n", err.message);
		}
	}
	
	public void releaseMediaKeys() {
		media_object.ReleaseMediaPlayerKeys("beatbox");
	}
	
	private void mediaKeyPressed(dynamic DBus.Object bus, string application, string key) {
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
