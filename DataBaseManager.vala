using SQLHeavy;
using TagLib;
using Gee;

public class BeatBox.DataBaseManager : GLib.Object {
	SQLHeavy.Database _db;
	
	Transaction transaction;// the current sql transaction
	Query query; //current query to do while doing mass transactions
	bool write;
	bool create;
	
	int index;
	int item_count;
	public signal void db_progress(string? message, double progress);
	
	/** Creates a new DatabaseManager
	 * @param write True if has write access
	 * @param create True to have create access
	 */
	public DataBaseManager(bool write, bool create) {
		this.write = write;
		this.create = create;
	}
	
	/** Used on the first run. Creates all the tables and initializes them
	 */
	public void create_db() {
		try {
			_db.execute("CREATE TABLE song_list_columns (`title` TEXT,`visible` INT,`width` INT)");
			initialize_columns();
			_db.execute("CREATE TABLE playlists (`name` TEXT, `songs` TEXT)");
			_db.execute("CREATE TABLE smart_playlists (`name` TEXT, `and_or` TEXT, `queries` TEXT)");
			_db.execute("CREATE TABLE songs (`file` TEXT,`title` TEXT,`artist` TEXT,`album` TEXT,`genre` TEXT,`comment` TEXT, `year` INT, `track` INT, `bitrate` INT, `length` INT, `samplerate` INT, `rating` INT, `playcount` INT, `dateadded` INT, `lastplayed` INT)");
			_db.execute("CREATE TABLE artists ('name' TEXT, 'mbid' TEXT, 'url' TEXT, 'streamable' INT, 'listeners' INT, 'playcount' INT, 'published' TEXT, 'summary' TEXT, 'content' TEXT, 'tags' TEXT, 'similar' TEXT, 'url_image' TEXT)");
			_db.execute("CREATE TABLE albums ('name' TEXT, 'artist' TEXT, 'mbid' TEXT, 'url' TEXT, 'release_date' TEXT, 'listeners' INT, 'playcount' INT, 'tags' TEXT,  'url_image' TEXT)");
			_db.execute("CREATE TABLE tracks ('id' INT, 'name' TEXT, 'artist' TEXT, 'url' TEXT, 'duration' INT, 'streamable' INT, 'listeners' INT, 'playcount' INT, 'summary' TEXT, 'content' TEXT, 'tags' TEXT)");
			
		}
		catch (SQLHeavy.Error err) {
			stdout.printf("Bad news: could not create tables. Please report this. Message: %s\n", err.message);
		}
	}
	
	/** Loads the db into memory, creates it if need be, adds music if need be
	 * 
	 */
	public void load_db() {
		/** CHECK THAT .BEATBOX EXISTS! **/
		stdout.printf("i should check that .beatbox exists\n");
		var db_file = GLib.File.new_for_path(Environment.get_home_dir () + "/.beatbox/data.db");
		
		bool need_create = false;
		if(!db_file.query_exists())
			need_create = true;
		
		try {
			if(write && !create)
				_db = new SQLHeavy.Database (Environment.get_home_dir () + "/.beatbox/data.db", SQLHeavy.FileMode.READ | SQLHeavy.FileMode.WRITE);
			else if(!write && create)
				_db = new SQLHeavy.Database (Environment.get_home_dir () + "/.beatbox/data.db", SQLHeavy.FileMode.READ | SQLHeavy.FileMode.CREATE);
			else if(write && create)
				_db = new SQLHeavy.Database (Environment.get_home_dir () + "/.beatbox/data.db", SQLHeavy.FileMode.READ | SQLHeavy.FileMode.WRITE | SQLHeavy.FileMode.CREATE);
			else
				_db = new SQLHeavy.Database (Environment.get_home_dir () + "/.beatbox/data.db", SQLHeavy.FileMode.READ);
			
			/*_db.sql_executed.connect ((sql) => { GLib.debug ("SQL: %s \n", sql); });*/
		}
		catch (SQLHeavy.Error err) {
			stdout.printf("This is terrible. Could not even make db file. Please report this. Message: %s", err.message);
		}
		
		if(need_create)
			create_db();
	}
	
