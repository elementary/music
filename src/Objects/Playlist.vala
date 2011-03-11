public class BeatBox.Playlist : Object {
	private string _name;
	public string sort_column; // Artist, Rating, etc.
	public Gtk.SortType sort_direction; //ASCENDING/DESCENDING
	private int _rowid;
	private Gee.LinkedList<Song> _songs; // hold title, artist, album
	
	public Playlist() {
		_name = "New Playlist";
		sort_column = "";
		_songs = new Gee.LinkedList<Song>();
	}
	
	public Playlist.with_info(int rowid, string name) {
		_songs = new Gee.LinkedList<Song>();
		_rowid = rowid;
		_name = name;
	}
	
	public int rowid {
		get { return _rowid; }
		set { _rowid = value; }
	}
	
	public string name {
		get {return _name; }
		set {_name = value; }
	}
	
	public Gee.LinkedList<Song> songs() {
		return _songs;
	}
	
	public void addSong(Song s) {
		_songs.add(s);
	}
	
	public void removeSong(Song s) {
		foreach(Song t in _songs) {
			if(t.title == s.title && t.artist == s.artist && t.album == s.album) {
				_songs.remove(t);
				break;
			}
		}
	}
	
	public void clear() {
		_songs.clear();
	}
	
	public void songs_from_string(string songs) {
		string[] song_strings = songs.split("<song_seperator>", 0);
		
		int index;
		for(index = 0; index < song_strings.length - 1; ++index) {
			string[] pieces_of_song = song_strings[index].split("<value_seperator>", 0);
			
			Song s = new Song("");
			s.title = pieces_of_song[0];
			s.artist = pieces_of_song[1];
			s.album = pieces_of_song[2];
			
			addSong(s);
		}
	}
	
	public string songs_to_string() {
		string rv = "";
		
		foreach(Song s in _songs) {
			rv += s.title + "<value_seperator>" + s.artist + "<value_seperator>" + s.album + "<song_seperator>";
		}
		
		return rv;
	}
	
	public Gee.LinkedList<int> analyze(LibraryManager lm) {
		Gee.LinkedList<int> rv = new Gee.LinkedList<int>();
		
		// TODO: prevent adding duplicates multiple times
		foreach(Song s in lm.songs()) {
			foreach(Song l in this._songs) {
				if(s.title == l.title && s.artist == l.artist && s.album == l.album) {
					rv.add(s.rowid);
				}
			}
		}
		
		return rv;
	}
}
