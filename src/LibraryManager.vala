using Gee;
using Gtk;

/** This is where all the song stuff happens. Here, songs are retrieved
 * from the db, added to the queue, sorted, and more. LibraryWindow is
 * the visual representation of this class
 */
public class BeatBox.LibraryManager : GLib.Object {
	public BeatBox.Settings settings;
	public BeatBox.DataBaseManager dbm;
	public BeatBox.DataBaseUpdater dbu;
	public BeatBox.FileOperator fo;
	public BeatBox.StreamPlayer player;
	
	private HashMap<int, SmartPlaylist> _smart_playlists; // rowid, smart playlist
	private HashMap<int, Playlist> _playlists; // rowid, playlist of all playlists
	private HashMap<int, Song> _songs; // rowid, song of all songs
	private HashMap<int, int> _current; // id, song of current songs.
	private HashMap<int, int> _current_shuffled;//list of id's yet to be played while on shuffle
	private HashMap<int, int> _current_view; // id, song of currently showing songs
	private LinkedList<int> _queue; // rowid, Song of queue
	private LinkedList<int> _already_played; // Song of already played
	
	public LastFM.Core lfm;
	private HashMap<string, LastFM.ArtistInfo> _artists;//key:artist
	private HashMap<string, LastFM.AlbumInfo> _albums;//key:artist<sep>album
	private HashMap<string, LastFM.TrackInfo> _tracks;//key:artist<sep>album<sep>track
	
	public TreeViewSetup music_setup;
	public TreeViewSetup similar_setup;
	public TreeViewSetup queue_setup;
	public TreeViewSetup history_setup;
	
	public int _played_index;//if user press back, this goes back 1 until it hits 0. as new songs play, this goes with it
	public int _current_index;
	public int _current_shuffled_index;
	public BeatBox.SongInfo song_info;
	
	public bool playing;
	public Repeat repeat;
	public Shuffle shuffle;
	
	private string temp_add_folder;
	public bool doing_file_operations;
	
	public signal void music_counted(int count);
	public signal void music_added(LinkedList<string> not_imported);
	public signal void music_imported(LinkedList<Song> new_songs, LinkedList<string> not_imported);
	public signal void music_rescanned(LinkedList<Song> new_songs, LinkedList<string> not_imported);
	public signal void progress_notification(string? message, double progress);
	public signal void file_operations_done();
	
	public signal void current_cleared();
	public signal void song_added(int id);
	public signal void songs_updated(LinkedList<int> ids);
	public signal void songs_removed(LinkedList<int> ids);
	public signal void song_queued(int id);
	public signal void song_played(int id, int old_id);
	
	public enum Shuffle {
		OFF,
		ARTIST,
		ALBUM,
		ALL;
	}
	
	public enum Repeat {
		OFF,
		ALL,
		ARTIST,
		ALBUM,
		SONG;
	}
	