	public void resetProgress(int items) {
		index = 0;
		item_count = items;
	}
	
	/** simply returns the db location on file
	 */
	public string db_location() {
		return _db.filename;
	}
	
	public void begin_transaction(string script) {
		try {
			transaction = _db.begin_transaction();
			query = transaction.prepare (script);
		}
		catch(SQLHeavy.Error err) {
			stdout.printf("could not begin transaction: %s \n", err.message);
		}
	}
	
	public void commit_transaction() {
		try {
			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			stdout.printf("could not commit transaction: %s \n", err.message);
		}
	}
	
	/** This is rather unsafe and should only be done if you know what you're doing **/
	public void drop_table(string table) {
		try {
			_db.execute("DELETE FROM `" + table + "`");
		}
		catch(SQLHeavy.Error err) {
			stdout.printf("Could not delete table %s: %s\n", table, err.message);
		}
	}
	
	/** SONG LIST COLUMNS **
	 * song_list_columns() loads song list columns from db
	 * 
	 * initialize_columns() sets columns to initial widths
	 * 
	 * save_song_list_columns() saves the columns to db
	 */
	public ArrayList<Gtk.TreeViewColumn> load_song_list_columns() {
		var rv = new ArrayList<Gtk.TreeViewColumn>();
		
		try {
			Query query = new Query(_db, "SELECT * FROM `song_list_columns`");
			
			index = 0;
			for (var results = query.execute () ; !results.finished ; results.next ()) {
				Gtk.TreeViewColumn tvc;
				if(results.fetch_string(0) != " ")
					tvc = new Gtk.TreeViewColumn.with_attributes(results.fetch_string(0), new Gtk.CellRendererText(), "text", index, null);
				else
					tvc = new Gtk.TreeViewColumn.with_attributes(results.fetch_string(0), new Gtk.CellRendererPixbuf(), "pixbuf", index, null);
				
				tvc.resizable = true;
				tvc.reorderable = true;
				tvc.clickable = true;
				tvc.sort_column_id = index;
				tvc.set_sort_indicator(false);
				tvc.visible = (results.fetch_int(1) == 1);
				tvc.sizing = Gtk.TreeViewColumnSizing.FIXED;
				tvc.fixed_width = results.fetch_int(2);
					
				rv.add(tvc);
				++index;
			}
		}
		catch (SQLHeavy.Error err) {
			stdout.printf("Could not load song list columns: %s\n", err.message);
		}
		
		return rv;
	}
	
