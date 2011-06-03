/** Original Authors: 	Andreas Obergrusberger
 * 						Jörn Magens
 * 
 * Edited by:			Scott Ringwelski
 * 
*/
public class BeatBox.MPRIS : GLib.Object {
	LibraryManager lm;
	LibraryWindow lw;
	
	public MprisPlayer player = null;
	public MprisRoot root = null;
	
	private unowned DBusConnection conn;
	private uint owner_id;
	
	public MPRIS(LibraryManager lmm, LibraryWindow lww) {
		lm = lmm;
		lw = lww;
		
		owner_id = Bus.own_name(BusType.SESSION,
								"org.mpris.MediaPlayer2.beatbox",
								GLib.BusNameOwnerFlags.NONE,
								on_bus_acquired,
								on_name_acquired,
								on_name_lost);
								
		if(owner_id == 0) {
			stdout.printf("Could not initialize MPRIS session.\n");
		}
		else {
			var soundMenu = new SoundMenuIntegration(lmm, lww);
		}
	}
	
	private void on_bus_acquired(DBusConnection connection, string name) {
		this.conn = connection;
		//print("bus acquired\n");
		try {
			root = new MprisRoot();
			connection.register_object("/org/mpris/MediaPlayer2", root);
			player = new MprisPlayer(connection);
			connection.register_object("/org/mpris/MediaPlayer2", player);
		} 
		catch(IOError e) {
			print("%s\n", e.message);
		}
	}

	private void on_name_acquired(DBusConnection connection, string name) {
		print("name acquired\n");
	}	

	private void on_name_lost(DBusConnection connection, string name) {
		print("name_lost\n");
	}
}

[DBus(name = "org.mpris.MediaPlayer2")]
public class MprisRoot : GLib.Object {
	
	public MprisRoot() {
		
	}
	
	public bool CanQuit { 
		get {
			return true;
		} 
	}

	public bool CanRaise { 
		get {
			return true;
		} 
	}
	
	public bool HasTrackList {
		get {
			return false;
		}
	}
	public string DesktopEntry { 
		owned get {
			return "beatbox";
		} 
	}
	
	public string Identity {
		owned get {
			return "BeatBox";
		}
	}
	
	public string[] SupportedUriSchemes {
		owned get {
			string[] sa = {"http", "file", "https", "ftp"};
			return sa;
		}
	}
	
	public string[] SupportedMimeTypes {
		owned get {
			string[] sa = {
			   "application/x-ogg",
			   "application/ogg",
			   "video/3gpp",
			   "video/avi",
			   "video/dv",
			   "video/fli",
			   "video/flv",
			   "video/mp4",
			   "video/mp4v-es",
			   "video/mpeg",
			   "video/msvideo",
			   "video/ogg",
			   "video/quicktime",
			   "video/vivo",
			   "video/vnd.divx",
			   "video/vnd.vivo",
			   "video/x-anim",
			   "video/x-avi",
			   "video/x-flc",
			   "video/x-fli",
			   "video/x-flic",
			   "video/x-flv",
			   "video/x-m4v",
			   "video/x-matroska",
			   "video/x-mpeg",
			   "video/x-mpg",
			   "video/x-ms-asf",
			   "video/x-msvideo",
			   "video/x-ms-wm",
			   "video/x-ms-wmv",
			   "video/x-ms-wmx",
			   "video/x-ms-wvx",
			   "video/x-nsv",
			   "video/x-ogm+ogg",
			   "video/x-theora",
			   "video/x-theora+ogg",
			   "audio/x-vorbis+ogg",
			   "audio/x-scpls",
			   "audio/x-mp3",
			   "audio/x-mpeg",
			   "audio/mpeg",
			   "audio/x-mpegurl",
			   "audio/x-flac",
			   "x-content/audio-cdda",
			   "x-content/audio-player"
			};
			return sa;
		}
	}

	public void Quit() {
		stdout.printf("Can't quit yet!\n");
	}
	
	public void Raise() {
		stdout.printf("Can't show myself yet!\n");
	}
}


[DBus(name = "org.mpris.MediaPlayer2.Player")]
public class MprisPlayer : GLib.Object {
	private unowned DBusConnection conn;
	
	private const string INTERFACE_NAME = "org.mpris.MediaPlayer2.Player";
	
	private uint send_property_source = 0;
	private uint update_metadata_source = 0;
	private HashTable<string,Variant> changed_properties = null;
	
	private static enum Direction {
		NEXT = 0,
		PREVIOUS,
		STOP
	}
	
	public MprisPlayer(DBusConnection conn) {
		this.conn = conn;
		
	}
	
	private bool send_property_change() {
		
		if(changed_properties == null)
			return false;
		
		var builder             = new VariantBuilder(VariantType.ARRAY);
		var invalidated_builder = new VariantBuilder(new VariantType("as"));
		
		foreach(string name in changed_properties.get_keys()) {
			Variant variant = changed_properties.lookup(name);
			builder.add("{sv}", name, variant);
		}
		
		changed_properties = null;
		
		try {
			conn.emit_signal(null,
			                 "/org/mpris/MediaPlayer2", 
			                 "org.freedesktop.DBus.Properties", 
			                 "PropertiesChanged", 
			                 new Variant("(sa{sv}as)", 
			                             this.INTERFACE_NAME, 
			                             builder, 
			                             invalidated_builder)
			                 );
		}
		catch(Error e) {
			print("%s\n", e.message);
		}
		send_property_source = 0;
		return false;
	}
	