	public LibraryManager(StreamPlayer player, BeatBox.DataBaseManager dbmn, BeatBox.Settings sett) {
		this.player = player;
		this.settings = sett;
		
		this.dbm = dbmn;
		this.dbu = new DataBaseUpdater(dbm);
		this.fo = new BeatBox.FileOperator(this, settings);
		
		fo.fo_progress.connect(dbProgress);
		dbm.db_progress.connect(dbProgress);
		
		_smart_playlists = new HashMap<int, SmartPlaylist>();
		_playlists = new HashMap<int, Playlist>();
		_songs = new HashMap<int, Song>();
		_current = new HashMap<int, int>();
		_current_shuffled = new HashMap<int, int>();
		_current_view = new HashMap<int, int>();
		_queue = new LinkedList<int>();
		_already_played = new LinkedList<int>();
		
		lfm = new LastFM.Core(this);
		_artists = new HashMap<string, LastFM.ArtistInfo>();
		_albums = new HashMap<string, LastFM.AlbumInfo>();
		_tracks = new HashMap<string, LastFM.TrackInfo>();
		
		_played_index = 0;
		
		song_info = new BeatBox.SongInfo();
		song_info.track = new LastFM.TrackInfo.basic();
		song_info.artist = new LastFM.ArtistInfo.basic();
		song_info.album = new LastFM.AlbumInfo.basic();
		
		repeat = Repeat.OFF;
		shuffle = Shuffle.OFF;
		doing_file_operations = false;
		
		music_setup = new TreeViewSetup("Artist", Gtk.SortType.ASCENDING);
		similar_setup = new TreeViewSetup("#", Gtk.SortType.ASCENDING);
		queue_setup = new TreeViewSetup("#", Gtk.SortType.ASCENDING);
		history_setup = new TreeViewSetup("#", Gtk.SortType.ASCENDING);
		
		//load all songs from db
		foreach(Song s in dbm.load_songs()) {
			_songs.set(s.rowid, s);
		}
		
		foreach(SmartPlaylist p in dbm.load_smart_playlists()) {
			_smart_playlists.set(p.rowid, p);
		}
		
		//load all playlists from db
		foreach(Playlist p in dbm.load_playlists()) {
			_playlists.set(p.rowid, p);
			
			if(p.name == "autosaved_music") {
				music_setup = p.tvs;
				_playlists.unset(p.rowid);
			}
			else if(p.name == "autosaved_similar") {
				similar_setup = p.tvs;
				_playlists.unset(p.rowid);				
			}
			else if(p.name == "autosaved_queue") {
				foreach(int i in songs_from_playlist(p.rowid)) {
					queue_song_by_id(i);
				}
				
				queue_setup = p.tvs;
				_playlists.unset(p.rowid);
			}
			else if(p.name == "autosaved_history") {
				history_setup = p.tvs;
				_playlists.unset(p.rowid);
			}
		}
		
		foreach(LastFM.ArtistInfo a in dbm.load_artists()) {
			_artists.set(a.name, a);
		}
		
		foreach(LastFM.AlbumInfo a in dbm.load_albums()) {
			_albums.set(a.name + " by " + a.artist, a);
		}
		
		foreach(LastFM.TrackInfo t in dbm.load_tracks()) {
			_tracks.set(t.name + " by " + t.artist, t);
		}
	}
	
	/************ Library/Collection management stuff ************/
	public virtual void dbProgress(string? message, double progress) {
		progress_notification(message, progress);
	}
	
	public void set_music_folder(string folder) {
		if(!doing_file_operations) {
			doing_file_operations = true;
			progress_notification("Importing music from " + folder + ". This may take a while", 0.0);
			
			settings.setMusicFolder(folder);
			try {
				Thread.create<void*>(set_music_thread_function, false);
			}
			catch(GLib.Error err) {
				stdout.printf("Could not create thread to set music folder: %s\n", err.message);
			}
		}
	}
        
        // i should do the actual file browsing here
	public void* set_music_thread_function () {
		var file = GLib.File.new_for_path(settings.getMusicFolder());
		
		var items = fo.count_music_files(file);
		music_counted(items);
		fo.resetProgress(items);
		
		var new_songs = new LinkedList<Song>();
		var not_imported = new LinkedList<string>();
		fo.get_music_files(file, ref new_songs, ref not_imported);
		
		_songs.clear();
		_queue.clear();
		//_current.clear();
		
		int index = 1;
		foreach(Song s in new_songs) {
			s.rowid = index++;
			add_song(s);
		}
		
		progress_notification("Populating list...", 0.0);
		
		Idle.add( () => { 
			save_songs();
			music_added(not_imported); 
			return false; 
		});
		
		doing_file_operations = false;
		file_operations_done();
		return null;
	}
	
	public void add_folder_to_library(string folder) {
		if(!doing_file_operations) {
			doing_file_operations = true;
			progress_notification("Adding music from " + folder + " to library. This may take a while", 0.0);
			
			temp_add_folder = folder;
			try {
				Thread.create<void*>(add_folder_to_library_thread, false);
			}
			catch(GLib.Error err) {
				stdout.printf("Could not create thread to add music folder: %s\n", err.message);
			}
		}
	}
	
	public void* add_folder_to_library_thread () {
		var file = GLib.File.new_for_path(temp_add_folder);
		
		var items = fo.count_music_files(file);
		music_counted(items);
		fo.resetProgress(items);
		
		var new_songs = new LinkedList<Song>();
		var not_imported = new LinkedList<string>();
		fo.get_music_files(file, ref new_songs, ref not_imported);
		
		int index = 1;
		
		// start at biggest value
		foreach(int i in _songs.keys) {
			if(i > index)
				index = i + 1;
		}
		
		fo.resetProgress(new_songs.size);
		progress_notification("<b>Copying</b> files to <b>Music Folder</b>", 0.0);
		int progress = 0;
		foreach(Song s in new_songs) {
			s.rowid = index++;
			stdout.printf("new song in import %s with rowid %d\n", s.title, s.rowid);
			add_song(s);
			
			if(settings.getCopyImportedMusic())
				fo.update_file_hierarchy(s, false);
			
			progress++;
			progress_notification(null, (double)((double)progress)/((double)new_songs.size));
		}
		
		Idle.add( () => { 
			save_songs();
			music_imported(new_songs, not_imported); 
			return false; 
		});
		
		doing_file_operations = false;
		file_operations_done();
		return null;
	}
        