	public void initialize_columns() {
		try {
			transaction = _db.begin_transaction();
			query = transaction.prepare ("INSERT INTO `song_list_columns` (`title`, `visible`, `width`) VALUES (:title, :visible, :width);");
			
			/* add all columns to db */
			//id
			query.set_string(":title", "id");
			query.set_int(":visible", 0);
			query.set_int(":width", 10);
			query.execute();
			
			//currently playing
			query.set_string(":title", " ");
			query.set_int(":visible", 1);
			query.set_int(":width", 30);
			query.execute();
			
			//#
			query.set_string(":title", "#");
			query.set_int(":visible", 0);
			query.set_int(":width", 60);
			query.execute();
			
			//track
			query.set_string(":title", "Track");
			query.set_int(":visible", 1);
			query.set_int(":width", 60);
			query.execute();
			
			//title
			query.set_string(":title", "Title");
			query.set_int(":visible", 1);
			query.set_int(":width", 220);
			query.execute();
			
			//length
			query.set_string(":title", "Length");
			query.set_int(":visible", 1);
			query.set_int(":width", 75);
			query.execute();
			
			//artist
			query.set_string(":title", "Artist");
			query.set_int(":visible", 1);
			query.set_int(":width", 110);
			query.execute();
			
			//album
			query.set_string(":title", "Album");
			query.set_int(":visible", 1);
			query.set_int(":width", 200);
			query.execute();
			
			//genre
			query.set_string(":title", "Genre");
			query.set_int(":visible", 1);
			query.set_int(":width", 70);
			query.execute();
			
			//comment
			query.set_string(":title", "Comment");
			query.set_int(":visible", 0);
			query.set_int(":width", 70);
			query.execute();
			
			//year
			query.set_string(":title", "Year");
			query.set_int(":visible", 0);
			query.set_int(":width", 30);
			query.execute();
			
			
			//bitrate
			query.set_string(":title", "Bitrate");
			query.set_int(":visible", 0);
			query.set_int(":width", 20);
			query.execute();
			
			//rating
			query.set_string(":title", "Rating");
			query.set_int(":visible", 0);
			query.set_int(":width", 30);
			query.execute();
			
			//playcount
			query.set_string(":title", "Playcount");
			query.set_int(":visible", 0);
			query.set_int(":width", 15);
			query.execute();
			
			
			//date added
			query.set_string(":title", "Date Added");
			query.set_int(":visible", 0);
			query.set_int(":width", 40);
			query.execute();
			
			
			//last played
			query.set_string(":title", "Last Played");
			query.set_int(":visible", 0);
			query.set_int(":width", 40);
			query.execute();
			
			//bpm
			query.set_string(":title", "BPM");
			query.set_int(":visible", 0);
			query.set_int(":width", 30);
			query.execute();
			
			//file path
			query.set_string(":title", "File Path");
			query.set_int(":visible", 0);
			query.set_int(":width", 120);
			query.execute();
			
			//file size
			query.set_string(":title", "File Size");
			query.set_int(":visible", 0);
			query.set_int(":width", 70);
			query.execute();
			
			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			stdout.printf("Could not initialize values for song list columns: %s\n", err.message);
		}
	}
	
	public void save_song_list_columns(ArrayList<Gtk.TreeViewColumn> columns) {
		try {
			_db.execute("DELETE FROM `song_list_columns`");
			transaction = _db.begin_transaction();
			query = transaction.prepare ("INSERT INTO `song_list_columns` (`title`, `visible`, `width`) VALUES (:title, :visible, :width);");
			
			index = 0;
			item_count = columns.size;
			foreach(Gtk.TreeViewColumn tvc in columns) {
				stdout.printf("saving column %s\n", tvc.title);
				db_progress(null, ((double)index++)/((double)item_count));
				
				query.set_string(":title", tvc.title);
				query.set_int(":visible", tvc.visible ? 1 : 0);
				query.set_int(":width", tvc.width == 0 ? 50 : tvc.width);
				query.execute();
			}
			
			transaction.commit();
		}
		catch (SQLHeavy.Error err) {
			stdout.printf("Could not save columns: %s\n", err.message);
		}
	}
	
	/** SONGS **
	 * load_songs() loads songs from db
	 * 
	 * songs_from_search() loads songs from db using a simple LIKE %search%
	 * search. It compares the search to artist, album, title and genre.
	 * If it matches either, it will be included in the search
	 * 
	 * songs_from_artist() loads all songs given an artist name
	 */
	public ArrayList<Song> load_songs() {
		var rv = new ArrayList<Song>();
		
		try {
			string script = "SELECT rowid,* FROM `songs`";
			Query query = new Query(_db, script);
			
			for (var results = query.execute(); !results.finished; results.next() ) {
				Song s = new Song(results.fetch_string(1));
				s.rowid = results.fetch_int(0);
				s.title = results.fetch_string(2);
				s.artist = results.fetch_string(3);
				s.album = results.fetch_string(4);
				s.genre = results.fetch_string(5);
				s.comment = results.fetch_string(6);
				s.year = results.fetch_int(7);
				s.track = results.fetch_int(8);
				s.bitrate = results.fetch_int(9);
				s.length = results.fetch_int(10);
				s.samplerate = results.fetch_int(11);
				s.rating = results.fetch_int(12);
				s.play_count = results.fetch_int(13);
				s.date_added = results.fetch_int(14);
				s.last_played = results.fetch_int(15);
				
				rv.add(s);
			}
		}
		catch (SQLHeavy.Error err) {
			stdout.printf("Could not load song from db: %s\n", err.message);
		}
		
		return rv;
	}
	
