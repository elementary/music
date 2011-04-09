using SQLHeavy;
using TagLib;
using Gee;

public class BeatBox.DataBaseManager : GLib.Object {
	public const int COLUMN_COUNT = 17;
	
	SQLHeavy.Database _db;
	
	Transaction transaction;// the current sql transaction
	
	int index;
	int item_count;
	public signal void db_progress(string? message, double progress);
	
	/** Creates a new DatabaseManager
	 * @param write True if has write access
	 * @param create True to have create access
	 */
	public DataBaseManager() {
		bool need_create = false;
		GLib.File beatbox_folder;
		GLib.File db_file;
		
		beatbox_folder = GLib.File.new_for_path(GLib.Path.build_filename(Environment.get_user_data_dir(), "/beatbox"));
		if(!beatbox_folder.query_exists()) {
			try {
				beatbox_folder.make_directory(null);
			}
			catch(GLib.Error err) {
				stdout.printf("CRITICAL: Could not create beatbox folder in data directory: %s\n", err.message);
			}
		}
		
		db_file = GLib.File.new_for_path(GLib.Path.build_filename(beatbox_folder.get_path(), "/beatbox_db.db"));
		if(!db_file.query_exists())
			need_create = true;
		
		try {
			_db = new SQLHeavy.Database (db_file.get_path(), SQLHeavy.FileMode.READ | SQLHeavy.FileMode.WRITE | SQLHeavy.FileMode.CREATE);
		}
		catch (SQLHeavy.Error err) {
			stdout.printf("This is terrible. Could not even load database. Please report this. Message: %s", err.message);
		}
		
        // disable synchronized commits for performance reasons ... this is not vital
        _db.synchronous = SQLHeavy.SynchronousMode.from_string("OFF");
        _db.sql_executed.connect ((sql) => { GLib.debug ("SQL: %s \n", sql); });
	
		if(need_create) {
			try {
				_db.execute("CREATE TABLE playlists (`name` TEXT, `songs` TEXT, 'sort_column' TEXT, 'sort_direction' TEXT, 'columns' TEXT)");
				_db.execute("CREATE TABLE smart_playlists (`name` TEXT, `and_or` TEXT, `queries` TEXT, 'limit' INT, 'limit_amount' INT, 'sort_column' TEXT, 'sort_direction' TEXT, 'columns' TEXT)");
				_db.execute("CREATE TABLE songs (`file` TEXT,`title` TEXT,`artist` TEXT,`album` TEXT,`genre` TEXT,`comment` TEXT, `year` INT, `track` INT, `bitrate` INT, `length` INT, `samplerate` INT, `rating` INT, `playcount` INT, 'skipcount' INT, `dateadded` INT, `lastplayed` INT, 'file_size' INT, 'lyrics' TEXT)");
				_db.execute("CREATE TABLE artists ('name' TEXT, 'mbid' TEXT, 'url' TEXT, 'streamable' INT, 'listeners' INT, 'playcount' INT, 'published' TEXT, 'summary' TEXT, 'content' TEXT, 'tags' TEXT, 'similar' TEXT, 'url_image' TEXT)");
				_db.execute("CREATE TABLE albums ('name' TEXT, 'artist' TEXT, 'mbid' TEXT, 'url' TEXT, 'release_date' TEXT, 'listeners' INT, 'playcount' INT, 'tags' TEXT,  'url_image' TEXT)");
				_db.execute("CREATE TABLE tracks ('id' INT, 'name' TEXT, 'artist' TEXT, 'url' TEXT, 'duration' INT, 'streamable' INT, 'listeners' INT, 'playcount' INT, 'summary' TEXT, 'content' TEXT, 'tags' TEXT)");
				addDefaultSmartPlaylists();
			}
			catch (SQLHeavy.Error err) {
				stdout.printf("Bad news: could not create tables. Please report this. Message: %s\n", err.message);
			}
		}
		
		/* now make sure db schema is up to date. 
		 * Whenever field is added, do check here and add above as well 
		*/
		if(_db.get_table("songs").field_count == 17) {
			stdout.printf("Could not find lyric field, adding it\n");
			_db.execute("ALTER TABLE songs ADD lyrics TEXT");
		}
		
		/* now clean up and just reload the db (this also gets rid of signals that
		 * were connected when doing the above work... bug in sqlheavy i believe.s */
		try {
			_db = new SQLHeavy.Database (db_file.get_path(), SQLHeavy.FileMode.READ | SQLHeavy.FileMode.WRITE | SQLHeavy.FileMode.CREATE);
		}
		catch (SQLHeavy.Error err) {
			stdout.printf("This is terrible. Could not even load database. Please report this. Message: %s", err.message);
		}
	}
	