	private void queue_property_for_notification(string property, Variant val) {
		// putting the properties into a hashtable works as akind of event compression
		
		if(changed_properties == null)
			changed_properties = new HashTable<string,Variant>(str_hash, str_equal);
		
		changed_properties.insert(property, val);
		
		if(send_property_source == 0) {
			send_property_source = Idle.add(send_property_change);
		}
	}
	
	public string PlaybackStatus {
		owned get { //TODO signal org.freedesktop.DBus.Properties.PropertiesChanged
			if(BeatBox.Beatbox._program.lm.playing)
				return "Playing";
			else if(!BeatBox.Beatbox._program.lm.playing && BeatBox.Beatbox._program.lm.song_info.song == null)
				return "Stopped";
			else if(!BeatBox.Beatbox._program.lm.playing)
				return "Paused";
			else
				return "Stopped";
		}
	}
	
	public string LoopStatus {
		owned get {
			switch(BeatBox.Beatbox._program.lm.repeat) {
				case(BeatBox.LibraryManager.Repeat.OFF):
					return "None";
					break;
				case(BeatBox.LibraryManager.Repeat.SONG):
					return "Track";
					break;
				case(BeatBox.LibraryManager.Repeat.ALBUM):
				case(BeatBox.LibraryManager.Repeat.ARTIST):
				case(BeatBox.LibraryManager.Repeat.ALL):
					return "Playlist";
					break;
			}
			
			return "Playlist";
		}
		set {
			switch(value) {
				case("None"):
					BeatBox.Beatbox._program.lm.repeat = BeatBox.LibraryManager.Repeat.OFF;
					break;
				case("Track"):
					BeatBox.Beatbox._program.lm.repeat = BeatBox.LibraryManager.Repeat.SONG;
					break;
				case("Playlist"):
					BeatBox.Beatbox._program.lm.repeat = BeatBox.LibraryManager.Repeat.ALL;
					break;
				default:
					BeatBox.Beatbox._program.lm.repeat = BeatBox.LibraryManager.Repeat.ALL;
					break;
			}
			
			Variant variant = value;
			queue_property_for_notification("LoopStatus", variant);
		}
	}
	
	/*public double Rate {
		get {
			return (double)1.0;
		}
		set {
		}
	}*/
	
	public bool Shuffle {
		get {
			if(BeatBox.Beatbox._program.lm.shuffle == BeatBox.LibraryManager.Shuffle.ALL)
				return true;
			return false;
		}
		set {
			if(value) {
				BeatBox.Beatbox._program.lm.shuffle = BeatBox.LibraryManager.Shuffle.ALL;
			}
			else {
				BeatBox.Beatbox._program.lm.shuffle = BeatBox.LibraryManager.Shuffle.OFF;
			}
			
			Variant variant = value;
			queue_property_for_notification("Shuffle", variant);
		}
	}
	
	private HashTable<string,Variant> _metadata = new HashTable<string,Variant>(str_hash, str_equal);
	public HashTable<string,Variant>? Metadata { //a{sv}
		owned get {
			Variant variant = "1";
			_metadata.insert("mpris:trackid", variant);
			return _metadata;
		}
	}
	
	/*public double Volume {
		owned get{
			return (double)1.0;
		}
		set {
			
		}
	}*/
	
	public int64 Position {
		get {
			return (int64)1;
		}
	}
	
	/*public double MinimumRate {
		get {
			return (double)1.0;
		}
	}

	public double MaximumRate {
		get {
			return (double)1.0;
		}
	}*/

	public bool CanGoNext {
		get {
			return true;
		}
	}
	
	public bool CanGoPrevious {
		get {
			return true;
		}
	}
	
	public bool CanPlay {
		get {
			return true;
		}
	}
	
	public bool CanPause {
		get {
			return true;
		}
	}
	
	public bool CanSeek {
		get {
			return true;
		}
	}
	
	public bool CanControl {
		get {
			return true;
		}
	}
	
	public signal void Seeked(int64 Position);
	
	public void Next() {
		BeatBox.Beatbox._program.nextClicked();
	}
	
	public void Previous() {
		BeatBox.Beatbox._program.previousClicked();
	}
	
	public void Pause() {
		if(BeatBox.Beatbox._program.lm.playing)
			BeatBox.Beatbox._program.playClicked();
	}
	
	public void PlayPause() {
		BeatBox.Beatbox._program.playClicked();
	}
	
	public void Stop() {
		BeatBox.Beatbox._program.lm.stopPlayback();
	}
	
	public void Play() {
		if(!BeatBox.Beatbox._program.lm.playing)
			BeatBox.Beatbox._program.playClicked();
	}
	
	public void Seek(int64 Offset) {
		return;
	}
	
	public void SetPosition(string dobj, int64 Position) {
		//print(" set position %lf\n", ((double)Position/(xn.gPl.length_time / 1000.0)));
		//xn.gPl.gst_position = ((double)Position/(xn.gPl.length_time / 1000.0));
		stdout.printf("Must set position!\n");
	}
	
	public void OpenUri(string Uri) {
		//TODO
		return;
	}
}