	public void save_songs(Collection<Song> songs) {
		try {
			_db.execute("DELETE FROM `songs`");
			transaction = _db.begin_transaction();
			query = transaction.prepare ("INSERT INTO `songs` (`file`, `title`, `artist`, `album`, `genre`, `comment`, `year`, `track`, `bitrate`, `length`, `samplerate`, `rating`, `playcount`, `dateadded`, `lastplayed`) VALUES (:file, :title, :artist, :album, :genre, :comment, :year, :track, :bitrate, :length, :samplerate, :rating, :playcount, :dateadded, :lastplayed);");
			
			index = 0;
			item_count = songs.size;
			foreach(Song s in songs) {
				db_progress(null, ((double)index++)/((double)item_count));
				
				query.set_string(":file", s.file);
				query.set_string(":title", s.title);
				query.set_string(":artist", s.artist);
				query.set_string(":album", s.album);
				query.set_string(":genre", s.genre);
				query.set_string(":comment", s.comment);
				query.set_int(":year", s.year);
				query.set_int(":track", s.track);
				query.set_int(":bitrate", s.bitrate);
				query.set_int(":length", s.length);
				query.set_int(":samplerate", s.samplerate);
				query.set_int(":rating", s.rating);
				query.set_int(":playcount", s.play_count);
				query.set_int(":dateadded", s.date_added);
				query.set_int(":lastplayed", s.last_played);
				
				query.execute();
			}
			
			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			stdout.printf("Could not save songs: %s \n", err.message);
		}
	}
	
	/** Saves a song in the database during finding music to add. Only use with add_music. if id == 0, create new entry. Else
	 * update its information
	 * @param id The rowid to update
	 * @param s The song to save
	 */
	public void add_song_mass(Song s, bool saving) {
		try {
			query.set_string(":file", s.file);
			query.set_string(":title", s.title);
			query.set_string(":artist", s.artist);
			query.set_string(":album", s.album);
			query.set_string(":genre", s.genre);
			query.set_string(":comment", s.comment);
			query.set_int(":year", s.year);
			query.set_int(":track", s.track);
			query.set_int(":bitrate", s.bitrate);
			query.set_int(":length", s.length);
			query.set_int(":samplerate", s.samplerate);
			query.set_int(":rating", s.rating);
			query.set_int(":playcount", s.play_count);
			query.set_int(":dateadded", s.date_added);
			query.set_int(":lastplayed", s.last_played);
			
			if(saving)
				query.set_int(":rowid", s.rowid);
			
			query.execute();
		}
		catch(SQLHeavy.Error err) {
			stdout.printf("Could not set query to save song %d: %s \n", s.rowid, err.message);
		}
	}
	
	public void remove_songs(Collection<string> songs) {
		try {
			transaction = _db.begin_transaction();
			Query query = transaction.prepare("DELETE FROM `songs` WHERE file=:file");
			
			index = 0;
			item_count = songs.size;
			foreach(string s in songs) {
				db_progress(null, ((double)index++)/((double)item_count));
				
				query.set_string(":file", s);
				query.execute();
			}
			
			transaction.commit();
		}
		catch (SQLHeavy.Error err) {
			stdout.printf("Could not load song from db: %s\n", err.message);
		}
	}
	
	/** PLAYLISTS **
	 * load_playlists() loads playlists from db
	 * 
	 * playlist_from_id loads playlist of given rowid
	 * 
	 * playlist_from_name() loads playlsit given a name
	 */
	public Gee.ArrayList<Playlist> load_playlists() {
		var rv = new ArrayList<Playlist>();
		
		try {
			string script = "SELECT rowid,* FROM `playlists`";
			Query query = new Query(_db, script);
			
			for (var results = query.execute(); !results.finished; results.next() ) {
				Playlist p = new Playlist.with_info(results.fetch_int(0), results.fetch_string(1));
				p.songs_from_string(results.fetch_string(2));
				
				rv.add(p);
			}
		}
		catch (SQLHeavy.Error err) {
			stdout.printf("Could not load song from db: %s\n", err.message);
		}
		
		return rv;
	}
	
