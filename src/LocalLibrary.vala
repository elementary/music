// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2013 Noise Developers (http://launchpad.net/noise)
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
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 *              Corentin Noël <tintou@mailoo.org>
 */

using Gee;

/**
 * This is where all the media stuff happens. Here, media is retrieved
 * from the db, added to the queue, sorted, and more. LibraryWindow is
 * the visual representation of this class
 */
public class Noise.LocalLibrary : Library {

    public LibraryWindow lw { get { return App.main_window; } }
    public DataBaseManager dbm;
    public DataBaseUpdater dbu;
    public FileOperator fo;
    public GStreamerTagger tagger;
    
    public Gee.LinkedList<StaticPlaylist> _playlists;
    public Gee.LinkedList<SmartPlaylist> _smart_playlists;
    public Gee.LinkedList<Media> _medias;
    public int medias_rowid = 0;
    public int playlists_rowid = 0;
    
    public StaticPlaylist p_music;

    public bool main_directory_set {
        get { return !String.is_empty (main_settings.music_folder, true); }
    }

    private Gee.LinkedList<Media> open_media_list;

    private bool _doing_file_operations = false;
    private bool _opening_file = false;

    public LocalLibrary () {
        libraries_manager.local_library = this;
        _playlists = new Gee.LinkedList<StaticPlaylist> ();
        _smart_playlists = new Gee.LinkedList<SmartPlaylist> ();
        _medias = new Gee.LinkedList<Media> ();
        p_music = new StaticPlaylist ();
        p_music.name = MUSIC_PLAYLIST;
        
        this.dbm = new DataBaseManager ();
        this.dbu = new DataBaseUpdater (dbm);
        this.fo = new FileOperator ();

    }
    
    public override void initialize_library () {
        dbm.init_database ();
        fo.connect_to_manager ();
        fo.fo_progress.connect (dbProgress);
        dbm.db_progress.connect (dbProgress);
        // Load all media from database
        lock (_medias) {
            foreach (var m in dbm.load_media ()) {
                _medias.add (m);
                m.rowid = medias_rowid;
                medias_rowid++;
            }
        }

        // Load smart playlists from database
        lock (_smart_playlists) {
            foreach (var p in dbm.load_smart_playlists ()) {
                _smart_playlists.add (p);
                p.rowid = playlists_rowid;
                playlists_rowid++;
                p.updated.connect ((old_name) => {smart_playlist_updated (p, old_name);});
            }
        }

        // Load all static playlists from database

        lock (_playlists) {
            foreach (var p in dbm.load_playlists ()) {
                if (p.name == C_("Name of the playlist", "Queue") || p.name == _("History")) {
                    continue;
                } else if (p.name != MUSIC_PLAYLIST) {
                    _playlists.add (p);
                    p.rowid = playlists_rowid;
                    playlists_rowid++;
                    p.updated.connect ((old_name) => {playlist_updated (p, old_name);});
                    continue;
                }
            }
        }
        device_manager.set_device_preferences (dbm.load_devices ());

        load_media_art_cache.begin ();
    }

    private async void load_media_art_cache () {
        lock (_medias) {
            yield CoverartCache.instance.load_for_media_async (get_medias ());
        }
    }

    private async void update_media_art_cache () {
        yield CoverartCache.instance.fetch_all_cover_art_async (get_medias ());
    }

    /************ Library/Collection management stuff ************/
    public virtual void dbProgress (string? message, double progress) {
        notification_manager.doProgressNotification (message, progress);
    }

    public bool doProgressNotificationWithTimeout () {
        if (_doing_file_operations) {
            notification_manager.doProgressNotification (null, (double) fo.index / (double) fo.item_count);
        }

        if (fo.index < fo.item_count && _doing_file_operations)
            return true;

        return false;
    }
    
    public void remove_all_static_playlists () {
        var list = new Gee.LinkedList<int> ();
        lock (_playlists) {
            foreach (var p in _playlists) {
                if (p.read_only == false)
                    list.add (_playlists.index_of(p));
            }
        }
        foreach (var id in list) {
                remove_playlist (id);
        }
    }

    public async void set_music_folder (string folder) {
        string m_folder = folder;
        m_folder = m_folder.replace ("/media", "");
        m_folder = m_folder.replace (GLib.Environment.get_home_dir ()+ "/", "");
        
        if (start_file_operations (_("Importing music from %s…").printf ("<b>" + String.escape (m_folder) + "</b>"))) {
            remove_all_static_playlists ();

            clear_medias ();

            App.player.unqueue_media (_medias);

            App.player.reset_already_played ();
            // FIXME: these are library window's internals. Shouldn't be here
            App.main_window.update_sensitivities.begin ();
            App.player.stop_playback ();

            main_settings.music_mount_name = "";
            main_settings.music_folder = folder;

            set_music_folder_thread.begin ();
        }
    }

