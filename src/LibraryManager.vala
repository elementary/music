/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

using Gee;

/** This is where all the media stuff happens. Here, media is retrieved
 * from the db, added to the queue, sorted, and more. LibraryWindow is
 * the visual representation of this class
 */
public class Noise.LibraryManager : Object {
    public signal void progress_notification (string? message, double progress);
    public signal void file_operations_started ();
    public signal void file_operations_done ();
    public signal void progress_cancel_clicked ();

	public signal void music_counted(int count);
	public signal void music_added(LinkedList<string> not_imported);
	public signal void music_imported(LinkedList<Media> new_media, LinkedList<string> not_imported);
	public signal void music_rescanned(LinkedList<Media> new_media, LinkedList<string> not_imported);

    public signal void media_added (Gee.LinkedList<int> ids);
    public signal void media_updated (Gee.LinkedList<int> ids);
    public signal void media_removed (Gee.LinkedList<int> ids);


    public Noise.LibraryWindow lw { get { return App.main_window; } }
    public Noise.DataBaseManager dbm;
    public Noise.DataBaseUpdater dbu;
    public Noise.FileOperator fo;
    public Noise.DeviceManager device_manager;


    private Gee.HashMap<int, Playlist> _playlists; // rowid, playlist of all playlists
    private Gee.HashMap<int, SmartPlaylist> _smart_playlists; // rowid, smart playlist
    private Gee.HashMap<int, Media> _media; // rowid, media of all media

    private Mutex _media_lock; // lock for _media. use this around _media, ...
    private Mutex _playlists_lock; // lock for _playlists
    private Mutex _smart_playlists_lock; // lock for _smart_playlists


    public TreeViewSetup music_setup   { get; private set; default = null; }
    public TreeViewSetup similar_setup { get; private set; default = null; }
    public TreeViewSetup queue_setup   { get; private set; default = null; }
    public TreeViewSetup history_setup { get; private set; default = null; }


    private string temp_add_folder;
    private string[] temp_add_other_folders;
    private int other_folders_added;
    private LinkedList<string> temp_add_files;

    // FIXME use mutex
    bool _doing_file_operations;

    public LibraryManager () {
        this.dbm = new DataBaseManager(this);
        this.dbu = new DataBaseUpdater(this, dbm);
        this.fo = new Noise.FileOperator(this);


        fo.fo_progress.connect(dbProgress);
        dbm.db_progress.connect(dbProgress);

        _smart_playlists = new Gee.HashMap<int, SmartPlaylist>();
        _playlists = new Gee.HashMap<int, Playlist>();
        _media = new Gee.HashMap<int, Media>();

        _doing_file_operations = false;

        //load all media from db
        _media_lock.lock ();
        foreach(Media s in dbm.load_media ()) {
            _media.set (s.rowid, s);
        }
        _media_lock.unlock();

        _smart_playlists_lock.lock();
        foreach(SmartPlaylist p in dbm.load_smart_playlists()) {
            _smart_playlists.set(p.rowid, p);
        }
        _smart_playlists_lock.unlock();

        //load all playlists from db
        _playlists_lock.lock();
        var playlists_added = new Gee.HashMap<string, int> ();
        foreach (Playlist p in dbm.load_playlists()) {
            if(!playlists_added.has_key (p.name)) { // sometimes we get duplicates. don't add duplicates
                _playlists.set(p.rowid, p);
                // TODO: these names should be constants defined in
                // Database Manager
                if(p.name == "autosaved_music") {
                    music_setup = p.tvs;
                    music_setup.set_hint (ViewWrapper.Hint.MUSIC);
                    _playlists.unset (p.rowid);
                }
                else if(p.name == "autosaved_similar") {
                    similar_setup = p.tvs;
                    similar_setup.set_hint(ViewWrapper.Hint.SIMILAR);
                    _playlists.unset(p.rowid);
                }
                else if(p.name == "autosaved_queue") {
                    var to_queue = new LinkedList<Media>();

                    foreach (var m in media_from_playlist (p.rowid)) {
                        to_queue.add (m);
                    }

                    App.player.queue_media (to_queue);

                    queue_setup = p.tvs;
                    queue_setup.set_hint(ViewWrapper.Hint.QUEUE);
                    _playlists.unset(p.rowid);
                }
                else if(p.name == "autosaved_history") {
                    history_setup = p.tvs;
                    history_setup.set_hint (ViewWrapper.Hint.HISTORY);
                    _playlists.unset (p.rowid);
                }

                playlists_added.set (p.name, 1);
            }
        }
        _playlists_lock.unlock();

        if (music_setup == null)
            music_setup = new TreeViewSetup (ListColumn.ARTIST,
                                             Gtk.SortType.ASCENDING,
                                             ViewWrapper.Hint.MUSIC);
        if (similar_setup == null)
            similar_setup = new TreeViewSetup (ListColumn.NUMBER,
                                               Gtk.SortType.ASCENDING,
                                               ViewWrapper.Hint.SIMILAR);

        if (queue_setup == null)
            queue_setup = new TreeViewSetup (ListColumn.NUMBER,
                                             Gtk.SortType.ASCENDING,
                                             ViewWrapper.Hint.QUEUE);

        if (history_setup == null)
            history_setup = new TreeViewSetup (ListColumn.NUMBER,
                                               Gtk.SortType.ASCENDING,
                                               ViewWrapper.Hint.HISTORY);

        // Create device manager
        device_manager = new DeviceManager(this);

        other_folders_added = 0;
        file_operations_done.connect ( ()=> {
            if (temp_add_other_folders != null) {
                other_folders_added++;
                add_folder_to_library (temp_add_other_folders[other_folders_added-1]);
                if (other_folders_added == temp_add_other_folders.length) {
                    other_folders_added = 0;
                    temp_add_other_folders = null;
                }
            }
        });


        CoverartCache.instance.load_for_media_async (media ());
    }

