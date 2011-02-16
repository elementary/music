using Gee;

public class BeatBox.SmartPlaylist : Object {
	private int _rowid;
	private string sort_column; // Artist, Rating, etc.
	private string _name;
	private string _conditional; //any or all
	private Gee.ArrayList<SmartQuery> _queries;
	public int query_count;
	
	private bool _limit;
	private int _limit_amount;
	
	public SmartPlaylist() {
		_name = "";
		_conditional = "all";
		query_count = 0;
		sort_column = "";
		_queries = new Gee.ArrayList<SmartQuery>();
		_limit = false;
		_limit_amount = 50;
	}
	
	public int rowid {
		get { return _rowid; }
		set { _rowid = value; }
	}
	
	public string name {
		get { return _name; }
		set { _name = value; }
	}
	
	public string conditional {
		get { return _conditional; }
		set {
			if(value == "all" || value == "any")
				_conditional = value;
			else
				stderr.printf("Invalid conditional for smart playlist. Must be \"all\" or \"any\". Supplied: %s \n", value);
		}
	}
	
	public bool limit {
		get { return _limit; }
		set { _limit = value; }
	}
	
	public int limit_amount {
		get { return _limit_amount; }
		set { _limit_amount = value; }
	}
	
	public void clearQueries() {
		query_count = 0;
		_queries.clear();
	}
	
	public Gee.ArrayList<SmartQuery> queries() {
		return _queries;
	}
	
	public void addQuery(SmartQuery s) {
		query_count++;
		_queries.add(s);
	}
	
	/** temp_playlist should be in format of #,#,#,#,#, **/
	public void queries_from_string(string q) {
		string[] queries_in_string = q.split("<query_seperator>", 0);
		
		int index;
		for(index = 0; index < queries_in_string.length - 1; index++) {
			string[] pieces_of_query = queries_in_string[index].split("<value_seperator>", 0);
			
			SmartQuery sq = new SmartQuery();
			sq.field = pieces_of_query[0];
			sq.comparator = pieces_of_query[1];
			sq.value = pieces_of_query[2];
			
			addQuery(sq);
		}
	}
	
	public string queries_to_string() {
		string rv = "";
		
		foreach(SmartQuery q in queries()) {
			rv += q.field + "<value_seperator>" + q.comparator + "<value_seperator>" + q.value + "<query_seperator>";
		}
		
		return rv;
	}
	
	public LinkedList<int> analyze(LibraryManager lm) {
		LinkedList<int> rv = new LinkedList<int>();
		
		foreach(Song s in lm.songs()) {
			int match_count = 0; //if OR must be greather than 0. if AND must = queries.size.
			
			foreach(SmartQuery q in _queries) {
				if(song_matches_query(q, s))
					match_count++;
			}
			
			if((conditional == "all" && match_count == _queries.size) || (conditional == "any" && match_count >= 1))
				rv.add(s.rowid);
		}
		
		return rv;
	}
	
	public bool song_matches_query(SmartQuery q, Song s) {
		if(q.field == "Album") { //strings
			
		}
		else if(q.field == "Artist") {
			
		}
		else if(q.field == "Comment") {
			
		}
		else if(q.field == "Genre") {
			
		}
		else if(q.field == "Title") {
			
		}
		else if(q.field == "Bitrate") {//numbers
			
		}
		else if(q.field == "Playcount") {
			
		}
		else if(q.field == "Year") {
			
		}
		else if(q.field == "Date Added") {//time
			
		}
		else if(q.field == "Last Played") {
			
		}
		else if(q.field == "Length") {//length
			
		}
		else if(q.field == "Rating") {//rating
			
		}
		
		if(q.comparator == "=") {
			if(q.field == "album")
				return s.album == q.value;
			else if(q.field == "artist")
				return s.artist == q.value;
			else if(q.field == "bitrate")
				return s.bitrate == q.value.to_int();
			else if(q.field == "comment")
				return s.comment == q.value;
			else if(q.field == "dateadded")
				return s.date_added == q.value.to_int();
			else if(q.field == "genre")
				return s.genre == q.value;
			else if(q.field == "length")
				return s.length == q.value.to_int();
			else if(q.field == "playcount")
				return s.play_count == q.value.to_int();
			else if(q.field == "rating")
				return s.rating == q.value.to_int();
			else if(q.field == "title")
				return s.title == q.value;
			else if(q.field == "track")
				return s.track == q.value.to_int();
			else if(q.field == "year")
				return s.year == q.value.to_int();
		}
		else if(q.comparator == ">") { //only numerical
			if(q.field == "bitrate")
				return s.bitrate > q.value.to_int();
			else if(q.field == "dateadded")
				return s.date_added > q.value.to_int();
			else if(q.field == "length")
				return s.length > q.value.to_int();
			else if(q.field == "playcount")
				return s.play_count > q.value.to_int();
			else if(q.field == "rating")
				return s.rating > q.value.to_int();
			else if(q.field == "track")
				return s.track > q.value.to_int();
			else if(q.field == "year")
				return s.year > q.value.to_int();
		}
		else if(q.comparator == "<") { // only numerical
			if(q.field == "bitrate")
				return s.bitrate < q.value.to_int();
			else if(q.field == "dateadded")
				return s.date_added < q.value.to_int();
			else if(q.field == "length")
				return s.length < q.value.to_int();
			else if(q.field == "playcount")
				return s.play_count < q.value.to_int();
			else if(q.field == "rating")
				return s.rating < q.value.to_int();
			else if(q.field == "track")
				return s.track < q.value.to_int();
			else if(q.field == "year")
				return s.year < q.value.to_int();
		}
		else if(q.comparator == "LIKE") { // only strings
			if(q.field == "album")
				return (q.value.down() in s.album.down());
			if(q.field == "artist")
				return (q.value.down() in s.artist.down());
			if(q.field == "comment")
				return (q.value.down() in s.comment.down());
			if(q.field == "genre")
				return (q.value.down() in s.genre.down());
			if(q.field == "title")
				return (q.value.down() in s.title.down());
		}
		
		return false;
	}
}