	public void rescan_music_folder() {
		if(!doing_file_operations) {
			doing_file_operations = true;
			progress_notification("Rescanning music for changes. This may take a while", 0.0);
			
			try {
					Thread.create<void*>(rescan_music_thread_function, false);
			}
			catch(GLib.Error err) {
					stdout.printf("Could not create thread to rescan music folder: %s\n", err.message);
			}
		}
	}
        
	public void* rescan_music_thread_function () {
		LinkedList<string> paths = new LinkedList<string>();
		LinkedList<Song> removed = new LinkedList<Song>();
		
		foreach(Song s in _songs.values) {
				paths.add(s.file);
		}
		
		fo.resetProgress(paths.size);
		
		var not_imported = new LinkedList<string>();
		var new_songs = new LinkedList<Song>();
		fo.rescan_music(GLib.File.new_for_path(settings.getMusicFolder()), ref paths, ref not_imported, ref new_songs);
		
		// all songs remaining are no longer in folder hierarchy
		int index = 1;
		lock(_songs) {
			foreach(Song s in _songs.values) {
				if(s.rowid > index)
					index = s.rowid + 1;
				
				foreach(string path in paths) {
					if(s.file == path)
						removed.add(s);
				}
			}
		}
		
		lock(_songs) {
			remove_songs(removed);
		}
		
		foreach(Song s in new_songs) {
			s.rowid = index++;
			stdout.printf("new song in rescan %s with rowid %d\n", s.title, s.rowid);
			add_song(s);
			
			if(settings.getCopyImportedMusic())
				fo.update_file_hierarchy(s, false);
		}
		
		dbm.remove_songs(paths);
		
		Idle.add( () => { 
			//maybe pass in songs_added, which appends those songs to the treeview?
			music_rescanned(new_songs, not_imported); 
			return false; 
		});
		
		doing_file_operations = false;
		file_operations_done();
		return null;
	}
	
	/******************** Song list columns *******************/
	public LinkedList<Gtk.TreeViewColumn> fresh_columns() {
		return dbm.load_song_list_columns();
	}
	
	/************************ Playlist stuff ******************/
	public int playlist_count() {
		return _playlists.size;
	}
	
	public Collection<Playlist> playlists() {
		return _playlists.values;
	}
	
	public HashMap<int, Playlist> playlist_hash() {
		return _playlists;
	}
	
	public void save_playlists() {
		var playlists_and_queue = new LinkedList<Playlist>();
		playlists_and_queue.add_all(_playlists.values);
		
		Playlist p_queue = new Playlist();
		p_queue.name = "autosaved_queue";
		foreach(int i in _queue) {
			p_queue.addSong(song_from_id(i));
		}
		p_queue.tvs = queue_setup;
		
		Playlist p_history = new Playlist();
		p_history.name = "autosaved_history";
		p_history.tvs = history_setup;
		
		Playlist p_similar = new Playlist();
		p_similar.name = "autosaved_similar";
		p_similar.tvs = similar_setup;
		
		Playlist p_music = new Playlist();
		p_music.name = "autosaved_music";
		p_music.tvs = music_setup;
		
		playlists_and_queue.add(p_queue);
		playlists_and_queue.add(p_history);
		playlists_and_queue.add(p_similar);
		playlists_and_queue.add(p_music);
		dbm.save_playlists(playlists_and_queue);
	}
	
	public Playlist playlist_from_id(int id) {
		return _playlists.get(id);
	}
	
	public int add_playlist(Playlist p) {
		p.rowid = _playlists.size + 1;
		_playlists.set(p.rowid, p);
		
		return p.rowid;
	}
	
	public void remove_playlist(int id) {
		Playlist removed;
		_playlists.unset(id, out removed);
	}
	
	/**************** Smart playlists ****************/
	public int smart_playlist_count() {
		return _smart_playlists.size;
	}
	
	public Collection<SmartPlaylist> smart_playlists() {
		return _smart_playlists.values;
	}
	