    /************ Library/Collection management stuff ************/
    public virtual void dbProgress(string? message, double progress) {
        progress_notification(message, progress);
    }

    public bool doProgressNotificationWithTimeout() {
        if(_doing_file_operations) {
            Gdk.threads_enter();
            progress_notification(null, (double)((double)fo.index)/((double)fo.item_count));
            Gdk.threads_leave();
        }

        if(fo.index < fo.item_count && _doing_file_operations) {
            return true;
        }

        return false;
    }

    public void set_music_folder (string folder) {
        if (start_file_operations (_("Importing music from %s...").printf ("<b>" + String.escape (folder) + "</b>"))) {

            // FIXME: these are library window's internals. Shouldn't be here
            lw.resetSideTree(true);
            lw.sideTree.removeAllStaticPlaylists();

            clear_media ();

            // FIXME: DOESN'T MAKE SENSE ANYMORE SINCE WE'RE NOT LIMITED TO
            // PLAYING LIBRARY MUSIC. Use unqueue_media ();
            App.player.clear_queue ();

            App.player.reset_already_played ();
            lw.resetSideTree(false);
            lw.update_sensitivities();
            App.player.stopPlayback();

            Settings.Main.instance.music_folder = folder;

            Settings.Main.instance.music_mount_name = "";

            set_music_folder_async ();
        }
    }

    private async void set_music_folder_async () {
        SourceFunc callback = set_music_folder_async.callback;

        Threads.add ( () => {
            var music_folder_file = File.new_for_path(Settings.Main.instance.music_folder);
            LinkedList<string> files = new LinkedList<string>();

            var items = fo.count_music_files(music_folder_file, ref files);
            debug ("found %d items to import\n", items);

            var to_import = remove_duplicate_files (files);

            fo.resetProgress(to_import.size - 1);
            Timeout.add(100, doProgressNotificationWithTimeout);
            fo.import_files(to_import, FileOperator.ImportType.SET);

            Idle.add ((owned) callback);
        });

        yield;
    }

    public void add_files_to_library (LinkedList<string> files) {
        if (start_file_operations (_("Adding files to library..."))) {
            temp_add_files = files;
            add_files_to_library_async ();
        }
    }

    private async void add_files_to_library_async () {
        SourceFunc callback = add_files_to_library_async.callback;

        Threads.add ( () => {
            var to_import = remove_duplicate_files (temp_add_files);

            fo.resetProgress(to_import.size - 1);
            Timeout.add(100, doProgressNotificationWithTimeout);
            fo.import_files(to_import, FileOperator.ImportType.IMPORT);

            Idle.add ((owned) callback);
        });

        yield;
    }

