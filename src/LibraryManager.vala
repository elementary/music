// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>,
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

using Gee;

/**
 * This is where all the media stuff happens. Here, media is retrieved
 * from the db, added to the queue, sorted, and more. LibraryWindow is
 * the visual representation of this class
 */
public class Noise.LibraryManager : Object {
    public signal void file_operations_started ();
    public signal void file_operations_done ();
    public signal void progress_cancel_clicked ();

	public signal void music_counted (int count);
	public signal void music_added (LinkedList<string> not_imported);
	public signal void music_imported (LinkedList<Media> new_media, LinkedList<string> not_imported);
	public signal void music_rescanned (LinkedList<Media> new_media, LinkedList<string> not_imported);

    public signal void media_added (Gee.LinkedList<int> ids);
    public signal void media_updated (Gee.LinkedList<int> ids);
    public signal void media_removed (Gee.LinkedList<int> ids);
    
    public signal void playlist_added (StaticPlaylist playlist);
    public signal void playlist_removed (StaticPlaylist playlist);
    
    public signal void smartplaylist_added (SmartPlaylist smartplaylist);
    public signal void smartplaylist_removed (SmartPlaylist smartplaylist);

    public signal void device_added (Device d);
    public signal void device_removed (Device d);
    public signal void device_name_changed (Device d);

    public LibraryWindow lw { get { return App.main_window; } }
    public DataBaseManager dbm;
    public DataBaseUpdater dbu;
    public FileOperator fo;
    public DeviceManager device_manager;
    public GStreamerTagger tagger;

    public bool main_directory_set {
        get { return !String.is_empty (main_settings.music_folder, true); }
    }

    public bool have_media {
        get { return media_count () > 0; }
    }

    private Gee.TreeMap<int, StaticPlaylist> _playlists; // rowid, playlist of all playlists
    private Gee.HashMap<int, SmartPlaylist> _smart_playlists; // rowid, smart playlist
    private Gee.TreeMap<int, Media> _media; // rowid, media of all media

    private int _playlist_rowid = 0;
    private int _smart_playlist_rowid = 0;
    private int _media_rowid = 0;

    private Gee.LinkedList<Media> open_media_list;

    // TODO: remove this from librarymanager
    public TreeViewSetup music_setup   { get; private set; default = null; }
    public TreeViewSetup queue_setup   { get; private set; default = null; }
    public TreeViewSetup history_setup { get; private set; default = null; }

    // TODO: get rid of this
    private string temp_add_folder;
    private string[] temp_add_other_folders;
    private int other_folders_added;
    private Gee.LinkedList<string> temp_add_files;

    private bool _doing_file_operations = false;
    private bool _opening_file = false;