	public void save_playlists(Collection<Playlist> playlists) {
		try {
			_db.execute("DELETE FROM `playlists`");
			transaction = _db.begin_transaction();
			query = transaction.prepare ("INSERT INTO `playlists` (`name`, `songs`) VALUES (:name, :songs);");
			
			index = 0;
			item_count = playlists.size;
			foreach(Playlist p in playlists) {
				db_progress(null, ((double)index++)/((double)item_count));
				
				query.set_string(":name", p.name);
				query.set_string(":songs", p.songs_to_string());
				query.execute();
			}
			
			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			stdout.printf("Could not save playlists: %s \n", err.message);
		}
	}
	
	/** SMART PLAYLISTS **
	 * load_smart_playlists() loads smart playlists from db
	 * 
	 * smart_playlist_from_id() loads smart playlist by rowid
	 * 
	 * smart_playlist_from_name() searches db for smart playlist with given name
	 */
	public Gee.ArrayList<SmartPlaylist> load_smart_playlists() {
		var rv = new ArrayList<SmartPlaylist>();
		
		try {
			string script = "SELECT rowid,* FROM `smart_playlists`";
			Query query = new Query(_db, script);
			
			for (var results = query.execute(); !results.finished; results.next() ) {
				SmartPlaylist p = new SmartPlaylist();
				
				p.rowid = results.fetch_int(0);
				p.name = results.fetch_string(1);
				p.conditional = results.fetch_string(2);
				p.queries_from_string(results.fetch_string(3));
				
				rv.add(p);
			}
		}
		catch (SQLHeavy.Error err) {
			stdout.printf("Could not load song from db: %s\n", err.message);
		}
		
		return rv;
	}
	
	public void save_smart_playlists(Collection<SmartPlaylist> smarts) {
		try {
			_db.execute("DELETE FROM `smart_playlists`");
			transaction = _db.begin_transaction();
			query = transaction.prepare ("INSERT INTO `smart_playlists` (`name`, `and_or`, `queries`) VALUES (:name, :and_or, :queries);");
			
			index = 0;
			item_count = smarts.size;
			foreach(SmartPlaylist s in smarts) {
				db_progress(null, ((double)index++)/((double)item_count));
				
				query.set_string(":name", s.name);
				query.set_string(":and_or", s.conditional);
				query.set_string(":queries", s.queries_to_string());
				query.execute();
			}
			
			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			stdout.printf("Could not save smart playlists: %s \n", err.message);
		}
	}
	
	public void save_albums(Collection<LastFM.AlbumInfo> albums) {
		try {
			_db.execute("DELETE FROM `albums`");
			transaction = _db.begin_transaction();
			query = transaction.prepare("INSERT INTO `albums` (`name`, 'artist', `mbid`, `url`, 'release_date', 'listeners', 'playcount', 'tags', 'url_image') VALUES (:name, :artist, :mbid, :url, :release_date, :listeners, :playcount, :tags, :url_image);");
			
			foreach(LastFM.AlbumInfo a in albums) {
				query.set_string(":name", a.name);
				query.set_string(":artist", a.artist);
				query.set_string(":mbid", a.mbid);
				query.set_string(":url", a.url);
				query.set_string(":release_date", a.releasedate);
				query.set_int(":listeners", a.listeners);
				query.set_int(":playcount", a.playcount);
				
				string tags = "";
				foreach(LastFM.Tag tag in a.tags()) {
					tags += tag.tag + "<value_seperator>" + tag.url + "<tag_seperator>";
				}
				
				query.set_string(":tags", tags);
				query.set_string(":url_image", a.url_image.to_string());
				query.execute();
			}
			
			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			stdout.printf("Could not save albums: %s\n", err.message);
		}
	}
	
