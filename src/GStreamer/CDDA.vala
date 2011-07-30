using Gst;
using Gee;

public class BeatBox.CDDA : GLib.Object {
	//Gst.Element playbin;
	
	public CDDA() {
		//this.playbin = playbin;
		//GLib.Signal.connect(playbin, "notify::source", (GLib.Callback)notifySourceCallback, this);
	}
	
	public static LinkedList<Song> getSongList(string device_uri) {
		var rv = new LinkedList<Song>();
		File device_file;
		FileInfo device_info;
		string album_name;
		string album_artist;
		string album_genre;
		
		device_file = File.new_for_uri(device_uri);
		if(!device_file.query_exists()) {
			stdout.printf("could not locate device file\n");
			return rv;
		}
		
		device_info = device_file.query_info("xattr::*", FileQueryInfoFlags.NONE);
		if(device_info == null) {
			stdout.printf("could not get device attr\n");
			return rv;
		}
		
		stdout.printf("Obtaining album data\n");
		album_name = device_info.get_attribute_string("xattr::org.gnome.audio.title");
		stdout.printf("album name: %s\n", album_name);
		album_artist = device_info.get_attribute_string("xattr::org.gnome.audio.artist");
		album_genre = device_info.get_attribute_string("xattr::org.gnome.audio.genre");
		
		var enumerator = device_file.enumerate_children("xattr::*", FileQueryInfoFlags.NONE);
		if(enumerator == null) {
			stdout.printf("Could not enumerate tracks\n");
			return rv;
		}
		
		int index = 1;
		for (device_info = enumerator.next_file(); device_info != null; device_info = enumerator.next_file()) {
			Song s = new Song("cdda://" + index.to_string());
			s.isTemporary = true;
			
			var title = device_info.get_attribute_string("xattr::org.gnome.audio.title");
			var artist = device_info.get_attribute_string("xattr::org.gnome.audio.artist");
			var length = (int)device_info.get_attribute_uint64("xattr::org.gnome.audio.duration");
			
			s.track = index;
			s.length = length; // no need to check, it's our best guess either way
			
			if(title != null)
				s.title = title;
			if(artist != null)
				s.artist = artist;
			if(album_artist != null)
				s.album_artist = album_artist;
			if(album_genre != null)
				s.genre = album_genre;
			
			// do some checks
			bool artistValid = (s.artist != null && s.artist != "");
			bool albumArtistValid = (album_artist != null && album_artist != "");
			
			if(artistValid && !albumArtistValid)
				s.album_artist = s.artist;
			else if(!artistValid && albumArtistValid)
				s.artist = s.album_artist;
			
			stdout.printf("Added %s %s %s %s\n", s.title, s.artist, s.album_artist, s.genre);
			rv.add(s);
			
			++index;
		}
		
		return rv;
	}
	
	public void getLastFMSongList(ref LinkedList<Song> songs, string artist, string album) {
		
	}
	
}
