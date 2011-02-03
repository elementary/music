//using Gst;
using Gtk;

public class BeatBox.Song : GLib.Object{
	//core info
	private string _file;
	private string _file_name;
	private string _file_directory;
	private int _file_size;
	private int _rowid;
	
	//tags
	private string _title;
	private string _artist;
	private string _album;
	private string _genre;
	private string _comment;
	private int _year;
	private int _track;
	
	//audioproperties
	private int _bitrate;
	private int _length;
	private int _samplerate;
	private int _bpm;
	
	//extra stuff for beatbox
	private int _rating;
	private int _score;//calculated based on skips, plays, etc.
	private int _play_count;
	private int _skip_count;
	private int _date_added;
	private int _last_played;
	
	
	//core stuff
	public Song(string file) {
		this.file = file;
		file_name = "";
		file_directory = "";
		file_size = 0;
		rowid = 0;
		title = "Unkown Title";
		artist = "Unkown Artist";
		album = "Unknown Album";
		genre = "";
		comment = "";
		year = 0;
		bitrate = 0;
		length = 0;
		samplerate = 0;
		bpm = 0;
		rating = 0;
		score = 0;
		play_count = 0;
		skip_count = 0;
		date_added = 0;
		last_played = 0;
	}
	
	public string file {
		get { return _file; }
		set { _file = value; }
	}
	
	public string file_directory {
		get { return _file_directory; }
		set { _file_directory = value; }
	}
	
	public string file_name {
		get { return _file_name; }
		set { _file_name = value; }
	}
	
	public int file_size {
		get { return _file_size; }
		set { _file_size = value; }
	}
	
	public int rowid {
		get { return _rowid; }
		set { _rowid = value; }
	}
	
	
	//tags
    public string title {
        get { return _title; }
        set { 
			if(value != "")
				_title = value;
			else
				_title = "Unkown";
		}
    }
    
    public string artist {
        get { return _artist; }
        set { 
			if(value != "")
				_artist = value;
			else
				_artist = "Unkown";
		}
    }
    
    public string album {
		get { return _album; }
		set { 
			if(value != "")
				_album = value;
			else
				_album = "Unkown";
		}
	}
	
	public string genre {
		get { return _genre; }
		set { _genre = value; } // add smart genre fixer ("rock" -> "Rock")
	}
	
	public string comment {
		get { return _comment; }
		set { _comment = value; }
	}
	
	public int year {
		get { return _year; }
		set { _year = value; }
	}
	
	public int track {
		get { return _track; }
		set { _track = value; }
	}
	
	
	//audioproperties
	public int bitrate {
		get { return _bitrate; }
		set { _bitrate = value; }
	}
	
	public int length {
		get { return _length; }
		set { _length = value; }
	}
	
	public string pretty_length() {
		int minute = 0;
		int seconds = _length;
		
		while(seconds >= 60) {
			++minute;
			seconds -= 60;
		}
		
		return minute.to_string() + ":" + ((seconds < 10 ) ? "0" + seconds.to_string() : seconds.to_string());
	}
	
	public int samplerate {
		get { return _samplerate; }
		set { _samplerate = value; }
	}
	
	public int bpm {
		get { return _bpm; }
		set { _bpm = value; }
	}
	
	public int rating {
		get { return _rating; }
		set { 
			if(value >= 0 && value <= 5)
				_rating = value;
		}
	}
	
	public int score {
		get { return _score; }
		set { _score = value; }
	}
	
	public int calculate_score() {
		
		return 1;
	}
	
	public int play_count {
		get { return _play_count; }
		set { _play_count = value; }
	}
	
	public int skip_count {
		get { return _skip_count; }
		set { _skip_count = value; }
	}
	
	public int last_played {
		get { return _last_played; }
		set { _last_played = value; }
	}
	
	public string pretty_last_played() {
		var t = Time.local(last_played);
		string rv = t.format("%m/%e/%Y %l:%M %p");
		return rv;
	}
	
	public int date_added {
		get { return _date_added; }
		set { _date_added = value; }
	}
	
	public string pretty_date_added() {
		var t = Time.local(date_added);
		string rv = t.format("%m/%e/%Y %l:%M %p");
		return rv;
	}
}