    /**
     * Used to avoid importing already-imported files.
     */
    private Gee.LinkedList<string> remove_duplicate_files (Gee.LinkedList<string> files) {
        var to_import = new Gee.LinkedList<string> ();

        EqualFunc<File> equal_func = FileUtils.equal_func;
        var existing_file_set = new Gee.HashSet<File> (null, equal_func);

        foreach (var m in media ())
            existing_file_set.add (m.file);

        foreach (string uri in files) {
            var to_test = File.new_for_uri (uri);
            if (!existing_file_set.contains (to_test))
                to_import.add (uri);
            else
                debug ("-- DUPLICATE FOUND for: %s", uri);
        }

        return to_import;
    }

    public void add_folder_to_library (string folder, string[]? other_folders = null) {
        if (other_folders != null)
            temp_add_other_folders = other_folders;

        if(start_file_operations (_("Adding music from %s to library...").printf ("<b>" + String.escape (folder) + "</b>"))) {
            temp_add_folder = folder;
            add_folder_to_library_async ();
        }
    }

    private async void add_folder_to_library_async () {
        SourceFunc callback = add_folder_to_library_async.callback;

        Threads.add ( () => {
            var file = File.new_for_path(temp_add_folder);
            var files = new LinkedList<string>();

            fo.count_music_files(file, ref files);

            var to_import = remove_duplicate_files (files);

            fo.resetProgress (to_import.size - 1);
            Timeout.add(100, doProgressNotificationWithTimeout);
            fo.import_files (to_import, FileOperator.ImportType.IMPORT);

            Idle.add ((owned) callback);
        });

        yield;
    }

    public void rescan_music_folder() {
        if(start_file_operations (_("Rescanning music for changes. This may take a while..."))) {
            rescan_music_folder_async ();
        }
    }

    private async void rescan_music_folder_async () {
        SourceFunc callback = rescan_music_folder_async.callback;

        var paths = new Gee.HashMap<string, Media>();
        var to_remove = new Gee.LinkedList<Media>();
        var to_import = new Gee.LinkedList<string>();

        Threads.add ( () => {
            fo.resetProgress(100);
            Timeout.add(100, doProgressNotificationWithTimeout);

            var music_folder_dir = Settings.Main.instance.music_folder;
            foreach(Media s in _media.values) {
                if(!s.isTemporary && !s.isPreview && s.uri.contains(music_folder_dir))
                    paths.set(s.uri, s);

                if(s.uri.contains(music_folder_dir) && !File.new_for_uri(s.uri).query_exists())
                        to_remove.add(s);
            }
            fo.index = 5;

            // get a list of the current files
            var files = new LinkedList<string>();
            fo.count_music_files(File.new_for_path(music_folder_dir), ref files);
            fo.index = 10;

            foreach(string s in files) {
                // XXX: libraries are not necessarily local. This will fail
                // for remote libraries FIXME
                if(paths.get(s) == null)
                    to_import.add (s);
            }

            to_import = remove_duplicate_files (to_import);

            debug ("Importing %d new songs\n", to_import.size);
            if(to_import.size > 0) {
                fo.resetProgress(to_import.size);
                Timeout.add(100, doProgressNotificationWithTimeout);
                fo.import_files(to_import, FileOperator.ImportType.RESCAN);
            }
            else {
                fo.index = 90;
            }

            Idle.add ((owned) callback);
        });

        yield;

        if (!fo.cancelled)
            remove_media(to_remove, false);

        if (to_import.size == 0)
            finish_file_operations();

        // after we're done with that, rescan album arts
        yield CoverartCache.instance.fetch_all_cover_art_async (media ());
    }

    public void play_files (File[] files) {
        /*
        var to_discover = new Gee.LinkedList<string> ();
        var to_play = new Gee.LinkedList<Media> ();

        foreach (var file in files) {
            if (file == null)
                continue;

            var path = file.get_path ();

            // Check if the file is already in the library
            var m = media_from_file (path);

            if (m != null) { // already in library
                debug ("ALREADY IN LIBRARY: %s", path);
                to_play.add (m);
            }
            else { // not in library
                // TODO: see if the file belongs to the music folder and ask the user
                // if they would like to add it to their collection.
                debug ("NOT IN LIBRARY: %s", path);
                to_discover.add (path);
            }
        }

        // Play library media immediately
        App.player.queue_media (to_play);
        App.player.getNext (true);

        Idle.add ( () => {
            fo.import_files (to_discover, FileOperator.ImportType.IMPORT);
            return false;
        });
        */
    }


    public void recheck_files_not_found() {
        Threads.add (recheck_files_not_found_thread);
    }