    public LibraryManager () {
        this.dbm = new DataBaseManager (this);
        this.dbu = new DataBaseUpdater (this, dbm);
        this.fo = new FileOperator (this);

        fo.fo_progress.connect (dbProgress);
        dbm.db_progress.connect (dbProgress);

        _smart_playlists = new Gee.HashMap<int, SmartPlaylist> ();
        _playlists = new Gee.TreeMap<int, StaticPlaylist> ();
        _media = new Gee.TreeMap<int, Media> ();

        // Load all media from database
        lock (_media) {
            foreach (var m in dbm.load_media ()) {
                m.rowid = _media_rowid;
                _media.set (m.rowid, m);
                _media_rowid++;
            }
        }

        // Load smart playlists from database
        lock (_smart_playlists) {
            foreach (var p in dbm.load_smart_playlists ()) {
                p.rowid = _smart_playlist_rowid;
                _smart_playlists.set (_smart_playlist_rowid, p);
                _smart_playlist_rowid++;
            }
        }

        // Load all static playlists from database
        var playlists_added = new Gee.HashSet<string> (); // Used to check for duplicates

        foreach (var p in dbm.load_playlists ()) {
            if (!playlists_added.contains (p.name)) { // Sometimes we get duplicates; ignore them.
                // TODO: these names should be constants defined in DatabaseManager
                // TODO: This souldn't be done like that, create a better function XXX
                switch (p.name) {
                    case "autosaved_music":
                        music_setup = lw.get_treeviewsetup_from_playlist(p);
                        if (music_setup != null)
                            music_setup.set_hint (ViewWrapper.Hint.MUSIC);
                    break;

                    case "autosaved_queue":
                        queue_setup = lw.get_treeviewsetup_from_playlist(p);
                        if (queue_setup != null)
                            queue_setup.set_hint (ViewWrapper.Hint.READ_ONLY_PLAYLIST);

                        var to_queue = new LinkedList<Media> ();

                        foreach (var m in p.medias)
                            to_queue.add (m);

                        App.player.queue_media (to_queue);
                    break;

                    // TODO: Use ZeitGeist to handle history !
                    case "autosaved_history":
                        history_setup = lw.get_treeviewsetup_from_playlist(p);
                        if (history_setup != null)
                            history_setup.set_hint (ViewWrapper.Hint.READ_ONLY_PLAYLIST);
                        
                        var to_history = new LinkedList<Media> ();

                        foreach (var m in p.medias)
                            to_history.add (m);

                        App.player.history_playlist.add_medias (to_history);
                    break;

                    default:
                        lock (_playlists) {
                            p.rowid = _playlist_rowid;
                            _playlists.set (_playlist_rowid, p);
                            _playlist_rowid++;
                        }
                    break;
                }

                playlists_added.add (p.name);
            }
        }

        if (music_setup == null)
            music_setup = new TreeViewSetup (ListColumn.ARTIST,
                                             Gtk.SortType.ASCENDING,
                                             ViewWrapper.Hint.MUSIC);

        if (queue_setup == null)
            queue_setup = new TreeViewSetup (ListColumn.NUMBER,
                                             Gtk.SortType.ASCENDING,
                                             ViewWrapper.Hint.READ_ONLY_PLAYLIST);

        if (history_setup == null)
            history_setup = new TreeViewSetup (ListColumn.NUMBER,
                                               Gtk.SortType.ASCENDING,
                                               ViewWrapper.Hint.READ_ONLY_PLAYLIST);

        device_manager = new DeviceManager (this);
        device_manager.device_added.connect ((device) => {device_added (device);});
        device_manager.device_removed.connect ((device) => {device_removed (device);});

        other_folders_added = 0;

        file_operations_done.connect (()=> {
            if (temp_add_other_folders != null) {
                other_folders_added++;
                add_folder_to_library (temp_add_other_folders[other_folders_added-1]);
                if (other_folders_added == temp_add_other_folders.length) {
                    other_folders_added = 0;
                    temp_add_other_folders = null;
                }
            }
        });

        load_media_art_cache.begin ();
    }

    private async void load_media_art_cache () {
        lock (_media) {
            yield CoverartCache.instance.load_for_media_async (media ());
        }
    }

    private async void update_media_art_cache () {
        yield CoverartCache.instance.fetch_all_cover_art_async (media ());
    }

    /************ Library/Collection management stuff ************/
    public virtual void dbProgress (string? message, double progress) {
        notification_manager.doProgressNotification (message, progress);
    }

    public bool doProgressNotificationWithTimeout () {
        if (_doing_file_operations) {
            Gdk.threads_enter ();
            notification_manager.doProgressNotification (null, (double) fo.index / (double) fo.item_count);
            Gdk.threads_leave ();
        }

        if (fo.index < fo.item_count && _doing_file_operations)
            return true;

        return false;
    }
    
    public void remove_all_static_playlists () {
        var list = new Gee.LinkedList<int> ();
        lock (_playlists) {
            foreach (var id in _playlists.keys) {
                if (playlist_from_id (id).read_only == false)
                    list.add (id);
            }
        }
        foreach (var id in list) {
                remove_playlist (id);
        }
    }

    public async void set_music_folder (string folder) {
        if (start_file_operations (_("Importing music from %s...").printf ("<b>" + String.escape (folder) + "</b>"))) {
            remove_all_static_playlists ();

            clear_media ();

            App.player.unqueue_media (media());

            App.player.reset_already_played ();
            // FIXME: these are library window's internals. Shouldn't be here
            lw.update_sensitivities ();
            App.player.stopPlayback ();

            main_settings.music_folder = folder;

            main_settings.music_mount_name = "";

            set_music_folder_thread ();
        }
    }

