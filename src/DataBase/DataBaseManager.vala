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
using Gee;

public class Noise.DataBaseManager : GLib.Object {
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
        assert (database == null);

        var database_dir = FileUtils.get_data_directory ();

        try {
            database_dir.make_directory_with_parents (null);
        }
        catch (GLib.Error err) {
            if (!(err is IOError.EXISTS))
                error ("Could not create data directory: %s", err.message);
        }

        string database_path = Path.build_filename (database_dir.get_path (), "database_1_4.db");
        var database_file = File.new_for_path (database_path);

        bool new_db = !database_file.query_exists ();

        try {
            const SQLHeavy.FileMode flags = SQLHeavy.FileMode.READ
                                            | SQLHeavy.FileMode.WRITE
                                            | SQLHeavy.FileMode.CREATE;
            database = new SQLHeavy.Database (database_file.get_path (), flags);
        }
        catch (SQLHeavy.Error err) {
            error ("Could not read/create database file: %s", err.message);
        }

        // Disable synchronized commits for performance reasons
        database.synchronous = SQLHeavy.SynchronousMode.OFF;

		load_table (Database.Tables.PLAYLISTS);
		load_table (Database.Tables.SMART_PLAYLISTS);
		load_table (Database.Tables.MEDIA);
		load_table (Database.Tables.DEVICES);
		load_table (Database.Tables.ARTISTS);
		load_table (Database.Tables.ALBUMS);
		load_table (Database.Tables.TRACKS);