    public void recheck_files_not_found_thread () {
        message ("IMPLEMENT FILE NOT FOUND CHECK !!");

#if 0
        Media[] cache_media;
        var not_found = new LinkedList<Media>();
        var found = new LinkedList<Media>(); // files that location were unknown but now are found
        var not_found_pix = Icons.PROCESS_ERROR.render(IconSize.MENU, ((ViewWrapper)lw.sideTree.getWidget(lw.sideTree.library_music_iter)).list_view.get_style_context());

        _media_lock.lock();
        cache_media = _media.values.to_array();
        _media_lock.unlock();

        for(int i = 0; i < cache_media.length; ++i) {
            var m = cache_media[i];
            if(m.mediatype == MediaType.STATION ||
            (m.mediatype == MediaType.PODCAST && m.uri.has_prefix("http:/"))) {
                // don't try to find this
            }
            else {
                if(File.new_for_uri(m.uri).query_exists() && m.location_unknown) {
                    m.unique_status_image = null;
                    m.location_unknown = false;
                    found.add(m);
                }
                else if(!File.new_for_uri(m.uri).query_exists() && !m.location_unknown) {
                    m.unique_status_image = not_found_pix;
                    m.location_unknown = true;
                    not_found.add(m);
                }
            }
        }

        Idle.add( () => {
            if(not_found.size > 0) {
                warning("Some media files could not be found and are being marked as such.\n");
                update_medias(not_found, false, false, true);
                foreach(var m in not_found) {
                    lw.media_not_found(m.rowid);
                }
            }
            if(found.size > 0) {
                warning("Some media files whose location were unknown were found.\n");
                update_medias(found, false, false, true);
                foreach(var m in found) {
                    lw.media_found(m.rowid);
                }
            }

            return false;
        });
#endif
    }






    /************************ Playlist stuff ******************/
    public int playlist_count() {
        return _playlists.size;
    }

    public Gee.Collection<Playlist> playlists() {
        return _playlists.values;
    }

    public Gee.HashMap<int, Playlist> playlist_hash() {
        return _playlists;
    }

    public Playlist playlist_from_id(int id) {
        return _playlists.get(id);
    }

    public Playlist? playlist_from_name(string name) {
        Playlist? rv = null;

        _playlists_lock.lock ();
        foreach(var p in playlists ()) {
            if(p.name == name)
                rv = p;
                break;
        }
        _playlists_lock.unlock ();

        return rv;
    }

    public int add_playlist(Playlist p) {
        _playlists_lock.lock ();
        p.rowid = _playlists.size + 1;
        _playlists.set(p.rowid, p);
        _playlists_lock.unlock ();

        dbm.add_playlist(p);

        return p.rowid;
    }

    public void remove_playlist(int id) {
        Playlist removed;

        _playlists_lock.lock ();
        _playlists.unset(id, out removed);
        _playlists_lock.unlock ();

        dbu.removeItem(removed);
    }

    /**************** Smart playlists ****************/
    public int smart_playlist_count() {
        return _smart_playlists.size;
    }

    public Collection<SmartPlaylist> smart_playlists() {
        return _smart_playlists.values;
    }

    public Gee.HashMap<int, SmartPlaylist> smart_playlist_hash() {
        return _smart_playlists;
    }

    public SmartPlaylist smart_playlist_from_id(int id) {
        return _smart_playlists.get(id);
    }

    public SmartPlaylist? smart_playlist_from_name(string name) {
        SmartPlaylist? rv = null;

        _smart_playlists_lock.lock ();
        foreach(var p in smart_playlists ()) {
            if(p.name == name)
                rv = p;
                break;
        }
        _smart_playlists_lock.unlock ();

        return rv;
    }

    public async void save_smart_playlists() {
        SourceFunc callback = save_smart_playlists.callback;

        Threads.add ( () => {
            _smart_playlists_lock.lock ();
            dbm.save_smart_playlists(smart_playlists ());
            _smart_playlists_lock.unlock ();

            Idle.add ((owned) callback);
        });

        yield;
    }

    public int add_smart_playlist(SmartPlaylist p) {
        _smart_playlists_lock.lock ();
        p.rowid = _smart_playlists.size + 1;// + 1 for 1-based db
        _smart_playlists.set(p.rowid, p);
        _smart_playlists_lock.unlock ();

        save_smart_playlists();

        return p.rowid;
    }

    public void remove_smart_playlist(int id) {
        SmartPlaylist removed;
        _smart_playlists_lock.lock ();
        _smart_playlists.unset(id, out removed);
        _smart_playlists_lock.unlock ();

        dbu.removeItem(removed);
    }