    private async void set_music_folder_thread () {
        SourceFunc callback = set_music_folder_thread.callback;

        Threads.add (() => {
            var music_folder_file = File.new_for_path (main_settings.music_folder);
            LinkedList<string> files = new LinkedList<string> ();

            var items = FileUtils.count_music_files (music_folder_file, ref files);
            debug ("found %d items to import\n", items);

            var to_import = remove_duplicate_files (files);

            fo.resetProgress (to_import.size - 1);
            Timeout.add (100, doProgressNotificationWithTimeout);
            fo.import_files (to_import, FileOperator.ImportType.SET);

            Idle.add ((owned) callback);
        });

        yield;
    }

    public override void add_files_to_library (Gee.Collection<string> files) {
        if (start_file_operations (_("Adding files to library…"))) {
            add_files_to_library_async.begin (files);
        }
    }

    private async void add_files_to_library_async (Gee.Collection<string> files) {
        SourceFunc callback = add_files_to_library_async.callback;

        Threads.add (() => {
            var to_import = remove_duplicate_files (files);

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
    private Gee.Collection<string> remove_duplicate_files (Gee.Collection<string> files) {
        
        var to_import = files;
        foreach (var m in get_medias ()) {
            if (files.contains (m.uri)) {
                to_import.remove (m.uri);
                debug ("-- DUPLICATE FOUND for: %s", m.uri);
            }
        }

        return to_import;
    }

    public void add_folder_to_library (Gee.Collection<string> folders) {

        if (start_file_operations (_("<b>Importing</b> music to library…"))) {
            add_folder_to_library_async.begin (folders);
        }
    }

    private async void add_folder_to_library_async (Gee.Collection<string> folders) {
        SourceFunc callback = add_folder_to_library_async.callback;

        Threads.add (() => {
            var files = new LinkedList<string> ();
            foreach (var folder in folders) {
                var file = File.new_for_path (folder);
                FileUtils.count_music_files (file, ref files);
            }
            var to_import = remove_duplicate_files (files);
            fo.resetProgress (to_import.size - 1);
            Timeout.add (100, doProgressNotificationWithTimeout);
            fo.import_files (to_import, FileOperator.ImportType.IMPORT);

            Idle.add ((owned) callback);
        });

        yield;
    }

    public void rescan_music_folder () {
        if (start_file_operations (_("Rescanning music for changes. This may take a while…"))) {
            App.main_window.update_sensitivities.begin ();
            rescan_music_folder_async.begin ();
        }
    }

    private async void rescan_music_folder_async () {
        SourceFunc callback = rescan_music_folder_async.callback;

        var to_remove = new Gee.LinkedList<Media> ();
        var to_import = new Gee.LinkedList<string> ();
        var files = new LinkedList<string> ();

        Threads.add (() => {

            // get a list of the current files
            var music_folder_dir = main_settings.music_folder;
            FileUtils.count_music_files (File.new_for_path (music_folder_dir), ref files);
            
            foreach (var m in get_medias ()) {
                if (!m.isTemporary && !m.isPreview && m.uri.contains (music_folder_dir))

                if (!File.new_for_uri (m.uri).query_exists ())
                    to_remove.add (m);
                if (files.contains (m.uri))
                    files.remove (m.uri);
            }
            debug ("found %d items to import\n", files.size);

            to_import.add_all (remove_duplicate_files (files));

            debug ("Importing %d new songs\n", to_import.size);
            if (!to_import.is_empty) {
                fo.resetProgress (to_import.size - 1);
                Timeout.add (100, doProgressNotificationWithTimeout);
                fo.import_files (to_import, FileOperator.ImportType.RESCAN);
            }

            if (files.is_empty)
                finish_file_operations ();

            Idle.add ((owned) callback);
        });

        if (!fo.cancelled) {
            remove_medias (to_remove, false);
        }

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
        if (open_media_list.size > 0) {
            if (!App.player.playing) {
                App.player.playMedia (open_media_list.get (0), false);
                App.main_window.play_media ();
            } else {
                string primary_text = _("Added to your queue:");

                var secondary_text = new StringBuilder ();
                secondary_text.append (open_media_list.get (0).get_display_title ());
                secondary_text.append ("\n");
                secondary_text.append (open_media_list.get (0).get_display_artist ());

                Gdk.Pixbuf? pixbuf = CoverartCache.instance.get_original_cover (open_media_list.get (0)).scale_simple (128, 128, Gdk.InterpType.HYPER);
#if HAVE_LIBNOTIFY
                App.main_window.show_notification (primary_text, secondary_text.str, pixbuf, Notify.Urgency.LOW);
#else
                App.main_window.show_notification (primary_text, secondary_text.str, pixbuf);
#endif
            }
        }
    }
    
    /************************ StaticPlaylist stuff ******************/

    public override bool support_playlists () {
        return true;
    }
    
    public override Gee.Collection<StaticPlaylist> get_playlists () {
        return _playlists;
    }

    public override StaticPlaylist? playlist_from_id (int id) {
        lock (_playlists) {
            foreach (var p in get_playlists ()) {
                if (p.rowid == id) {
                    return p;
                }
            }
        }
        return null;
    }

    public override StaticPlaylist? playlist_from_name (string name) {
        if (name == p_music.name)
            return p_music;

        lock (_playlists) {
            foreach (var p in get_playlists ()) {
                if (p.name == name) {
                    return p;
                }
            }
        }
        return null;
    }

    public override void add_playlist (StaticPlaylist p) {
        lock (_playlists) {
            _playlists.add (p);
        }
        p.rowid = playlists_rowid;
        playlists_rowid++;
        p.updated.connect ((old_name) => {playlist_updated (p, old_name);});
        dbm.add_playlist (p);
        playlist_added (p);
        debug ("playlist %s added",p.name);
    }

    public override void remove_playlist (int id) {
        lock (_playlists) {
            foreach (var playlist in get_playlists ()) {
                if (playlist.rowid == id) {
                    _playlists.remove (playlist);
                    dbu.removeItem.begin (playlist);
                    playlist_removed (playlist);
                    break;
                }
            }
        }
    }

    public void playlist_updated (StaticPlaylist p, string? old_name = null) {
        dbu.save_playlist (p, old_name);
    }

    /**************** Smart playlists ****************/
    
    public override bool support_smart_playlists () {
        return true;
    }
    
    public override Collection<SmartPlaylist> get_smart_playlists () {
        return _smart_playlists;
    }

    public override SmartPlaylist? smart_playlist_from_id (int id) {
        lock (_smart_playlists) {
            foreach (var p in get_smart_playlists ()) {
                if (p.rowid == id) {
                    return p;
                }
            }
         }
        return null;
    }

    public override SmartPlaylist? smart_playlist_from_name (string name) {

        lock (_smart_playlists) {
            foreach (var p in get_smart_playlists ()) {
                if (p.name == name) {
                    return p;
                }
            }
         }

        return null;
    }

    public async void save_smart_playlists () {
        SourceFunc callback = save_smart_playlists.callback;

        Threads.add (() => {
            lock (_smart_playlists) {
                dbm.save_smart_playlists (get_smart_playlists ());
            }

            Idle.add ((owned) callback);
        });

        yield;
    }

    public override void add_smart_playlist (SmartPlaylist p) {
        
        lock (_smart_playlists) {
            _smart_playlists.add (p);
        }
        p.rowid = playlists_rowid;
        playlists_rowid++;

        p.updated.connect ((old_name) => {smart_playlist_updated (p, old_name);});
        smartplaylist_added (p);
    }

    public override void remove_smart_playlist (int id) {
        lock (_smart_playlists) {
            foreach (var p in get_smart_playlists ()) {
                if (p.rowid == id) {
                    _smart_playlists.remove (p);
                    smartplaylist_removed (p);
                    dbu.removeItem.begin (p);
                    break;
                }
            }
        }
    }

    public void smart_playlist_updated (SmartPlaylist p, string? old_name = null) {
        dbu.save_smart_playlist (p, old_name);
    }

    /******************** Media stuff ******************/
    public void clear_medias () {
        message ("-- Clearing medias");

        // We really only want to clear the songs that are permanent and on the file system
        // Dont clear podcasts that link to a url, device media, temporary media, previews, songs
        var unset = new Gee.LinkedList<Media> ();

        foreach (var s in _medias) {
            if (!s.isTemporary && !s.isPreview)
                unset.add (s);
        }

        remove_medias (unset, false);

        debug ("--- MEDIAS CLEARED ---");
    }

    private async void update_smart_playlists_async (Collection<Media> media) {
        Idle.add (update_smart_playlists_async.callback);
        yield;

        lock (_smart_playlists) {
            foreach (var p in get_smart_playlists ()) {
                lock (_medias) {
                    p.update_medias (media);
                }
            }
        }
    }

    public override Gee.Collection<Media> get_medias () {
        return _medias;
    }

    public override void update_media (Media s, bool updateMeta, bool record_time) {
        var one = new LinkedList<Media> ();
        one.add (s);

        update_medias (one, updateMeta, record_time);
    }

    public override void update_medias (Collection<Media> updates, bool updateMeta, bool record_time) {
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
            dbu.update_media.begin (s);

        update_smart_playlists_async.begin (updates);
    }

    public async void save_media () {
        SourceFunc callback = save_media.callback;
        
        Threads.add (() => {
            lock (_medias) {
                dbm.update_media (_medias);
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
     
    public override Media? media_from_id (int id) {
        lock (_medias) {
            foreach (var m in _medias) {
                if (m.rowid == id)
                    return m;
            }
        }
        return null;
    }

    public override Gee.Collection<Media> medias_from_ids (Gee.Collection<int> ids) {
        var media_collection = new Gee.LinkedList<Media> ();

        lock (_medias) {
            foreach (var m in _medias) {
                if (ids.contains (m.rowid))
                    media_collection.add (m);
                if (media_collection.size == ids.size)
                    break;
            }
        }

        return media_collection;
    }

    public override Media? find_media (Media to_find) {
        Media? found = null;
        lock (_medias) {
            foreach (var m in _medias) {
                if (to_find.title.down () == m.title.down () && to_find.artist.down () == m.artist.down ()) {
                    found = m;
                    break;
                }
            }
        }
        return found;
    }

    public override Media? media_from_file (File file) {
        lock (_medias) {
            foreach (var m in _medias) {
                if (m != null && m.file.equal (file))
                    return m;
            }
        }

        return null;
    }

    public override Media? media_from_uri (string uri) {
        lock (_medias) {
            foreach (var m in _medias) {
                if (m != null && m.uri == uri)
                    return m;
            }
        }

        return null;
    }

    public override void add_media (Media s) {
        var coll = new Gee.LinkedList<Media> ();
        coll.add (s);
        add_medias (coll);
    }

    public override void add_medias (Gee.Collection<Media> new_media) {
        if (new_media.size < 1) // happens more often than you would think
            return;

        // make a copy of the media list so that it doesn't get modified before
        // the async code (e.g. updating the smart playlists) is done with it
        var media = new Gee.LinkedList<Media> ();
        var added = new Gee.LinkedList<int> ();

        foreach (var s in new_media) {
            media.add(s);
            _medias.add (s);
            s.rowid = medias_rowid;
            medias_rowid++;
            added.add (s.rowid);
        }
        media_added (added);

        dbm.add_media (media);
        update_smart_playlists_async.begin (media);
    }

    public override void remove_media (Media s, bool trash) {
        var coll = new Gee.LinkedList<Media> ();
        coll.add (s);
        remove_medias (coll, trash);
    }

    public override void remove_medias (Gee.Collection<Media> toRemove, bool trash) {
        var removedIds = new Gee.LinkedList<int> ();
        var removeURIs = new Gee.LinkedList<string> ();

        foreach (var s in toRemove) {
            removedIds.add (_medias.index_of(s));
            removeURIs.add (s.uri);

            if (s == App.player.media_info.media)
                App.player.stop_playback ();
        }

        dbu.removeItem.begin (removeURIs);

        if (trash)
            fo.remove_media (removeURIs);

        // Emit signal before actually removing the media because otherwise
        // media_from_id () and media_from_ids () wouldn't work.
        media_removed (removedIds);

        lock (_medias) {
            foreach (Media s in toRemove)
                _medias.remove (s);
        }

        lock (_playlists) {
            foreach (var p in get_playlists ())
                p.remove_medias (toRemove);
        }

        update_smart_playlists_async.begin (toRemove);
    }

    public Gee.LinkedList<Noise.Media> answer_to_device_sync (Device device) {
        var medias_to_sync = new Gee.LinkedList<Noise.Media> ();
        if (device.get_preferences ().sync_music == true) {
            if (device.get_preferences ().sync_all_music == true) {
                medias_to_sync.add_all (get_medias ());
            } else {
                medias_to_sync.add_all (device.get_preferences ().music_playlist.medias);
            }
        }
        return medias_to_sync;
    }

    public override bool start_file_operations (string? message) {
        if (_doing_file_operations)
            return false;

        notification_manager.doProgressNotification (message, 0.0);
        _doing_file_operations = true;
        App.main_window.update_sensitivities.begin ();
        file_operations_started ();
        return true;
    }

    public override bool doing_file_operations () {
        return _doing_file_operations;
    }

    public override void finish_file_operations () {
        _doing_file_operations = false;
        debug ("file operations finished or cancelled\n");

        fo.index = fo.item_count +1;
        file_operations_done ();
        update_media_art_cache.begin ();
        Timeout.add(3000, () => {
            notification_manager.showSongNotification ();
            return false;
        });
    }
}