	public Collection<LastFM.AlbumInfo> load_albums() {
		var rv = new ArrayList<LastFM.AlbumInfo>();
		
		try {
			string script = "SELECT rowid,* FROM `albums`";
			Query query = new Query(_db, script);
			
			for (var results = query.execute(); !results.finished; results.next() ) {
				LastFM.AlbumInfo a = new LastFM.AlbumInfo.basic();
				
				int rowid = results.fetch_int(0);
				a.name = results.fetch_string(1);
				a.artist = results.fetch_string(2);
				a.mbid = results.fetch_string(3);
				a.url = results.fetch_string(4);
				a.releasedate = results.fetch_string(5);
				a.listeners = results.fetch_int(6);
				a.playcount = results.fetch_int(7);
				
				string tag_string = results.fetch_string(8);
				string[] tag_strings = tag_string.split("<tag_seperator>", 0);
				
				int index;
				for(index = 0; index < tag_strings.length - 1; ++index) {
					string[] tag_values = tag_strings[index].split("<value_seperator>", 0);
					
					LastFM.Tag t = new LastFM.Tag.with_string_and_url(tag_values[0], tag_values[1]);
					a.addTag(t);
				}
				
				string url_image = results.fetch_string(9);
				//string local_image = results.fetch_string(10);
				
				if(url_image != null && url_image != "")
					a.url_image = new LastFM.Image.with_import_string(url_image);
				else
					a.url_image = new LastFM.Image.basic();
				
				rv.add(a);
			}
		}
		catch (SQLHeavy.Error err) {
			stdout.printf("Could not load albums from db: %s\n", err.message);
		}
		
		return rv;
	}
	
	public Collection<LastFM.ArtistInfo> load_artists() {
		var rv = new ArrayList<LastFM.ArtistInfo>();
		
		try {
			string script = "SELECT rowid,* FROM `artists`";
			Query query = new Query(_db, script);
			
			for (var results = query.execute(); !results.finished; results.next() ) {
				LastFM.ArtistInfo a = new LastFM.ArtistInfo.basic();
				
				int rowid = results.fetch_int(0);
				a.name = results.fetch_string(1);
				a.mbid = results.fetch_string(2);
				a.url = results.fetch_string(3);
				a.streamable = results.fetch_int(4);
				a.listeners = results.fetch_int(5);
				a.playcount = results.fetch_int(6);
				a.published = results.fetch_string(7);
				a.summary = results.fetch_string(8);
				a.content = results.fetch_string(9);
				
				string tag_string = results.fetch_string(10);
				string[] tag_strings = tag_string.split("<tag_seperator>", 0);
				
				int index;
				for(index = 0; index < tag_strings.length - 1; ++index) {
					string[] tag_values = tag_strings[index].split("<value_seperator>", 0);
					
					LastFM.Tag t = new LastFM.Tag.with_string_and_url(tag_values[0], tag_values[1]);
					a.addTag(t);
				}
				
				string sim_string = results.fetch_string(11);
				string[] sim_strings = sim_string.split("<similar_seperator>", 0);
				
				for(index = 0; index < sim_strings.length - 1; ++index) {
					string[] sim_values = sim_strings[index].split("<value_seperator>", 0);
					
					LastFM.ArtistInfo sim = new LastFM.ArtistInfo.with_artist_and_url(sim_values[0], sim_values[1]);
					a.addSimilarArtist(sim);
				}
				
				string url_image = results.fetch_string(12);
				
				if(url_image != null && url_image != "")
					a.url_image = new LastFM.Image.with_import_string(url_image);
				else
					a.url_image = new LastFM.Image.basic();
					
				rv.add(a);
			}
		}
		catch (SQLHeavy.Error err) {
			stdout.printf("Could not load artist from db: %s\n", err.message);
		}
		
		return rv;
	}
	