	public HashMap<int, SmartPlaylist> smart_playlist_hash() {
		return _smart_playlists;
	}
	
	public SmartPlaylist smart_playlist_from_id(int id) {
		return _smart_playlists.get(id);
	}
	
	public void save_smart_playlists() {
		dbm.save_smart_playlists(_smart_playlists.values);
	}
	
	public int add_smart_playlist(SmartPlaylist p) {
		p.rowid = _smart_playlists.size + 1;// + 1 for 1-based db
		_smart_playlists.set(p.rowid, p);
		
		return p.rowid;
	}
	
	public void remove_smart_playlist(int id) {
		SmartPlaylist removed;
		_smart_playlists.unset(id, out removed);
	}
	
	/******************** Song stuff ******************/
	public void clear_songs() {
		_songs.clear();
	}
	
	public int song_count() {
		return _songs.size;
	}
	
	public Collection<Song> songs() {
		return _songs.values;
	}
	
	public Collection<int> song_ids() {
		return _songs.keys;
	}
	
	public HashMap<int, Song> song_hash() {
		return _songs;
	}
	
	public void update_song(Song s, bool updateMeta) {
		LinkedList<Song> one = new LinkedList<Song>();
		one.add(s);
		
		update_songs(one, updateMeta);
	}
	
	public void update_songs(Collection<Song> updates, bool updateMeta) {
		LinkedList<int> rv = new LinkedList<int>();
		
		foreach(Song s in updates) {
			_songs.set(s.rowid, s);
			
			rv.add(s.rowid);
		}
		
		songs_updated(rv);
		
		/* now do background work */
		if(updateMeta)
			fo.save_songs(updates);
		
		dbu.updateItem(updates);
	}
	
	public void save_songs() {
		try {
			Thread.create<void*>( () => { 
				lock(_songs) {
					dbm.save_songs(_songs.values);
				} 
				
				return null; 
			}, false);
		}
		catch(GLib.Error err) {
			stdout.printf("Could not create thread to rescan music folder: %s\n", err.message);
		}
	}
	
	/** Used extensively. All other song data stores a song rowid, and then
	 * use this to retrieve the song. This is for memory saving and 
	 * consistency
	 */
	public Song song_from_id(int id) {
		return _songs.get(id);
	}
	
	public Song song_from_name(string title, string artist) {
		Song rv = new Song("");
		rv.title = title;
		rv.artist = artist;
		
		lock (_songs) {
			foreach(Song s in _songs.values) {
				if(s.title.down() == title.down() && s.artist.down() == artist.down())
					return s;
			}
		}
		
		return rv;
	}
	
	public Song? song_from_file(string file) {
		lock(_songs) {
			foreach(Song s in _songs.values) {
				if(s.file == file)
					return s;
			}
		}
		
		return null;
	}
	
	public Collection<int> songs_from_search(string search, Collection<int> songs_to_search) {
		string l_search = search.down();
		
		if(search == null || search == "")
			return songs_to_search;
		
		var rv = new ArrayList<int>();
		
		foreach(int i in songs_to_search) {
			Song s = song_from_id(i);
			if(l_search in s.title.down() || l_search in s.artist.down() || l_search in s.album.down() || l_search in s.genre.down())
				rv.add(i);
		}
		
		return rv;
	}
	
	public LinkedList<int> songs_from_playlist(int id) {
		return _playlists.get(id).analyze(this);
	}
	
	public LinkedList<int> songs_from_smart_playlist(int id) {
		return _smart_playlists.get(id).analyze(this);
	}
	
	/** make this smarter **/
	public void add_song(Song s) {
		//fill in rowid's
		if(s.rowid == 0) {
			int index = 1;
			foreach(int i in _songs.keys) {
				if(i > index)
					index = i + 1;
			}
			stdout.printf("Song %s by %s new rowid: %d\n", s.title, s.artist, index);
			s.rowid = index + 1;
		}
		
		_songs.set(s.rowid, s);
		
		song_added(s.rowid);
	}
	
	public void remove_songs(LinkedList<Song> toRemove) {
		LinkedList<int> removedIds = new LinkedList<int>();
		LinkedList<string> removePaths = new LinkedList<string>();
		
		//string file_path = song_from_id(id).file;
		foreach(Song s in toRemove) {
			removedIds.add(s.rowid);
			removePaths.add(s.file);
		}
		
		songs_removed(removedIds);
		
		dbu.removeItem(removePaths);
		fo.remove_songs(removePaths);
		
		foreach(Song s in toRemove) {
			_songs.unset(s.rowid);
		}
	}
	