    private async void set_music_folder_thread () {
        SourceFunc callback = set_music_folder_thread.callback;

        Threads.add (() => {
            var music_folder_file = File.new_for_path (main_settings.music_folder);
            LinkedList<string> files = new LinkedList<string> ();

            var items = fo.count_music_files (music_folder_file, ref files);
            debug ("found %d items to import\n", items);

            var to_import = remove_duplicate_files (files);

            fo.resetProgress (to_import.size - 1);
            Timeout.add (100, doProgressNotificationWithTimeout);
            fo.import_files (to_import, FileOperator.ImportType.SET);

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

        Threads.add (() => {
            var to_import = remove_duplicate_files (temp_add_files);

            fo.resetProgress (to_import.size - 1);
            Timeout.add (100, doProgressNotificationWithTimeout);
            fo.import_files (to_import, FileOperator.ImportType.IMPORT);

            Idle.add ((owned) callback);
        });

        yield;
    }

    /**
     * Used to avoid importing already-imported files.
     */
    private Gee.LinkedList<string> remove_duplicate_files (Gee.LinkedList<string> files) {
        
        var to_import = files;
        foreach (var m in media ()) {
            if (files.contains (m.uri)) {
                to_import.remove (m.uri);
                debug ("-- DUPLICATE FOUND for: %s", m.uri);
            }
        }

        return to_import;
    }

    public void add_folder_to_library (string folder, string[]? other_folders = null) {
        if (other_folders != null)
            temp_add_other_folders = other_folders;

        if (start_file_operations (_("Adding music from %s to library...").printf ("<b>" + String.escape (folder) + "</b>"))) {
            temp_add_folder = folder;
            add_folder_to_library_async ();
        }
    }

    private async void add_folder_to_library_async () {
        SourceFunc callback = add_folder_to_library_async.callback;

        Threads.add (() => {
            var file = File.new_for_path (temp_add_folder);
            var files = new LinkedList<string> ();

            fo.count_music_files (file, ref files);

            var to_import = remove_duplicate_files (files);

            fo.resetProgress (to_import.size - 1);
            Timeout.add (100, doProgressNotificationWithTimeout);
            fo.import_files (to_import, FileOperator.ImportType.IMPORT);

            Idle.add ((owned) callback);
        });

        yield;
    }

    public void rescan_music_folder () {
        if (start_file_operations (_("Rescanning music for changes. This may take a while..."))) {
            rescan_music_folder_async ();
        }
    }

    private async void rescan_music_folder_async () {
        SourceFunc callback = rescan_music_folder_async.callback;

        var paths = new Gee.HashMap<string, Media> ();
        var to_remove = new Gee.LinkedList<Media> ();
        var to_import = new Gee.LinkedList<string> ();

        Threads.add (() => {
            fo.resetProgress (100);
            Timeout.add (100, doProgressNotificationWithTimeout);

            var music_folder_dir = main_settings.music_folder;
            foreach (Media s in _media.values) {
                if (!s.isTemporary && !s.isPreview && s.uri.contains (music_folder_dir))
                    paths.set (s.uri, s);

                if (s.uri.contains (music_folder_dir) && !File.new_for_uri (s.uri).query_exists ())
                        to_remove.add (s);
            }
            fo.index = 5;

            // get a list of the current files
            var files = new LinkedList<string> ();
            fo.count_music_files (File.new_for_path (music_folder_dir), ref files);
            fo.index = 10;

            foreach (string s in files) {
                // XXX: libraries are not necessarily local. This will fail
                // for remote libraries FIXME
                if (paths.get (s) == null)
                    to_import.add (s);
            }

            to_import = remove_duplicate_files (to_import);

            debug ("Importing %d new songs\n", to_import.size);
            if (to_import.size > 0) {
                fo.resetProgress (to_import.size);
                Timeout.add (100, doProgressNotificationWithTimeout);
                fo.import_files (to_import, FileOperator.ImportType.RESCAN);
            }
            else {
                fo.index = 90;
            }

            Idle.add ((owned) callback);
        });

        if (!fo.cancelled) {
            remove_media (to_remove, false);
        }

        if (to_import.size == 0)
            finish_file_operations ();

        yield;
    }

    public void play_files (File[] files) {
        _opening_file = true;
        tagger = new GStreamerTagger();
        open_media_list = new Gee.LinkedList<Media> ();
        tagger.media_imported.connect(media_opened_imported);
        tagger.queue_finished.connect(() => {_opening_file = false;});
        var files_list = new LinkedList<string>();
        foreach (var file in files) {
            files_list.add (file.get_uri ());
        }
        tagger.discoverer_import_media (files_list);
    }
    
    private void media_opened_imported(Media m) {
        m.isTemporary = true;
        open_media_list.add (m);
        if (!_opening_file)
            media_opened_finished();
    }
    
    private void media_opened_finished() {
        App.player.queue_media (open_media_list);
        if (!App.player.playing) {
            App.player.getNext (true);
            lw.playClicked ();
        }
    }
    
    /************************ StaticPlaylist stuff ******************/
    public int playlist_count () {
        return _playlists.size;
    }

    public int playlist_count_without_read_only () {
        int i = 0;
        foreach (var p in _playlists.values) {
            if (p.read_only == false)
                i++;
        }
        return i;
    }

    public Gee.Collection<StaticPlaylist> playlists () {
        return _playlists.values;
    }

    public Gee.TreeMap<int, StaticPlaylist> playlist_hash () {
        return _playlists;
    }

    public StaticPlaylist playlist_from_id (int id) {
        return _playlists.get (id);
    }

    public StaticPlaylist? playlist_from_name (string name) {
        StaticPlaylist? rv = null;

        lock (_playlists) {
            foreach (var p in playlists ()) {
                if (p.name == name) {
                    rv = p;
                    break;
                }
            }
        }

        return rv;
    }

    public int add_playlist (StaticPlaylist p) {
        lock (_playlists) {
            p.rowid = _playlist_rowid;
            _playlist_rowid++;
            _playlists.set (p.rowid, p);
        }

        dbm.add_playlist (p);
        playlist_added (p);

        return p.rowid;
    }

    public void remove_playlist (int id) {
        StaticPlaylist removed;

        lock (_playlists) {
            _playlists.unset (id, out removed);
        }

        dbu.removeItem (removed);
        playlist_removed (removed);
    }

    /**************** Smart playlists ****************/
    public int smart_playlist_count () {
        return _smart_playlists.size;
    }

    public Collection<SmartPlaylist> smart_playlists () {
        return _smart_playlists.values;
    }

    public Gee.HashMap<int, SmartPlaylist> smart_playlist_hash () {
        return _smart_playlists;
    }

    public SmartPlaylist smart_playlist_from_id (int id) {
        return _smart_playlists.get (id);
    }

    public SmartPlaylist? smart_playlist_from_name (string name) {
        SmartPlaylist? rv = null;

        lock (_smart_playlists) {
            foreach (var p in smart_playlists ()) {
                if (p.name == name) {
                    rv = p;
                    break;
                }
            }
         }

        return rv;
    }

    public async void save_smart_playlists () {
        SourceFunc callback = save_smart_playlists.callback;

        Threads.add (() => {
            lock (_smart_playlists) {
                dbm.save_smart_playlists (smart_playlists ());
            }

            Idle.add ((owned) callback);
        });

        yield;
    }

    public int add_smart_playlist (SmartPlaylist p) {
        
        lock (_smart_playlists) {
            p.rowid = _smart_playlist_rowid;
            _smart_playlist_rowid++;
            _smart_playlists.set (p.rowid, p);
        }

        save_smart_playlists ();
        smartplaylist_added (p);
        return p.rowid;
    }

    public void remove_smart_playlist (int id) {
        SmartPlaylist removed;

        lock (_smart_playlists) {
            _smart_playlists.unset (id, out removed);
        }

        smartplaylist_removed (removed);
        dbu.removeItem (removed);
    }

    /******************** Media stuff ******************/
    public  void clear_media () {
        message ("-- Clearing media");

        // We really only want to clear the songs that are permanent and on the file system
        // Dont clear podcasts that link to a url, device media, temporary media, previews, songs
        var unset = new Gee.LinkedList<Media> ();

        foreach (int i in _media.keys) {
            var s = _media.get (i);

            if (!s.isTemporary && !s.isPreview)
                unset.add (s);
        }

        remove_media (unset, false);

        debug ("--- MEDIA CLEARED ---");
    }

    private async void update_smart_playlists_async () {
        Idle.add (update_smart_playlists_async.callback);
        yield;

        lock (_smart_playlists) {
            foreach (var p in smart_playlists ()) {
                lock (_media) {
                    p.add_medias (media ());
                }
            }
        }
    }

    public int media_count () {
        return _media.size;
    }

    public Gee.Collection<Media> media () {
        return _media.values;
    }

    public void update_media_item (Media s, bool updateMeta, bool record_time) {
        var one = new LinkedList<Media> ();
        one.add (s);

        update_media (one, updateMeta, record_time);
    }

    public void update_media (Collection<Media> updates, bool updateMeta, bool record_time) {
        var rv = new LinkedList<int> ();

        foreach (Media s in updates) {
            /*_media.set (s.rowid, s);*/
            rv.add (s.rowid);

            if (record_time)
                s.last_modified = (int)time_t ();
        }

        debug ("%d media updated", rv.size);
        media_updated (rv);

        /* now do background work. even if updateMeta is true, so must user preferences */
        if (updateMeta)
            fo.save_media (updates);

        foreach (Media s in updates)
            dbu.update_media (s);

        update_smart_playlists_async.begin ();
    }

    public async void save_media () {
        SourceFunc callback = save_media.callback;

        Threads.add (() => {
            lock (_media) {
                dbm.update_media (_media.values);
            }

            Idle.add ((owned) callback);
        });

        yield;
    }

    /**
     * Used extensively. All other media data stores a media rowid, and then
     * use this to retrieve the media. This is for memory saving and
     * consistency
     */
    public Media media_from_id (int id) {
        return _media.get (id);
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

    public void media_from_name (Gee.Collection<Media> tests, ref Gee.LinkedList<int> found, ref Gee.LinkedList<Media> not_found) {
        Media[] searchable;

        lock (_media) {
            searchable = _media.values.to_array ();
        }

        foreach (Media test in tests) {
            bool found_match = false;
            for (int i = 0; i < searchable.length; ++i) {
                var s = searchable[i];
                if (test.title.down () == s.title.down () && test.artist.down () == s.artist.down ()) {
                    found.add (s.rowid);
                    found_match = true;
                    break;
                }
            }

            if (!found_match)
                not_found.add (test);
        }
    }

    public Media? media_from_file (File file) {
        lock (_media) {
            foreach (var m in media ()) {
                if (m != null && m.file.equal (file))
                    return m;
            }
        }

        return null;
    }

    public Media? media_from_uri (string uri) {
        lock (_media) {
            foreach (var m in media ()) {
                if (m != null && m.uri == uri)
                    return m;
            }
        }

        return null;
    }

    public Gee.Collection<Media> media_from_playlist (int id) {
        return _playlists.get (id).medias;
    }

    public Collection<Media> media_from_smart_playlist (int id) {
        return _smart_playlists.get (id).medias;
    }

    public void add_media_item (Media s) {
        var coll = new Gee.LinkedList<Media> ();
        coll.add (s);
        add_media (coll);
    }

    public void add_media (Gee.Collection<Media> new_media) {
        if (new_media.size < 1) // happens more often than you would think
            return;

        var added = new Gee.LinkedList<int> ();

        foreach (var s in new_media) {
            if (s.rowid == 0) {
                s.rowid = _media_rowid;
                _media_rowid++;
            }

            added.add (s.rowid);

            _media.set (s.rowid, s);
        }
        media_added (added);

        dbm.add_media (new_media);
        update_smart_playlists_async.begin ();
    }

    public void remove_media (Gee.LinkedList<Media> toRemove, bool trash) {
        var removedIds = new Gee.LinkedList<int> ();
        var removeURIs = new Gee.LinkedList<string> ();

        foreach (var s in toRemove) {
            removedIds.add (s.rowid);
            removeURIs.add (s.uri);

            if (s == App.player.media_info.media)
                App.player.stopPlayback ();
        }

        dbu.removeItem (removeURIs);

        if (trash)
            fo.remove_media (removeURIs);

        // Emit signal before actually removing the media because otherwise
        // media_from_id () and media_from_ids () wouldn't work.
        media_removed (removedIds);

        lock (_media) {
            foreach (Media s in toRemove)
                _media.unset (s.rowid);
        }

        lock (_playlists) {
            foreach (var p in playlists ())
                p.remove_medias (toRemove);
        }

        // TODO: move away. It's called twice due to LW's internal handlers
        //lw.update_sensitivities ();

        update_smart_playlists_async.begin ();
    }

    public void cancel_operations () {
        progress_cancel_clicked ();
    }

    public bool start_file_operations (string? message) {
        if (_doing_file_operations)
            return false;

        notification_manager.doProgressNotification (message, 0.0);
        _doing_file_operations = true;
        lw.update_sensitivities ();
        file_operations_started ();
        return true;
    }

    public bool doing_file_operations () {
        return _doing_file_operations;
    }

    public void finish_file_operations () {
        _doing_file_operations = false;
        debug ("file operations finished or cancelled\n");

        file_operations_done ();
        update_media_art_cache.begin ();
        Timeout.add(3000, () => {
            notification_manager.showSongNotification ();
            return false;
        });
    }
}