	public void save_artists(Collection<LastFM.ArtistInfo> artists) {
		try {
			_db.execute("DELETE FROM `artists`");
			transaction = _db.begin_transaction();
			query = transaction.prepare("INSERT INTO `artists` (`name`, `mbid`, `url`, 'streamable', 'listeners', 'playcount', 'published', 'summary', 'content', 'tags', 'similar', 'url_image') VALUES (:name, :mbid, :url, :streamable, :listeners, :playcount, :published, :summary, :content, :tags, :similar, :url_image);");
			
			foreach(LastFM.ArtistInfo a in artists) {
				query.set_string(":name", a.name);
				query.set_string(":mbid", a.mbid);
				query.set_string(":url", a.url);
				query.set_int(":streamable", a.streamable);
				query.set_int(":listeners", a.listeners);
				query.set_int(":playcount", a.playcount);
				query.set_string(":published", a.published);
				query.set_string(":summary", a.summary);
				query.set_string(":content", a.content);
				
				string tags = "";
				foreach(LastFM.Tag tag in a.tags()) {
					tags += tag.tag + "<value_seperator>" + tag.url + "<tag_seperator>";
				}
				
				string similar = "";
				foreach(LastFM.ArtistInfo sim in a.similarArtists()) {
					similar += sim.name + "<value_seperator>" + sim.url + "<similar_seperator>";
				}
				
				query.set_string(":tags", tags);
				query.set_string(":similar", similar);
				query.set_string(":url_image", a.url_image.to_string());
				query.execute();
			}
			
			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			stdout.printf("Could not save artists: %s\n", err.message);
		}
	}
	
	public Collection<LastFM.TrackInfo> load_tracks() {
		var rv = new ArrayList<LastFM.TrackInfo>();
		
		try {
			string script = "SELECT rowid,* FROM `tracks`";
			Query query = new Query(_db, script);
			
			for (var results = query.execute(); !results.finished; results.next() ) {
				LastFM.TrackInfo t = new LastFM.TrackInfo.basic();
				
				int rowid = results.fetch_int(0);
				t.id = results.fetch_int(1);
				t.name = results.fetch_string(2);
				t.artist = results.fetch_string(3);
				t.url = results.fetch_string(4);
				t.duration = results.fetch_int(5);
				t.streamable = results.fetch_int(6);
				t.listeners = results.fetch_int(7);
				t.playcount = results.fetch_int(8);
				t.summary = results.fetch_string(9);
				t.content = results.fetch_string(10);
				
				string tag_string = results.fetch_string(11);
				string[] tag_strings = tag_string.split("<tag_seperator>", 0);
				
				int index;
				for(index = 0; index < tag_strings.length - 1; ++index) {
					string[] tag_values = tag_strings[index].split("<value_seperator>", 0);
					
					LastFM.Tag tag = new LastFM.Tag.with_string_and_url(tag_values[0], tag_values[1]);
					t.addTag(tag);
				}
				
				rv.add(t);
			}
		}
		catch (SQLHeavy.Error err) {
			stdout.printf("Could not load tracks from db: %s\n", err.message);
		}
		
		return rv;
	}
	
	public void save_tracks(Collection<LastFM.TrackInfo> tracks) {
		try {
			_db.execute("DELETE FROM `tracks`");
			transaction = _db.begin_transaction();
			query = transaction.prepare("INSERT INTO `tracks` ('id', `name`, `artist`, `url`, 'duration', 'streamable', 'listeners', 'playcount', 'summary', 'content', 'tags') VALUES (:id, :name, :artist, :url, :duration, :streamable, :listeners, :playcount, :summary, :content, :tags);");
			
			foreach(LastFM.TrackInfo t in tracks) {
				query.set_int(":id", t.id);
				query.set_string(":name", t.name);
				query.set_string(":artist", t.artist);
				query.set_string(":url", t.url);
				query.set_int(":duration", t.duration);
				query.set_int(":streamable", t.streamable);
				query.set_int(":listeners", t.listeners);
				query.set_int(":playcount", t.playcount);
				query.set_string(":summary", t.summary);
				query.set_string(":content", t.content);
				
				string tags = "";
				foreach(LastFM.Tag tag in t.tags()) {
					tags += tag.tag + "<value_seperator>" + tag.url + "<tag_seperator>";
				}
				
				query.set_string(":tags", tags);
				query.execute();
			}
			
			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			stdout.printf("Could not save tracks: %s\n", err.message);
		}
	}
}
