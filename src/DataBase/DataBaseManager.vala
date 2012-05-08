/*
 * Copyright (c) 2012 Noise Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; see the file COPYING.  If not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>,
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

using SQLHeavy;
using TagLib;
using Gee;

public class BeatBox.DataBaseManager : GLib.Object {
	public signal void db_progress (string? message, double progress);

	private LibraryManager lm;
	private SQLHeavy.Database database;
	private Transaction transaction; // the current sql transaction

	private int index = 0;
	private int item_count = 0;

	/** Creates a new DatabaseManager **/
	public DataBaseManager (LibraryManager lm) {
		this.lm = lm;
		init_database ();
	}

	/** Creates/Reads the database file and folder **/
	private void init_database () {
		var data_dir = GLib.File.new_for_path (GLib.Path.build_filename (Environment.get_user_data_dir (), lm.lw.app.get_name ()));
		if (!data_dir.query_exists ()) {
			try {
				data_dir.make_directory_with_parents (null);
			}
			catch (GLib.Error err) {
				warning ("CRITICAL: Could not create folder in data directory: %s\n", err.message);
			}
		}

		var db_file = GLib.File.new_for_path (GLib.Path.build_filename (data_dir.get_path (), "database_1_0.db"));

		/* we need to set this variable now since 'new SQLHeavy.Database' will create the file later */
		bool need_create = !db_file.query_exists ();

		try {
			database = new SQLHeavy.Database (db_file.get_path (), SQLHeavy.FileMode.READ | SQLHeavy.FileMode.WRITE | SQLHeavy.FileMode.CREATE);
		}
		catch (SQLHeavy.Error err) {
			warning ("This is terrible. Could not even load database. Please report this. Message: %s", err.message);
		}

		/* disable synchronized commits for performance reasons ... this is not vital */
		database.synchronous = SQLHeavy.SynchronousMode.from_string ("OFF");

		/* Create new database if it doesn't exist */
		if (need_create) {
			try {
				database.execute("CREATE TABLE playlists (`name` TEXT, `media` TEXT, 'sort_column_id' INT, 'sort_direction' TEXT, 'columns' TEXT)");
				database.execute("CREATE TABLE smart_playlists (`name` TEXT, `and_or` TEXT, `queries` TEXT, 'limit' INT, 'limit_amount' INT, 'sort_column_id' INT, 'sort_direction' TEXT, 'columns' TEXT)");

				database.execute("""CREATE TABLE media (`uri` TEXT, 'file_size' INT, `title` TEXT,`artist` TEXT, 'composer' TEXT, 'album_artist' TEXT,
				`album` TEXT, 'grouping' TEXT, `genre` TEXT,`comment` TEXT, 'lyrics' TEXT, 'album_path' TEXT, 'has_embedded' INT,
				`year` INT, `track` INT, 'track_count' INT, 'album_number' INT, 'album_count' INT, `bitrate` INT, `length` INT, `samplerate` INT,
				`rating` INT, `playcount` INT, 'skipcount' INT, `dateadded` INT, `lastplayed` INT, 'lastmodified' INT, 'mediatype' INT,
				'podcast_rss' TEXT, 'podcast_url' TEXT, 'podcast_date' INT, 'is_new_podcast' INT, 'resume_pos' INT)""");

				database.execute("CREATE TABLE devices ('unique_id' TEXT, 'sync_when_mounted' INT,'sync_music' INT, 'sync_podcasts' INT, 'sync_audiobooks' INT, 'sync_all_music' INT, 'sync_all_podcasts' INT, 'sync_all_audiobooks' INT, 'music_playlist' STRING, 'podcast_playlist' STRING, 'audiobook_playlist' STRING, 'last_sync_time' INT)");

				database.execute("CREATE TABLE artists ('name' TEXT, 'mbid' TEXT, 'url' TEXT, 'streamable' INT, 'listeners' INT, 'playcount' INT, 'published' TEXT, 'summary' TEXT, 'content' TEXT, 'tags' TEXT, 'similar' TEXT, 'url_image' TEXT)");
				database.execute("CREATE TABLE albums ('name' TEXT, 'artist' TEXT, 'mbid' TEXT, 'url' TEXT, 'release_date' TEXT, 'listeners' INT, 'playcount' INT, 'tags' TEXT,  'url_image' TEXT)");
				database.execute("CREATE TABLE tracks ('id' INT, 'name' TEXT, 'artist' TEXT, 'url' TEXT, 'duration' INT, 'streamable' INT, 'listeners' INT, 'playcount' INT, 'summary' TEXT, 'content' TEXT, 'tags' TEXT)");

				add_default_smart_playlists ();
			}
			catch (SQLHeavy.Error err) {
				warning ("Bad news: could not create tables. Please report this. Message: %s\n", err.message);
			}
		}
	}

	public void resetProgress (int items) {
		index = 0;
		item_count = items;
	}

	/**
	 * Loads media from db
	 */
	public ArrayList<Media> load_media () {
		var rv = new ArrayList<Media>();

		try {
			Query query = new Query (database, "SELECT rowid,* FROM `media`");

			for (var results = query.execute (); !results.finished; results.next()) {
				var s = new Media (results.fetch_string (1));
				s.rowid = results.fetch_int (0);
				s.file_size = (uint)results.fetch_int(2);
				s.title = results.fetch_string(3);
				s.artist = results.fetch_string(4);
				s.composer = results.fetch_string(5);
				s.album_artist = results.fetch_string(6);
				s.album = results.fetch_string(7);
				s.grouping = results.fetch_string(8);
				s.genre = results.fetch_string(9);
				s.comment = results.fetch_string(10);
				s.lyrics = results.fetch_string(11);
				s.setAlbumArtPath(results.fetch_string(12));
				s.has_embedded = (results.fetch_int(13) == 1);
				s.year = (uint)results.fetch_int(14);
				s.track = (uint)results.fetch_int(15);
				s.track_count = (uint)results.fetch_int(16);
				s.album_number = (uint)results.fetch_int(17);
				s.album_count = (uint)results.fetch_int(18);
				s.bitrate = (uint)results.fetch_int(19);
				s.length = (uint)results.fetch_int(20);
				s.samplerate = (uint)results.fetch_int(21);
				s.rating = (uint)results.fetch_int(22);
				s.play_count = (uint)results.fetch_int(23);
				s.skip_count = (uint)results.fetch_int(24);
				s.date_added = (uint)results.fetch_int(25);
				s.last_played = (uint)results.fetch_int(26);
				s.last_modified = (uint)results.fetch_int(27);
				s.mediatype = (int)results.fetch_int(28);
				s.podcast_rss = results.fetch_string(29);
				s.podcast_url = results.fetch_string(30);
				s.podcast_date = results.fetch_int(31);
				s.is_new_podcast = (results.fetch_int(32) == 1) ? true : false;
				s.resume_pos = results.fetch_int(33);

				rv.add(s);
			}
		}
		catch (SQLHeavy.Error err) {
			warning ("Could not load media from db: %s\n", err.message);
		}

		return rv;
	}

	public void clear_media () {
		try {
			database.execute ("DELETE FROM `media`");
		}
		catch(SQLHeavy.Error err) {
			warning ("Could not clear media: %s \n", err.message);
		}
	}

	public void add_media (Collection<Media> media) {
		try {
			transaction = database.begin_transaction();
			Query query = transaction.prepare ("""INSERT INTO 'media' ('rowid', 'uri', 'file_size', 'title', 'artist', 'composer', 'album_artist',
'album', 'grouping', 'genre', 'comment', 'lyrics', 'album_path', 'has_embedded', 'year', 'track', 'track_count', 'album_number', 'album_count',
'bitrate', 'length', 'samplerate', 'rating', 'playcount', 'skipcount', 'dateadded', 'lastplayed', 'lastmodified', 'mediatype', 'podcast_rss',
'podcast_url', 'podcast_date', 'is_new_podcast', 'resume_pos')
VALUES (:rowid, :uri, :file_size, :title, :artist, :composer, :album_artist, :album, :grouping,
:genre, :comment, :lyrics, :album_path, :has_embedded, :year, :track, :track_count, :album_number, :album_count, :bitrate, :length, :samplerate,
:rating, :playcount, :skipcount, :dateadded, :lastplayed, :lastmodified, :mediatype, :podcast_rss, :podcast_url, :podcast_date, :is_new_podcast,
:resume_pos);""");

			foreach (var s in media) {
				if (s.rowid > 0 && !s.isTemporary) {
					query.set_int(":rowid", (int)s.rowid);
					query.set_string(":uri", s.uri);
					query.set_int(":file_size", (int)s.file_size);
					query.set_string(":title", s.title);
					query.set_string(":artist", s.artist);
					query.set_string(":composer", s.composer);
					query.set_string(":album_artist", s.album_artist);
					query.set_string(":album", s.album);
					query.set_string(":grouping", s.grouping);
					query.set_string(":genre", s.genre);
					query.set_string(":comment", s.comment);
					query.set_string(":lyrics", s.lyrics);
					query.set_string(":album_path", s.getAlbumArtPath());
					query.set_int(":has_embedded", s.has_embedded ? 1 : 0);
					query.set_int(":year", (int)s.year);
					query.set_int(":track", (int)s.track);
					query.set_int(":track_count", (int)s.track_count);
					query.set_int(":album_number", (int)s.album_number);
					query.set_int(":album_count", (int)s.album_count);
					query.set_int(":bitrate", (int)s.bitrate);
					query.set_int(":length", (int)s.length);
					query.set_int(":samplerate", (int)s.samplerate);
					query.set_int(":rating", (int)s.rating);
					query.set_int(":playcount", (int)s.play_count);
					query.set_int(":skipcount", (int)s.skip_count);
					query.set_int(":dateadded", (int)s.date_added);
					query.set_int(":lastplayed", (int)s.last_played);
					query.set_int(":lastmodified", (int)s.last_modified);
					query.set_int(":mediatype", s.mediatype);
					query.set_string(":podcast_rss", s.podcast_rss);
					query.set_string(":podcast_url", s.podcast_url);
					query.set_int(":podcast_date", s.podcast_date);
					query.set_int(":is_new_podcast", s.is_new_podcast ? 1 : 0);
					query.set_int(":resume_pos", s.resume_pos);

					query.execute();
				}
			}

			transaction.commit();
		}
		catch (SQLHeavy.Error err) {
			warning ("Could not save media: %s \n", err.message);
		}
	}

	public void remove_media (Collection<string> media) {
		try {
			transaction = database.begin_transaction();
			Query query = transaction.prepare ("DELETE FROM `media` WHERE uri=:uri");

			foreach (var m in media) {
				query.set_string (":uri", m);
				query.execute ();
			}

			transaction.commit ();
		}
		catch (SQLHeavy.Error err) {
			warning ("Could not remove media from db: %s\n", err.message);
		}
	}

	public void update_media (Gee.Collection<Media> media) {
		try {
			transaction = database.begin_transaction();
			Query query = transaction.prepare("""UPDATE `media` SET uri=:uri, file_size=:file_size, title=:title, artist=:artist,
composer=:composer, album_artist=:album_artist, album=:album, grouping=:grouping, genre=:genre, comment=:comment, lyrics=:lyrics,
album_path=:album_path, has_embedded=:has_embedded, year=:year, track=:track, track_count=:track_count, album_number=:album_number,
album_count=:album_count,bitrate=:bitrate, length=:length, samplerate=:samplerate, rating=:rating, playcount=:playcount, skipcount=:skipcount,
dateadded=:dateadded, lastplayed=:lastplayed, lastmodified=:lastmodified, mediatype=:mediatype, podcast_rss=:podcast_rss, podcast_url=:podcast_url,
podcast_date=:podcast_date, is_new_podcast=:is_new_podcast, resume_pos=:resume_pos WHERE rowid=:rowid""");

			foreach(Media s in media) {
				if(s.rowid != -2 && s.rowid > 0) {
					query.set_int(":rowid", (int)s.rowid);
					query.set_string(":uri", s.uri);
					query.set_int(":file_size", (int)s.file_size);
					query.set_string(":title", s.title);
					query.set_string(":artist", s.artist);
					query.set_string(":composer", s.composer);
					query.set_string(":album_artist", s.album_artist);
					query.set_string(":album", s.album);
					query.set_string(":grouping", s.grouping);
					query.set_string(":genre", s.genre);
					query.set_string(":comment", s.comment);
					query.set_string(":lyrics", s.lyrics);
					query.set_string(":album_path", s.getAlbumArtPath());
					query.set_int(":has_embedded", s.has_embedded ? 1 : 0);
					query.set_int(":year", (int)s.year);
					query.set_int(":track", (int)s.track);
					query.set_int(":track_count", (int)s.track_count);
					query.set_int(":album_number", (int)s.album_number);
					query.set_int(":album_count", (int)s.album_count);
					query.set_int(":bitrate", (int)s.bitrate);
					query.set_int(":length", (int)s.length);
					query.set_int(":samplerate", (int)s.samplerate);
					query.set_int(":rating", (int)s.rating);
					query.set_int(":playcount", (int)s.play_count);
					query.set_int(":skipcount", (int)s.skip_count);
					query.set_int(":dateadded", (int)s.date_added);
					query.set_int(":lastplayed", (int)s.last_played);
					query.set_int(":lastmodified", (int)s.last_modified);
					query.set_int(":mediatype", s.mediatype);
					query.set_string(":podcast_rss", s.podcast_rss);
					query.set_string(":podcast_url", s.podcast_url);
					query.set_int(":podcast_date", s.podcast_date);
					query.set_int(":is_new_podcast", s.is_new_podcast ? 1 : 0);
					query.set_int(":resume_pos", s.resume_pos);

					query.execute();
				}
			}

			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			warning ("Could not update media: %s \n", err.message);
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
			Query query = new Query(database, script);

			for (var results = query.execute(); !results.finished; results.next() ) {
				Playlist p = new Playlist.with_info(results.fetch_int(0), results.fetch_string(1));
				p.medias_from_string(results.fetch_string(2), lm);
				p.tvs.sort_column_id = results.fetch_int(3);
				p.tvs.set_sort_direction_from_string(results.fetch_string(4));

				p.tvs.import_columns(results.fetch_string(5));

				rv.add(p);
			}
		}
		catch (SQLHeavy.Error err) {
			warning ("Could not load playlists from db: %s\n", err.message);
		}

		return rv;
	}

	public void save_playlists(Collection<Playlist> playlists) {
		try {
			database.execute("DELETE FROM `playlists`");
			transaction = database.begin_transaction();
			Query query = transaction.prepare ("INSERT INTO `playlists` (`name`, `media`, 'sort_column_id', 'sort_direction', 'columns') VALUES (:name, :media, :sort_column_id, :sort_direction, :columns);");

			foreach(Playlist p in playlists) {
				query.set_string(":name", p.name);
				query.set_string(":media", p.medias_to_string(lm));
				query.set_int(":sort_column_id", p.tvs.sort_column_id);
				query.set_string(":sort_direction", p.tvs.sort_direction_to_string());
				query.set_string(":columns", p.tvs.columns_to_string());

				query.execute();
			}

			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			warning ("Could not save playlists: %s \n", err.message);
		}
	}

	public void add_playlist(Playlist p) {
		try {
			transaction = database.begin_transaction();
			Query query = transaction.prepare ("""INSERT INTO `playlists` (`name`, `media`, 'sort_column_id', 'sort_direction', 'columns')
												VALUES (:name, :media, :sort_column_id, :sort_direction, :columns);""");

			//foreach(Playlist p in playlists) {
				query.set_string(":name", p.name);
				query.set_string(":media", p.medias_to_string(lm));
				query.set_int(":sort_column_id", p.tvs.sort_column_id);
				query.set_string(":sort_direction", p.tvs.sort_direction_to_string());
				query.set_string(":columns", p.tvs.columns_to_string());

				query.execute();
			//}

			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			warning ("Could not add playlists: %s \n", err.message);
		}
	}

	/*public void update_playlists(LinkedList<Playlist> playlists) {
		try {
			transaction = database.begin_transaction();
			Query query = transaction.prepare("UPDATE `playlists` SET name=:name, media=:media, sort_column_id=:sort_column_id, sort_direction=:sort_direction, columns=:columns  WHERE name=:name");

			foreach(Playlist p in playlists) {
				query.set_string(":name", p.name);
				query.set_string(":media", p.media_to_string(lm));
				query.set_int(":sort_column_id", p.tvs.sort_column_id);
				query.set_string(":sort_direction", p.tvs.sort_direction_to_string());
				query.set_string(":columns", p.tvs.columns_to_string());

				query.execute();
			}

			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			warning ("Could not update playlist: %s \n", err.message);
		}
	}*/

	public void remove_playlist(Playlist p) {
		try {
			transaction = database.begin_transaction();
			Query query = transaction.prepare("DELETE FROM `playlists` WHERE rowid=:rowid");

			query.set_int(":rowid", p.rowid);
			query.execute();

			transaction.commit();
		}
		catch (SQLHeavy.Error err) {
			warning ("Could not remove playlist from db: %s\n", err.message);
		}
	}

	/** SMART PLAYLISTS **/

	public void add_default_smart_playlists () {
		try {
			TreeViewSetup tvs = new TreeViewSetup(MusicTreeView.MusicColumn.ARTIST, Gtk.SortType.ASCENDING, ViewWrapper.Hint.SMART_PLAYLIST);
			transaction = database.begin_transaction();
			Query query = transaction.prepare ("INSERT INTO `smart_playlists` (`name`, `and_or`, `queries`, 'limit', 'limit_amount', 'sort_column_id', 'sort_direction', 'columns') VALUES (:name, :and_or, :queries, :limit, :limit_amount, :sort_column_id, :sort_direction, :columns);");

			query.set_string(":name", _("Favorite Songs"));
			query.set_string(":and_or", "all");
			query.set_string(":queries", "Media Type<value_separator>is<value_separator>0<query_seperator>Rating<value_separator>is at least<value_separator>4<query_seperator>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_int(":sort_column_id", MusicTreeView.MusicColumn.RATING);
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();

#if HAVE_INTERNET_RADIO
			query.set_string(":name", "Favorite Stations");
			query.set_string(":and_or", "all");
			query.set_string(":queries", "Media Type<value_separator>is<value_separator>3<query_seperator>Rating<value_separator>is at least<value_separator>4<query_seperator>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_int(":sort_column_id", MusicTreeView.MusicColumn.RATING);
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();
#endif
			query.set_string(":name", _("Recently Added"));
			query.set_string(":and_or", "any");
			query.set_string(":queries", "Date Added<value_separator>is within<value_separator>7<query_seperator>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_int(":sort_column_id", MusicTreeView.MusicColumn.ARTIST);
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();

			query.set_string(":name", _("Recently Played"));
			query.set_string(":and_or", "any");
			query.set_string(":queries", "Last Played<value_separator>is within<value_separator>7<query_seperator>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_int(":sort_column_id", MusicTreeView.MusicColumn.LAST_PLAYED);
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();

			query.set_string(":name", _("Recent Favorites"));
			query.set_string(":and_or", "all");
			query.set_string(":queries", "Media Type<value_separator>is<value_separator>0<query_seperator>Last Played<value_separator>is within<value_separator>7<query_seperator>Rating<value_separator>is at least<value_separator>4<query_seperator>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_int(":sort_column_id", MusicTreeView.MusicColumn.RATING);
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();

			query.set_string(":name", _("Never Played"));
			query.set_string(":and_or", "all");
			query.set_string(":queries", "Media Type<value_separator>is<value_separator>0<query_seperator>Playcount<value_separator>is exactly<value_separator>0<query_seperator>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_int(":sort_column_id", MusicTreeView.MusicColumn.ARTIST);
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();
#if HAVE_PODCASTS
			query.set_string(":name", _("Unheard Podcasts"));
			query.set_string(":and_or", "all");
			query.set_string(":queries", "Media Type<value_separator>is<value_separator>1<query_seperator>Playcount<value_separator>is exactly<value_separator>0<query_seperator>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_int(":sort_column_id", MusicTreeView.MusicColumn.ARTIST);
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();
#endif
			query.set_string(":name", _("Over Played"));
			query.set_string(":and_or", "all");
			query.set_string(":queries", "Media Type<value_separator>is<value_separator>0<query_seperator>Playcount<value_separator>is at least<value_separator>10<query_seperator>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_int(":sort_column_id", MusicTreeView.MusicColumn.PLAY_COUNT);
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();

			query.set_string(":name", _("Not Recently Played"));
			query.set_string(":and_or", "any");
			query.set_string(":queries", "Last Played<value_separator>is before<value_separator>7<query_seperator>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_int(":sort_column_id", MusicTreeView.MusicColumn.NUMBER);
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();

			transaction.commit();
		}
		catch (SQLHeavy.Error err) {
			warning ("Could not initialize smart playlists: %s\n", err.message);
		}
	}
	public Gee.ArrayList<SmartPlaylist> load_smart_playlists() {
		var rv = new ArrayList<SmartPlaylist>();

		try {
			string script = "SELECT rowid,* FROM `smart_playlists`";
			Query query = new Query(database, script);

			for (var results = query.execute(); !results.finished; results.next() ) {
				SmartPlaylist p = new SmartPlaylist();

				p.rowid = results.fetch_int(0);
				p.name = results.fetch_string(1);
				p.conditional = results.fetch_string(2);
				p.queries_from_string(results.fetch_string(3));
				p.limit = ( results.fetch_string(4) == "1") ? true : false;
				p.limit_amount = results.fetch_int(5);
				p.tvs.sort_column_id = results.fetch_int(6);
				p.tvs.set_sort_direction_from_string(results.fetch_string(7));
				p.tvs.import_columns(results.fetch_string(8));

				rv.add(p);
			}
		}
		catch (SQLHeavy.Error err) {
			warning ("Could not load smart playlists from db: %s\n", err.message);
		}

		return rv;
	}

	public void save_smart_playlists(Collection<SmartPlaylist> smarts) {
		try {
			database.execute("DELETE FROM `smart_playlists`");
			transaction = database.begin_transaction();
			Query query = transaction.prepare ("INSERT INTO `smart_playlists` (`name`, `and_or`, `queries`, 'limit', 'limit_amount', 'sort_column_id', 'sort_direction', 'columns') VALUES (:name, :and_or, :queries, :limit, :limit_amount, :sort_column_id, :sort_direction, :columns);");

			foreach(SmartPlaylist s in smarts) {
				query.set_string(":name", s.name);
				query.set_string(":and_or", s.conditional);
				query.set_string(":queries", s.queries_to_string());
				query.set_int(":limit", ( s.limit ) ? 1 : 0);
				query.set_int(":limit_amount", s.limit_amount);
				query.set_int(":sort_column_id", s.tvs.sort_column_id);
				query.set_string(":sort_direction", s.tvs.sort_direction_to_string());
				query.set_string(":columns", s.tvs.columns_to_string());

				query.execute();
			}

			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			warning ("Could not save smart playlists: %s \n", err.message);
		}
	}

	public void update_smart_playlist(SmartPlaylist p) {
		try {
			transaction = database.begin_transaction();
			Query query = transaction.prepare("UPDATE `smart_playlists` SET name=:name, and_or=:and_or, queries=:queries, limit=:limit, limit_amount=:limit_amount, sort_column_id=:sort_column_id, sort_direction=:sort_direction, columns=:columns WHERE name=:name");

			query.set_string(":name", p.name);
			query.set_string(":and_or", p.conditional);
			query.set_string(":queries", p.queries_to_string());
			query.set_int(":limit", ( p.limit ) ? 1 : 0);
			query.set_int(":limit_amount", p.limit_amount);
			query.set_int(":sort_column_id", p.tvs.sort_column_id);
			query.set_string(":sort_direction", p.tvs.sort_direction_to_string());
			query.set_string(":columns", p.tvs.columns_to_string());

			query.execute();
			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			warning ("Could not update smart playlist: %s \n", err.message);
		}
	}

	public void remove_smart_playlist(SmartPlaylist p) {
		try {
			transaction = database.begin_transaction();
			Query query = transaction.prepare("DELETE FROM `smart_playlists` WHERE rowid=:rowid");

			query.set_int(":rowid", p.rowid);
			query.execute();

			transaction.commit();
		}
		catch (SQLHeavy.Error err) {
			warning ("Could not remove smart playlist from db: %s\n", err.message);
		}
	}

	/** Last FM objects **/
	public void save_albums(GLib.List<LastFM.AlbumInfo> albums) {
		try {
			database.execute("DELETE FROM `albums`");
			transaction = database.begin_transaction();
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
					tags += tag.tag + "<value_separator>" + tag.url + "<tag_seperator>";
				}

				query.set_string(":tags", tags);
				query.set_string(":url_image", a.url_image.to_string());
				query.execute();
			}

			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			warning ("Could not save albums: %s\n", err.message);
		}
	}

	public GLib.List<LastFM.AlbumInfo> load_albums() {
		var rv = new GLib.List<LastFM.AlbumInfo>();

		try {
			string script = "SELECT rowid,* FROM `albums`";
			Query query = new Query(database, script);

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
					string[] tag_values = tag_strings[index].split("<value_separator>", 0);

					LastFM.Tag t = new LastFM.Tag.with_string_and_url(tag_values[0], tag_values[1]);
					a.addTag(t);
				}

				string url_image = results.fetch_string(9);
				//string local_image = results.fetch_string(10);

				if(url_image != null && url_image != "")
					a.url_image = new LastFM.Image.with_import_string(url_image);
				else
					a.url_image = new LastFM.Image.basic();

				rv.append(a);
			}
		}
		catch (SQLHeavy.Error err) {
			warning ("Could not load albums from db: %s\n", err.message);
		}

		return rv;
	}

	public GLib.List<LastFM.ArtistInfo> load_artists() {
		var rv = new GLib.List<LastFM.ArtistInfo>();

		try {
			string script = "SELECT rowid,* FROM `artists`";
			Query query = new Query(database, script);

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
					string[] tag_values = tag_strings[index].split("<value_separator>", 0);

					LastFM.Tag t = new LastFM.Tag.with_string_and_url(tag_values[0], tag_values[1]);
					a.addTag(t);
				}

				string sim_string = results.fetch_string(11);
				string[] sim_strings = sim_string.split("<similar_seperator>", 0);

				for(index = 0; index < sim_strings.length - 1; ++index) {
					string[] sim_values = sim_strings[index].split("<value_separator>", 0);

					LastFM.ArtistInfo sim = new LastFM.ArtistInfo.with_artist_and_url(sim_values[0], sim_values[1]);
					a.addSimilarArtist(sim);
				}

				string url_image = results.fetch_string(12);

				if(url_image != null && url_image != "")
					a.url_image = new LastFM.Image.with_import_string(url_image);
				else
					a.url_image = new LastFM.Image.basic();

				rv.append(a);
			}
		}
		catch (SQLHeavy.Error err) {
			warning ("Could not load artist from db: %s\n", err.message);
		}

		return rv;
	}

	public void save_artists(GLib.List<LastFM.ArtistInfo> artists) {
		try {
			database.execute("DELETE FROM `artists`");
			transaction = database.begin_transaction();
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
					tags += tag.tag + "<value_separator>" + tag.url + "<tag_seperator>";
				}

				string similar = "";
				foreach(LastFM.ArtistInfo sim in a.similarArtists()) {
					similar += sim.name + "<value_separator>" + sim.url + "<similar_seperator>";
				}

				query.set_string(":tags", tags);
				query.set_string(":similar", similar);
				query.set_string(":url_image", a.url_image.to_string());
				query.execute();
			}

			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			warning ("Could not save artists: %s\n", err.message);
		}
	}

	public GLib.List<LastFM.TrackInfo> load_tracks() {
		var rv = new GLib.List<LastFM.TrackInfo>();

		try {
			string script = "SELECT rowid,* FROM `tracks`";
			Query query = new Query(database, script);

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
					string[] tag_values = tag_strings[index].split("<value_separator>", 0);

					LastFM.Tag tag = new LastFM.Tag.with_string_and_url(tag_values[0], tag_values[1]);
					t.addTag(tag);
				}

				rv.append(t);
			}
		}
		catch (SQLHeavy.Error err) {
			warning ("Could not load tracks from db: %s\n", err.message);
		}

		return rv;
	}

	public void save_tracks(GLib.List<LastFM.TrackInfo> tracks) {
		try {
			database.execute("DELETE FROM `tracks`");
			transaction = database.begin_transaction();
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
					tags += tag.tag + "<value_separator>" + tag.url + "<tag_seperator>";
				}

				query.set_string(":tags", tags);
				query.execute();
			}

			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			warning ("Could not save tracks: %s\n", err.message);
		}
	}

	public GLib.List<DevicePreferences> load_devices() {
		var rv = new GLib.List<DevicePreferences>();

		try {
			string script = "SELECT rowid,* FROM `devices`";
			Query query = new Query(database, script);

			for (var results = query.execute(); !results.finished; results.next() ) {
				DevicePreferences dp = new DevicePreferences(results.fetch_string(1));

				dp.sync_when_mounted = results.fetch_int(2) == 1;
				dp.sync_music = results.fetch_int(3) == 1;
				dp.sync_podcasts = results.fetch_int(4) == 1;
				dp.sync_audiobooks = results.fetch_int(5) == 1;
				dp.sync_all_music = results.fetch_int(6) == 1;
				dp.sync_all_podcasts = results.fetch_int(7) == 1;
				dp.sync_all_audiobooks = results.fetch_int(8) == 1;
				dp.music_playlist = results.fetch_string(9);
				dp.podcast_playlist = results.fetch_string(10);
				dp.audiobook_playlist = results.fetch_string(11);
				dp.last_sync_time = results.fetch_int(12);

				rv.append(dp);
			}
		}
		catch (SQLHeavy.Error err) {
			warning ("Could not load devices from db: %s\n", err.message);
		}

		return rv;
	}

	public void save_devices(GLib.List<DevicePreferences> devices) {
		try {
			database.execute("DELETE FROM `devices`");
			transaction = database.begin_transaction();
			Query query = transaction.prepare("""INSERT INTO `devices` ('unique_id', 'sync_when_mounted', 'sync_music',
			'sync_podcasts', 'sync_audiobooks', 'sync_all_music', 'sync_all_podcasts', 'sync_all_audiobooks', 'music_playlist',
			'podcast_playlist', 'audiobook_playlist', 'last_sync_time') VALUES (:unique_id, :sync_when_mounted, :sync_music, :sync_podcasts, :sync_audiobooks,
			:sync_all_music, :sync_all_podcasts, :sync_all_audiobooks, :music_playlist, :podcast_playlist, :audiobook_playlist, :last_sync_time);""");

			foreach(DevicePreferences dp in devices) {
				query.set_string(":unique_id", dp.id);
				query.set_int(":sync_when_mounted", dp.sync_when_mounted ? 1 : 0);

				query.set_int(":sync_music", dp.sync_music ? 1 : 0);
				query.set_int(":sync_podcasts", dp.sync_podcasts ? 1 : 0);
				query.set_int(":sync_audiobooks", dp.sync_audiobooks ? 1 : 0);

				query.set_int(":sync_all_music", dp.sync_all_music ? 1 : 0);
				query.set_int(":sync_all_podcasts", dp.sync_all_podcasts ? 1 : 0);
				query.set_int(":sync_all_audiobooks", dp.sync_all_audiobooks ? 1 : 0);

				query.set_string(":music_playlist", dp.music_playlist);
				query.set_string(":podcast_playlist", dp.podcast_playlist);
				query.set_string(":audiobook_playlist", dp.audiobook_playlist);
				query.set_int(":last_sync_time", dp.last_sync_time);

				query.execute();
			}

			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			warning ("Could not save devices: %s\n", err.message);
		}
	}
}