    /******************** Media stuff ******************/
    public void clear_media () {
        debug ("Clearing media");

        // We really only want to clear the songs that are permanent and on the file system
        // Dont clear podcasts that link to a url, device media, temporary media, previews, songs
        _media_lock.lock();

        var unset = new LinkedList<Media> ();
        var unset_ids = new LinkedList<int> ();

        foreach (int i in _media.keys) {
            Media s = _media.get (i);

            if(!(s.isTemporary || s.isPreview || s.uri.has_prefix("http://"))) {
                unset.add(s);
                unset_ids.add(s.rowid);
            }
        }

        foreach(Media s in unset) {
            _media.unset(s.rowid);
        }
        _media_lock.unlock ();

        _playlists_lock.lock ();
        foreach (var p in playlists ()) {
            p.remove_media (unset_ids);
        }
        _playlists_lock.unlock ();

        dbm.clear_media ();
        dbm.add_media (_media.values);

        Idle.add ( () => {
            // Analyze sets the matching media as the playlist's media,
            // so we have to pass the entire media list.
            _smart_playlists_lock.lock ();
            foreach (var p in smart_playlists ()) {
                p.analyze (this, media ());
            }
            _smart_playlists_lock.unlock ();

            return false;
        });

        debug ("--- MEDIA CLEARED ---");
    }


    public int media_count() {
        return _media.size;
    }

    public Collection<Media> media() {
        return _media.values;
    }

    public Collection<int> media_ids() {
        return _media.keys;
    }

    public Gee.HashMap<int, Media> media_hash() {
        return _media;
    }

    public void update_media_item (Media s, bool updateMeta, bool record_time) {
        LinkedList<Media> one = new LinkedList<Media>();
        one.add(s);

        update_media(one, updateMeta, record_time);
    }

    public void update_media (Collection<Media> updates, bool updateMeta, bool record_time) {
        LinkedList<int> rv = new LinkedList<int>();

        foreach(Media s in updates) {
            /*_media.set(s.rowid, s);*/
            rv.add(s.rowid);

            if(record_time)
                s.last_modified = (int)time_t();
        }

        debug ("%d media updated from lm.update_media 677\n", rv.size);
        media_updated(rv);

        /* now do background work. even if updateMeta is true, so must user preferences */
        if(updateMeta)
            fo.save_media(updates);

        foreach(Media s in updates)
            dbu.update_media(s);

        Idle.add ( () => {
            // Analyze sets the matching media as the playlist's media,
            // so we have to pass the entire media list.
            _smart_playlists_lock.lock ();
            foreach (var p in smart_playlists ()) {
                p.analyze (this, media ());
            }
            _smart_playlists_lock.unlock ();

            return false;
        });
    }

    public async void save_media() {
        SourceFunc callback = save_media.callback;

        Threads.add ( () => {
            _media_lock.lock ();
            dbm.update_media (_media.values);
            _media_lock.unlock ();

            Idle.add ((owned) callback);
        });

        yield;
    }

    /** Used extensively. All other media data stores a media rowid, and then
     * use this to retrieve the media. This is for memory saving and
     * consistency
     */
    public Media media_from_id(int id) {
        return _media.get(id);
    }

    public Gee.Collection<Media> media_from_ids (Gee.Collection<int> ids) {
        var media_collection = new Gee.LinkedList<Media> ();

        foreach (int id in ids) {
            var m = media_from_id (id);
            if (m != null)
                media_collection.add (m);
        }

        return media_collection;
    }

    public Media? match_media_to_list(Media m, Collection<Media> to_match) {
        Media? rv = null;

        _media_lock.lock();
        foreach(var test in to_match) {
            if(!test.isTemporary && test != m && test.title.down() == m.title.down() && test.artist.down() == m.artist.down()) {
                rv = test;
            }
        }
        _media_lock.unlock();

        return rv;
    }

    public Media media_item_from_name(string title, string artist) {
        Media rv = new Media("");
        rv.title = title;
        rv.artist = artist;
        Media[] searchable;

        _media_lock.lock();
        searchable = _media.values.to_array();
        _media_lock.unlock();

        for(int i = 0; i < searchable.length; ++i) {
            Media s = searchable[i];
            if(s.title.down() == title.down() && s.artist.down() == artist.down())
                return s;
        }

        return rv;
    }