	/**************** Queue Stuff **************************/
	public bool queue_empty() {
		return (_queue.size == 0);
	}
	
	public void clear_queue() {
		_queue.clear();
	}
	
	public void queue_song_by_id(int id) {
		_queue.offer_tail(id);
	}
	
	public void unqueue_song_by_id(int id) {
		_queue.remove(id);
	}
	
	public int peek_queue() {
		return _queue.peek_head();
	}
	
	public int poll_queue() {
		return _queue.poll_head();
	}
	
	public Collection<int> queue() {
		return _queue;
	}
	
	/************ Already Played Stuff **************/
	public void reset_already_played() {
		_already_played.clear();
	}
	
	public void add_already_played(int i) {
		_already_played.offer_tail(i);
	}
	
	public LinkedList<int> already_played() {
		return _already_played;
	}
	
	/************ Current songlist stuff ***************/
	public bool is_shuffled() {
		return _current_shuffled.size > 0;
	}
	
	/* value returned depends on whether shuffle is on or not */
	public int current_index {
		get {
			if(_current_shuffled.size == 0)
				return _current_index;
			else
				return _current_shuffled_index;
		}
		set {
			if(_current_shuffled.size == 0)
				_current_index = value;
			else
				_current_shuffled_index = value;
		}
	}
	
	public Collection<int> current_songs() {
		return _current.values;
	}
	
	public void clearCurrent() {
		current_cleared();
		
		_current.clear();
	}
	
	public void addToCurrent(int i) {
		_current.set(_current.size, i);
	}
	
	public void shuffleMusic(Shuffle mode) {
		if(mode == Shuffle.OFF) {
			unShuffleMusic();
			return;
		}
		
		_current_shuffled.clear();
		_current_shuffled_index = 0;
		settings.setShuffleMode(mode);
		shuffle = mode;
		
		//create temp list of all of current's song id's
		LinkedList<int> temp = new LinkedList<int>();
		foreach(int i in _current.values) {
			temp.add(i);
		}
		
		//loop through all current song id's and pick a random one remaining
		//and set that int i as one of those this is confusing just a sort
		if(mode == Shuffle.ALL) {
			for(int i = 0;i < _current.size; ++i) {
				int random = GLib.Random.int_range(0, temp.size);
				
				_current_shuffled.set(i, temp.get(random));
				temp.remove(temp.get(random));
			}
		}
		else if(mode == Shuffle.ARTIST) {
			
		}
		else if(mode == Shuffle.ALBUM) {
			
		}
	}
	
	public void unShuffleMusic() {
		_current_shuffled.clear();
		_current_shuffled_index = 0;
		settings.setShuffleMode(Shuffle.OFF);
		shuffle = Shuffle.OFF;
		
		//make sure we continue playing where we left off
		for(int i = 0; i < _current.size; ++i) {
			if(_current.get(i) == song_info.song.rowid) {
				_current_index = i;
				return;
			}
		}
	}
	