	public void resetProgress(int items) {
		index = 0;
		item_count = items;
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
				s.skip_count = results.fetch_int(14);
				s.date_added = results.fetch_int(15);
				s.last_played = results.fetch_int(16);
				s.file_size = results.fetch_int(17);
				s.lyrics = results.fetch_string(18);
				
				rv.add(s);
			}
		}
		catch (SQLHeavy.Error err) {
			stdout.printf("Could not load songs from db: %s\n", err.message);
		}
		
		return rv;
	}
	
	public void save_songs(Collection<Song> songs) {
		try {
			_db.execute("DELETE FROM `songs`");
			transaction = _db.begin_transaction();
			Query query = transaction.prepare ("INSERT INTO `songs` (`file`, `title`, `artist`, `album`, `genre`, `comment`, `year`, `track`, `bitrate`, `length`, `samplerate`, `rating`, `playcount`, 'skipcount', `dateadded`, `lastplayed`, 'file_size', 'lyrics') VALUES (:file, :title, :artist, :album, :genre, :comment, :year, :track, :bitrate, :length, :samplerate, :rating, :playcount, :skipcount, :dateadded, :lastplayed, :file_size, :lyrics);");
			
			foreach(Song s in songs) {
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
				query.set_int(":skipcount", s.skip_count);
				query.set_int(":dateadded", s.date_added);
				query.set_int(":lastplayed", s.last_played);
				query.set_int(":file_size", s.file_size);
				query.set_string(":lyrics", s.lyrics);
				
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
	public void remove_songs(Collection<string> songs) {
		try {
			transaction = _db.begin_transaction();
			Query query = transaction.prepare("DELETE FROM `songs` WHERE file=:file");
			
			foreach(string s in songs) {
				query.set_string(":file", s);
				query.execute();
			}
			
			transaction.commit();
		}
		catch (SQLHeavy.Error err) {
			stdout.printf("Could not remove songs from db: %s\n", err.message);
		}
	}
	
	public void update_songs(Gee.Collection<Song> songs) {
		try {
			transaction = _db.begin_transaction();
			Query query = transaction.prepare("UPDATE `songs` SET file=:file, title=:title, artist=:artist, album=:album, genre=:genre, comment=:comment, year=:year, track=:track, bitrate=:bitrate, length=:length, samplerate=:samplerate, rating=:rating, playcount=:playcount, skipcount=:skipcount, dateadded=:dateadded, lastplayed=:lastplayed, file_size=:file_size, lyrics=:lyrics WHERE rowid=:rowid");
			
			foreach(Song s in songs) {
				if(s.rowid != 0) {
					query.set_string(":rowid", s.rowid.to_string());
				}
				
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
				query.set_int(":skipcount", s.skip_count);
				query.set_int(":dateadded", s.date_added);
				query.set_int(":lastplayed", s.last_played);
				query.set_int(":file_size", s.file_size);
				query.set_string(":lyrics", s.lyrics);
				
				query.execute();
			}
			
			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			stdout.printf("Could not update songs: %s \n", err.message);
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
				p.tvs.sort_column = results.fetch_string(3);
				p.tvs.set_sort_direction_from_string(results.fetch_string(4));
				p.tvs.import_columns(results.fetch_string(5));
				
				rv.add(p);
			}
		}
		catch (SQLHeavy.Error err) {
			stdout.printf("Could not load playlists from db: %s\n", err.message);
		}
		
		return rv;
	}
	
	public void save_playlists(Collection<Playlist> playlists) {
		try {
			_db.execute("DELETE FROM `playlists`");
			transaction = _db.begin_transaction();
			Query query = transaction.prepare ("INSERT INTO `playlists` (`name`, `songs`, 'sort_column', 'sort_direction', 'columns') VALUES (:name, :songs, :sort_column, :sort_direction, :columns);");
			
			foreach(Playlist p in playlists) {
				query.set_string(":name", p.name);
				query.set_string(":songs", p.songs_to_string());
				query.set_string(":sort_column", p.tvs.sort_column);
				query.set_string(":sort_direction", p.tvs.sort_direction_to_string());
				query.set_string(":columns", p.tvs.columns_to_string());
				
				query.execute();
			}
			
			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			stdout.printf("Could not save playlists: %s \n", err.message);
		}
	}
	
	public void update_playlist(Playlist p) {
		try {
			transaction = _db.begin_transaction();
			Query query = transaction.prepare("UPDATE `playlists` SET name=:name, songs=:songs, sort_column=:sort_column, sort_direction=:sort_direction, columns=:columns  WHERE name=:name");
			
			query.set_string(":name", p.name);
			query.set_string(":songs", p.songs_to_string());
			query.set_string(":sort_column", p.tvs.sort_column);
			query.set_string(":sort_direction", p.tvs.sort_direction_to_string());
			query.set_string(":columns", p.tvs.columns_to_string());
				
			query.execute();
			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			stdout.printf("Could not update playlist: %s \n", err.message);
		}
	}
	
	/** SMART PLAYLISTS **
	 * load_smart_playlists() loads smart playlists from db
	 * 
	 * smart_playlist_from_id() loads smart playlist by rowid
	 * 
	 * smart_playlist_from_name() searches db for smart playlist with given name
	 */
	public void addDefaultSmartPlaylists() {
		try {
			TreeViewSetup tvs = new TreeViewSetup("#", Gtk.SortType.ASCENDING, MusicTreeView.Hint.SMART_PLAYLIST);
			transaction = _db.begin_transaction();
			Query query = transaction.prepare ("INSERT INTO `smart_playlists` (`name`, `and_or`, `queries`, 'limit', 'limit_amount', 'sort_column', 'sort_direction', 'columns') VALUES (:name, :and_or, :queries, :limit, :limit_amount, :sort_column, :sort_direction, :columns);");
			
			query.set_string(":name", "Favorites");
			query.set_string(":and_or", "any");
			query.set_string(":queries", "Rating<value_seperator>is at least<value_seperator>4<query_seperator>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_string(":sort_column", "Rating");
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();
			
			query.set_string(":name", "Recently Added");
			query.set_string(":and_or", "any");
			query.set_string(":queries", "Date Added<value_seperator>is within<value_seperator>7<query_seperator>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_string(":sort_column", "Artist");
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();
			
			query.set_string(":name", "Recently Played");
			query.set_string(":and_or", "any");
			query.set_string(":queries", "Last Played<value_seperator>is within<value_seperator>7<query_seperator>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_string(":sort_column", "Last Played");
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();
			
			query.set_string(":name", "Recent Favorites");
			query.set_string(":and_or", "any");
			query.set_string(":queries", "Last Played<value_seperator>is within<value_seperator>7<query_seperator>Rating<value_seperator>is at least<value_seperator>4<query_seperator>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_string(":sort_column", "Rating");
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();
			
			query.set_string(":name", "Never Played");
			query.set_string(":and_or", "any");
			query.set_string(":queries", "Playcount<value_seperator>is exactly<value_seperator>0<query_seperator>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_string(":sort_column", "Artist");
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();
			
			query.set_string(":name", "Over Played");
			query.set_string(":and_or", "any");
			query.set_string(":queries", "Playcount<value_seperator>is at least<value_seperator>10<query_seperator>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_string(":sort_column", "Plays");
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();
			
			query.set_string(":name", "Not Recently Played");
			query.set_string(":and_or", "any");
			query.set_string(":queries", "Last Played<value_seperator>is before<value_seperator>7<query_seperator>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_string(":sort_column", tvs.sort_column);
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();
			
			transaction.commit();
		}
		catch (SQLHeavy.Error err) {
			stdout.printf("Could not initialize smart playlists: %s\n", err.message);
		}
	}
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
				p.limit = ( results.fetch_string(4) == "1") ? true : false;
				p.limit_amount = results.fetch_int(5);
				p.tvs.sort_column = results.fetch_string(6);
				p.tvs.set_sort_direction_from_string(results.fetch_string(7));
				p.tvs.import_columns(results.fetch_string(8));
				
				rv.add(p);
			}
		}
		catch (SQLHeavy.Error err) {
			stdout.printf("Could not load smart playlists from db: %s\n", err.message);
		}
		
		return rv;
	}
	
	public void save_smart_playlists(Collection<SmartPlaylist> smarts) {
		try {
			_db.execute("DELETE FROM `smart_playlists`");
			transaction = _db.begin_transaction();
			Query query = transaction.prepare ("INSERT INTO `smart_playlists` (`name`, `and_or`, `queries`, 'limit', 'limit_amount', 'sort_column', 'sort_direction', 'columns') VALUES (:name, :and_or, :queries, :limit, :limit_amount, :sort_column, :sort_direction, :columns);");
			
			index = 0;
			item_count = smarts.size;
			foreach(SmartPlaylist s in smarts) {
				db_progress(null, ((double)index++)/((double)item_count));
				
				query.set_string(":name", s.name);
				query.set_string(":and_or", s.conditional);
				query.set_string(":queries", s.queries_to_string());
				query.set_int(":limit", ( s.limit ) ? 1 : 0);
				query.set_int(":limit_amount", s.limit_amount);
				query.set_string(":sort_column", s.tvs.sort_column);
				query.set_string(":sort_direction", s.tvs.sort_direction_to_string());
				query.set_string(":columns", s.tvs.columns_to_string());
				
				query.execute();
			}
			
			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			stdout.printf("Could not save smart playlists: %s \n", err.message);
		}
	}
	
	public void update_smart_playlist(SmartPlaylist p) {
		try {
			transaction = _db.begin_transaction();
			Query query = transaction.prepare("UPDATE `smart_playlists` SET name=:name, and_or=:and_or, queries=:queries, limit=:limit, limit_amount=:limit_amount, sort_column=:sort_column, sort_direction=:sort_direction, columns=:columns WHERE name=:name");
			
			query.set_string(":name", p.name);
			query.set_string(":and_or", p.conditional);
			query.set_string(":queries", p.queries_to_string());
			query.set_int(":limit", ( p.limit ) ? 1 : 0);
			query.set_int(":limit_amount", p.limit_amount);
			query.set_string(":sort_column", p.tvs.sort_column);
			query.set_string(":sort_direction", p.tvs.sort_direction_to_string());
			query.set_string(":columns", p.tvs.columns_to_string());
				
			query.execute();
			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			stdout.printf("Could not update smart playlist: %s \n", err.message);
		}
	}
	
	/** Last FM objects **/
	public void save_albums(Collection<LastFM.AlbumInfo> albums) {
		try {
			_db.execute("DELETE FROM `albums`");
			transaction = _db.begin_transaction();
			Query query = transaction.prepare("INSERT INTO `albums` (`name`, 'artist', `mbid`, `url`, 'release_date', 'listeners', 'playcount', 'tags', 'url_image') VALUES (:name, :artist, :mbid, :url, :release_date, :listeners, :playcount, :tags, :url_image);");
			
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
				
				//int rowid = results.fetch_int(0);
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
				
				//int rowid = results.fetch_int(0);
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
			Query query = transaction.prepare("INSERT INTO `artists` (`name`, `mbid`, `url`, 'streamable', 'listeners', 'playcount', 'published', 'summary', 'content', 'tags', 'similar', 'url_image') VALUES (:name, :mbid, :url, :streamable, :listeners, :playcount, :published, :summary, :content, :tags, :similar, :url_image);");
			
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
				
				//int rowid = results.fetch_int(0);
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
			Query query = transaction.prepare("INSERT INTO `tracks` ('id', `name`, `artist`, `url`, 'duration', 'streamable', 'listeners', 'playcount', 'summary', 'content', 'tags') VALUES (:id, :name, :artist, :url, :duration, :streamable, :listeners, :playcount, :summary, :content, :tags);");
			
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