        if (new_db)
            add_default_smart_playlists ();
    }

    private void load_table (string table) {
        try {
            database.execute (table);
        }
        catch (SQLHeavy.Error err) {
            warning ("Error while executing %s: %s", table, err.message);
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
				s.has_embedded = (results.fetch_int(12) == 1);
				s.year = (uint)results.fetch_int(13);
				s.track = (uint)results.fetch_int(14);
				s.track_count = (uint)results.fetch_int(15);
				s.album_number = (uint)results.fetch_int(16);
				s.album_count = (uint)results.fetch_int(17);
				s.bitrate = (uint)results.fetch_int(18);
				s.length = (uint)results.fetch_int(19);
				s.samplerate = (uint)results.fetch_int(20);
				s.rating = (uint)results.fetch_int(21);
				s.play_count = (uint)results.fetch_int(22);
				s.skip_count = (uint)results.fetch_int(23);
				s.date_added = (uint)results.fetch_int(24);
				s.last_played = (uint)results.fetch_int(25);
				s.last_modified = (uint)results.fetch_int(26);
				s.mediatype = (MediaType)results.fetch_int(27);
				s.resume_pos = results.fetch_int(28);

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
'album', 'grouping', 'genre', 'comment', 'lyrics', 'has_embedded', 'year', 'track', 'track_count', 'album_number', 'album_count',
'bitrate', 'length', 'samplerate', 'rating', 'playcount', 'skipcount', 'dateadded', 'lastplayed', 'lastmodified', 'mediatype', 'resume_pos')
VALUES (:rowid, :uri, :file_size, :title, :artist, :composer, :album_artist, :album, :grouping,
:genre, :comment, :lyrics, :has_embedded, :year, :track, :track_count, :album_number, :album_count, :bitrate, :length, :samplerate,
:rating, :playcount, :skipcount, :dateadded, :lastplayed, :lastmodified, :mediatype,
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
 has_embedded=:has_embedded, year=:year, track=:track, track_count=:track_count, album_number=:album_number,
album_count=:album_count,bitrate=:bitrate, length=:length, samplerate=:samplerate, rating=:rating, playcount=:playcount, skipcount=:skipcount,
dateadded=:dateadded, lastplayed=:lastplayed, lastmodified=:lastmodified, mediatype=:mediatype, resume_pos=:resume_pos WHERE rowid=:rowid""");

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
				p.media_from_string(results.fetch_string(2), lm);
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
				query.set_string(":media", p.media_to_string(lm));
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

    		query.set_string(":name", p.name);
			query.set_string(":media", p.media_to_string(lm));
			query.set_int(":sort_column_id", p.tvs.sort_column_id);
			query.set_string(":sort_direction", p.tvs.sort_direction_to_string());
			query.set_string(":columns", p.tvs.columns_to_string());

			query.execute();

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
			TreeViewSetup tvs = new TreeViewSetup(MusicListView.MusicColumn.ARTIST, Gtk.SortType.ASCENDING, ViewWrapper.Hint.SMART_PLAYLIST);
			transaction = database.begin_transaction();
			Query query = transaction.prepare ("INSERT INTO `smart_playlists` (`name`, `and_or`, `queries`, 'limit', 'limit_amount', 'sort_column_id', 'sort_direction', 'columns') VALUES (:name, :and_or, :queries, :limit, :limit_amount, :sort_column_id, :sort_direction, :columns);");

			query.set_string(":name", _("Favorite Songs"));
			query.set_int(":and_or", 0);
			query.set_string(":queries", "11<val_sep>0<val_sep>0<query_sep>13<val_sep>6<val_sep>4<query_sep>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_int(":sort_column_id", MusicListView.MusicColumn.RATING);
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();

			query.set_string(":name", _("Recently Added"));
			query.set_int(":and_or", 1);
			query.set_string(":queries", "5<val_sep>7<val_sep>7<query_sep>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_int(":sort_column_id", MusicListView.MusicColumn.ARTIST);
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();

			/*
			query.set_string(":name", _("Recently Played"));
			query.set_int(":and_or", 1);
			query.set_string(":queries", "9<val_sep>7<val_sep>7<query_sep>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_int(":sort_column_id", MusicListView.MusicColumn.LAST_PLAYED);
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();
			*/

			query.set_string(":name", _("Recent Favorites"));
			query.set_int(":and_or", 0);
			query.set_string(":queries", "11<val_sep>0<val_sep>0<query_sep>9<val_sep>7<val_sep>7<query_sep>13<val_sep>6<val_sep>4<query_sep>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_int(":sort_column_id", MusicListView.MusicColumn.RATING);
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();

			query.set_string(":name", _("Never Played"));
			query.set_int(":and_or", 0);
			query.set_string(":queries", "11<val_sep>0<val_sep>0<query_sep>12<val_sep>4<val_sep>0<query_sep>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_int(":sort_column_id", MusicListView.MusicColumn.ARTIST);
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();

			query.set_string(":name", _("Over Played"));
			query.set_int(":and_or", 0);
			query.set_string(":queries", "11<val_sep>0<val_sep>0<query_sep>12<val_sep>6<val_sep>10<query_sep>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_int(":sort_column_id", MusicListView.MusicColumn.PLAY_COUNT);
			query.set_string(":sort_direction", tvs.sort_direction_to_string());
			query.set_string(":columns", tvs.columns_to_string());
			query.execute();

			query.set_string(":name", _("Not Recently Played"));
			query.set_int(":and_or", 1);
			query.set_string(":queries", "9<val_sep>8<val_sep>7<query_sep>");
			query.set_int(":limit", 0);
			query.set_int(":limit_amount", 50);
			query.set_int(":sort_column_id", MusicListView.MusicColumn.NUMBER);
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
				p.conditional = (SmartPlaylist.ConditionalType)results.fetch_int(2);
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
				query.set_int(":and_or", (int)s.conditional);
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
			query.set_int(":and_or", (int)p.conditional);
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
	public void save_albums(GLib.List<Noise.AlbumInfo> albums) {
		try {
			database.execute("DELETE FROM `albums`");
			transaction = database.begin_transaction();
			Query query = transaction.prepare("INSERT INTO `albums` (`name`, 'artist', `mbid`, 'release_date', 'summary', 'listeners', 'playcount', 'image_uri') VALUES (:name, :artist, :mbid, :release_date, :summary, :listeners, :playcount, :image_uri);");

			foreach(Noise.AlbumInfo a in albums) {
				query.set_string(":name", a.name);
				query.set_string(":artist", a.artist);
				query.set_string(":mbid", a.mbid);
				query.set_string(":release_date", a.get_releasedate_as_string ());
				query.set_string(":summary", a.summary);
				query.set_int(":listeners", a.listeners);
				query.set_int(":playcount", a.playcount);
				query.set_string(":image_uri", a.image_uri);
				query.execute();
			}

			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			warning ("Could not save albums: %s\n", err.message);
		}
	}

	public GLib.List<Noise.AlbumInfo> load_albums() {
		var rv = new GLib.List<Noise.AlbumInfo>();

		try {
			string script = "SELECT rowid,* FROM `albums`";
			Query query = new Query(database, script);

			for (var results = query.execute(); !results.finished; results.next() ) {
				Noise.AlbumInfo a = new Noise.AlbumInfo();

				//int rowid = results.fetch_int(0);
				a.name = results.fetch_string (1);
				a.artist = results.fetch_string (2);
				a.mbid = results.fetch_string (3);
				a.set_releasedate_from_string (results.fetch_string (4));
				a.summary = results.fetch_string (5);
				a.listeners = results.fetch_int (6);
				a.playcount = results.fetch_int (7);
				a.image_uri = results.fetch_string (8);

				rv.append(a);
			}
		}
		catch (SQLHeavy.Error err) {
			warning ("Could not load albums from db: %s\n", err.message);
		}

		return rv;
	}

	public GLib.List<Noise.ArtistInfo> load_artists() {
		var rv = new GLib.List<Noise.ArtistInfo>();

		try {
			string script = "SELECT rowid,* FROM `artists`";
			Query query = new Query(database, script);

			for (var results = query.execute(); !results.finished; results.next() ) {
				Noise.ArtistInfo a = new Noise.ArtistInfo();

				//int rowid = results.fetch_int(0);
				a.name = results.fetch_string(1);
				a.mbid = results.fetch_string(2);
				a.listeners = results.fetch_int(3);
				a.playcount = results.fetch_int(4);
				a.published = results.fetch_string(5);
				a.summary = results.fetch_string(6);
				a.content = results.fetch_string(7);
				a.image_uri = results.fetch_string(8);

				rv.append(a);
			}
		}
		catch (SQLHeavy.Error err) {
			warning ("Could not load artist from db: %s\n", err.message);
		}

		return rv;
	}

	public void save_artists(GLib.List<Noise.ArtistInfo> artists) {
		try {
			database.execute("DELETE FROM `artists`");
			transaction = database.begin_transaction();
			Query query = transaction.prepare("INSERT INTO `artists` (`name`, `mbid`, 'listeners', 'playcount', 'published', 'summary', 'content', 'image_uri') VALUES (:name, :mbid, :listeners, :playcount, :published, :summary, :content, :image_uri);");

			foreach(Noise.ArtistInfo a in artists) {
				query.set_string(":name", a.name);
				query.set_string(":mbid", a.mbid);
				query.set_int(":listeners", a.listeners);
				query.set_int(":playcount", a.playcount);
				query.set_string(":published", a.published);
				query.set_string(":summary", a.summary);
				query.set_string(":content", a.content);
				query.set_string(":image_uri", a.image_uri);
				query.execute();
			}

			transaction.commit();
		}
		catch(SQLHeavy.Error err) {
			warning ("Could not save artists: %s\n", err.message);
		}
	}

	public GLib.List<Noise.TrackInfo> load_tracks() {
		var rv = new GLib.List<Noise.TrackInfo>();

		try {
			string script = "SELECT rowid,* FROM `tracks`";
			Query query = new Query(database, script);

			for (var results = query.execute(); !results.finished; results.next() ) {
				Noise.TrackInfo t = new Noise.TrackInfo();

				//int rowid = results.fetch_int(0);
				t.id = results.fetch_int(1);
				t.name = results.fetch_string(2);
				t.artist = results.fetch_string(3);
				t.album = results.fetch_string(4);
				t.duration = results.fetch_int(5);
				t.listeners = results.fetch_int(6);
				t.playcount = results.fetch_int(7);
				t.summary = results.fetch_string(8);
				t.content = results.fetch_string(9);

				rv.append(t);
			}
		}
		catch (SQLHeavy.Error err) {
			warning ("Could not load tracks from db: %s\n", err.message);
		}

		return rv;
	}

	public void save_tracks(GLib.List<Noise.TrackInfo> tracks) {
		try {
			database.execute("DELETE FROM `tracks`");
			transaction = database.begin_transaction();
			Query query = transaction.prepare("INSERT INTO `tracks` ('id', `name`, `artist`, `album`, 'duration', 'listeners', 'playcount', 'summary', 'content') VALUES (:id, :name, :artist, :album, :duration, :listeners, :playcount, :summary, :content);");

			foreach(Noise.TrackInfo t in tracks) {
				query.set_int(":id", t.id);
				query.set_string(":name", t.name);
				query.set_string(":artist", t.artist);
				query.set_string(":album", t.album);
				query.set_int(":duration", t.duration);
				query.set_int(":listeners", t.listeners);
				query.set_int(":playcount", t.playcount);
				query.set_string(":summary", t.summary);
				query.set_string(":content", t.content);

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