	public int getNext(bool play) {
		int rv;
		
		// next check if user has queued songs
		if(!queue_empty()) {
			rv = poll_queue();
		}
		else if(_current_shuffled.size > 0) {
			if(song_info.song == null) {
				_current_shuffled_index = 0;
				rv = _current_shuffled.get(0);
			}
			else if(repeat == Repeat.SONG) {
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else if(_current_shuffled_index == (_current_shuffled.size - 1)) {// consider repeat options
				if(repeat == Repeat.ALL)
					_current_shuffled_index = 0;
				else
					return 0;
				
				rv = _current_shuffled.get(0);
			}
			else if(_current_shuffled_index >= 0 && _current_shuffled_index < (_current_shuffled.size - 1)){
				// make sure we are repeating what we need to be
				if(repeat == Repeat.ARTIST && song_from_id(_current_shuffled.get(_current_shuffled_index) + 1).artist != song_info.song.artist) {
					while(song_from_id(_current_shuffled.get(_current_shuffled_index - 1)).artist == song_info.song.artist)
						--_current_shuffled_index;
				}
				else if(repeat == Repeat.ALBUM && song_from_id(_current_shuffled.get(_current_shuffled_index) + 1).album != song_info.song.album) {
					while(song_from_id(_current_shuffled.get(_current_shuffled_index - 1)).album == song_info.song.album)
						--_current_shuffled_index;
				}
				else
					++_current_shuffled_index;
				
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else {
				foreach(Song s in _songs.values)
					addToCurrent(s.rowid);
				
				shuffleMusic(shuffle);
				
				_current_shuffled_index = 0;
				rv = _current_shuffled.get(0);
			}
		}
		else {
			if(song_info.song == null) {
				foreach(Song s in _songs.values)
					addToCurrent(s.rowid);
				
				_current_index = 0;
				rv = _current.get(0);
			}
			else if(_current_index == (_current.size - 1)) {// consider repeat options
				_current_index = 0;
				rv = _current.get(0);
			}
			else if(_current_index >= 0 && _current_index < (_current.size - 1)){
				++_current_index;
				rv = _current.get(_current_index);
			}
			else {
				foreach(Song s in _songs.values)
					addToCurrent(s.rowid);
				
				_current_index = 0;
				rv = _current.get(0);
			}
		}
		
		if(play)
			playSong(rv);
		
		return rv;
	}
	
	public int getPrevious(bool play) {
		int rv;
		
		if(_current_shuffled.size > 0) {
			if(_current_shuffled_index > 0) {
				--_current_shuffled_index;
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else {
				// i should actually pause the music / stop the music instead of playing first song
				foreach(Song s in _songs.values)
					addToCurrent(s.rowid);
				
				shuffleMusic(shuffle);
				
				_current_shuffled_index = _current_shuffled.size - 1;
				rv = _current_shuffled.get(_current_shuffled_index);
			}
		}
		else {
			if(_current_index > 0) {
				--_current_index;
				rv = _current.get(_current_index);
			}
			else {
				// i should actually pause the music / stop the music instead of playing first song
				foreach(Song s in _songs.values)
					addToCurrent(s.rowid);
				
				_current_index = _current.size - 1;
				rv = _current.get(_current_index);
			}
		}
		
		if(play)
			playSong(rv);
		
		return rv;
	}
	
	public void playSong(int id) {
		int old_id = -1;
		
		if(song_info.song != null)
			old_id = song_info.song.rowid;
		
		// actually play the song asap
		player.play_song(song_from_id(id));
			
		// set the current song
		song_info.song = song_from_id(id);
		
		//pause if paused
		if(!playing)
			player.pause_stream();
		
		//update settings
		settings.setLastSongPlaying(song_from_id(id));
		
		song_played(id, old_id);
	}
	
	/************* Last FM Artist Stuff ************/
	public void save_artist(LastFM.ArtistInfo artist) {
		_artists.set(artist.name, artist);
	}
	
	public void save_artists() {
		dbm.save_artists(_artists.values);
	}
	
	public bool artist_info_exists(string artist_key) {
		return _artists.has_key(artist_key);
	}
	
	public LastFM.ArtistInfo? get_artist(string artist_key) {
		if(artist_info_exists(artist_key))	
			return _artists.get(artist_key);
			
		return null;
	}
	
	/************** LastFM Album stuff **************/
	public void save_album(LastFM.AlbumInfo album) {
		_albums.set(album.name + " by " + album.artist, album);
	}
	
	public void save_albums() {
		dbm.save_albums(_albums.values);
	}
	
	public bool album_info_exists(string album_key) {
		return _albums.has_key(album_key);
	}
	
	public LastFM.AlbumInfo? get_album(string album_key) {
		if(album_info_exists(album_key))	
			return _albums.get(album_key);
			
		return null;
	}
	
	/************** Last FM Track Stuff ***************/
	public void save_track(LastFM.TrackInfo track) {
		_tracks.set(track.name + " by " + track.artist, track);
	}
	
	public void save_tracks() {
		dbm.save_tracks(_tracks.values);
	}
	
	public bool track_info_exists(string track_key) {
		return _tracks.has_key(track_key);
	}
	
	public LastFM.TrackInfo? get_track(string track_key) {
		if(track_info_exists(track_key))	
			return _tracks.get(track_key);
			
		return null;
	}
	
	/************ Image stuff ********************/
	public string? get_album_location(int id) {
		return fo.find_album(_songs.get(id));
	}
	
	public Gdk.Pixbuf? save_album_locally(int id, string album) {
		return fo.save_album(_songs.get(id), album);
	}
	
	public string? get_artist_image_location(int id) {
		return fo.find_artist_image(_songs.get(id));
	}
	
	public Gdk.Pixbuf? save_artist_image_locally(int id, string image) {
		return fo.save_artist_image(_songs.get(id), image);
	}
	
}