    public void media_from_name(Collection<Media> tests, ref LinkedList<int> found, ref LinkedList<Media> not_found) {
        Media[] searchable;

        _media_lock.lock();
        searchable = _media.values.to_array();
        _media_lock.unlock();

        foreach(Media test in tests) {
            bool found_match = false;
            for(int i = 0; i < searchable.length; ++i) {
                Media s = searchable[i];
                if(test.title.down() == s.title.down() && test.artist.down() == s.artist.down()) {
                    found.add(s.rowid);
                    found_match = true;
                    break;
                }
            }

            if(!found_match)
                not_found.add(test);
        }
    }


    public Media? media_from_file (string uri) {
        var to_test = File.new_for_uri (uri);

        _media_lock.lock ();
        var array = _media.values.to_array ();
        _media_lock.unlock ();

        foreach (var m in array) {
            if (m != null && m.file.equal (to_test))
                return m;
        }

        return null;
    }

    public Gee.Collection<Media> media_from_playlist (int id) {
        return _playlists.get (id).media ();
    }

    public Collection<Media> media_from_smart_playlist (int id) {
        return _smart_playlists.get (id).analyze (this, media ());
    }

    public void add_media_item (Media s) {
        var coll = new LinkedList<Media>();
        coll.add(s);
        add_media (coll);
    }

    public void add_media(Collection<Media> new_media) {
        if(new_media.size < 1) // happens more often than you would think
            return;

        int top_index = 0;

        _media_lock.lock();
        foreach(int i in _media.keys) {
            if(i > top_index)
                top_index = i;
        }

        var added = new LinkedList<int>();
        foreach(var s in new_media) {
            if(s.rowid == 0)
                s.rowid = ++top_index;

            added.add(s.rowid);

            _media.set(s.rowid, s);
        }
        _media_lock.unlock();

        if(new_media.size > 0) {
            dbm.add_media(new_media);
        }

        Idle.add_full (Priority.HIGH_IDLE, () => {
            media_added(added);
            return false;
        });

        Idle.add ( () => {
            // Analyze sets the matching media as the playlist's media,
            // so we have to pass the entire media list.
            _smart_playlists_lock.lock ();
            foreach (var p in smart_playlists ()) {
                p.analyze (this, media ());
            }
            _smart_playlists_lock.unlock ();

            return false;
        });
    }

    public void remove_media (Gee.LinkedList<Media> toRemove, bool trash) {
        var removedIds = new LinkedList<int>();
        var removeURIs = new LinkedList<string>();

        foreach(Media s in toRemove) {
            removedIds.add(s.rowid);
            removeURIs.add(s.uri);

            if(s == App.player.media_info.media)
                App.player.stopPlayback();
        }

        dbu.removeItem(removeURIs);

        if(trash) {
            fo.remove_media(removeURIs);
        }

        /* Emit signal before actually removing the media because otherwise
         * media_from_id() and media_from_ids() wouldn't work.
         */
        media_removed(removedIds);

        _media_lock.lock();
        foreach(Media s in toRemove) {
            _media.unset(s.rowid);
        }
        _media_lock.unlock();

        _playlists_lock.lock();
        foreach(var p in playlists ()) {
            p.remove_media (toRemove);
        }
        _playlists_lock.unlock();

        if(_media.size == 0)
            Settings.Main.instance.music_folder = Environment.get_user_special_dir(UserDirectory.MUSIC);

        // TODO: move away. It's called twice due to LW's internal handlers
        lw.update_sensitivities();

        // Analyze sets the matching media as the playlist's media,
        // so we have to pass the entire media list.
        _smart_playlists_lock.lock ();
        foreach (var p in smart_playlists ()) {
            p.analyze (this, media ());
        }
        _smart_playlists_lock.unlock ();
    }

    public void cancel_operations() {
        progress_cancel_clicked();
    }

    public bool start_file_operations(string? message) {
        if(_doing_file_operations)
            return false;

        progress_notification(message, 0.0);
        _doing_file_operations = true;
        lw.update_sensitivities();
        file_operations_started();
        return true;
    }

    public bool doing_file_operations() {
        return _doing_file_operations;
    }

    public void finish_file_operations() {
        _doing_file_operations = false;
        debug("file operations finished or cancelled\n");

        // FIXME: THESE ARE Library Window's internals!
        lw.update_sensitivities();
        lw.updateInfoLabel();

        file_operations_done();
    }
}

