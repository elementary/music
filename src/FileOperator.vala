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
 *              Corentin Noël <tintou@mailoo.org>
 */

public class Noise.FileOperator : Object {
    public signal void import_cancelled ();
    public signal void rescan_cancelled ();

    public GStreamerTagger tagger;
    public Cancellable cancellable;
    CoverImport cover_importer;

    public int index;
    public int item_count;
    int queue_size = 0;

    ImportType import_type;
    StaticPlaylist new_playlist;
    Gee.TreeSet<Media> all_new_imports;
    Gee.TreeSet<string> import_errors;
    Gee.HashMap<string, GLib.FileMonitor> monitors;

    public enum ImportType  {
        SET,
        RESCAN,
        PLAYLIST,
        IMPORT
    }

    public FileOperator () {
        TagLib.ID3v2.set_default_text_encoding (TagLib.ID3v2.Encoding.UTF8);

        cancellable = new GLib.Cancellable ();
        all_new_imports = new Gee.TreeSet<Media> ();
        import_errors = new Gee.TreeSet<string> ();
        monitors = new Gee.HashMap<string, GLib.FileMonitor> (null, null);
        tagger = new GStreamerTagger (cancellable);
        cover_importer = new CoverImport (cancellable);

        tagger.media_imported.connect (media_imported);
        tagger.import_error.connect (import_error);
        tagger.queue_finished.connect (queue_finished);
        // Use right encoding

        var music_folder = Settings.Main.get_default ().music_folder;
        var file = GLib.File.new_for_path (music_folder);
        var dirs = new Gee.TreeSet<string> ();
        dirs.add (music_folder);
        list_recursive_directory (file, ref dirs);
        foreach (var dir in dirs) {
            var dir_file = GLib.File.new_for_path (dir);
            try {
                var file_monitor = dir_file.monitor (GLib.FileMonitorFlags.SEND_MOVED, null);
                monitors.set (dir, file_monitor);
                file_monitor.changed.connect (file_monitored_changed);
            } catch (Error e) {
                warning("file %s: %s", dir, e.message);
            }
        }
    }

    public int list_recursive_directory (File music_folder, ref Gee.TreeSet<string> dirs) {
        FileInfo file_info = null;
        int index = 0;
        try {
            var enumerator = music_folder.enumerate_children(FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE + "," + FileAttribute.STANDARD_CONTENT_TYPE, 0);
            while ((file_info = enumerator.next_file ()) != null) {
                var file = music_folder.get_child (file_info.get_name ());

                if(file_info.get_file_type() == FileType.DIRECTORY) {
                    dirs.add (file.get_uri ());
                    list_recursive_directory (file, ref dirs);
                }
            }
        } catch (Error err) {
            warning("Could not pre-scan music folder. Progress percentage may be off: %s\n", err.message);
        }

        return index;
    }

    public void connect_to_manager () {
        NotificationManager.get_default ().progress_canceled.connect (() => {
            cancellable.cancel ();
        });
    }

    public void resetProgress (int items) {
        index = 0;
        item_count = items;
    }

    // TODO: Rewrite it using GStreamer's TagSetter
    public async void save_media (Gee.Collection<Media> to_save) {
        var copy = new Gee.TreeSet<Media> ();
        copy.add_all (to_save);
        var main_settings = Settings.Main.get_default ();
        foreach (Media s in copy) {
            if (s.isTemporary || s.isPreview || File.new_for_uri (s.uri).get_path ().has_prefix (main_settings.music_folder) == false)
                continue;

            if (main_settings.write_metadata_to_file) {
                TagLib.File tag_file;
                tag_file = new TagLib.File (File.new_for_uri (s.uri).get_path ());

                if (tag_file != null && tag_file.tag != null && tag_file.audioproperties != null) {
                    tag_file.tag.title = s.title;
                    tag_file.tag.artist = s.artist;
                    tag_file.tag.album = s.album;
                    tag_file.tag.genre = s.genre;
                    tag_file.tag.comment = s.comment;
                    tag_file.tag.year = s.year;
                    tag_file.tag.track  = s.track;
                    tag_file.save ();
                } else {
                    debug ("Could not save %s.\n", s.uri);
                }
            }

            if (main_settings.update_folder_hierarchy)
                update_file_hierarchy (s, true, false);
        }
    }

    public bool update_file_hierarchy (Media s, bool delete_old, bool emit_update) {
        try {
            File dest = FileUtils.get_new_destination (s);
            if (dest == null)
                return true;

            File original = File.new_for_uri (s.uri);
            /* copy the file over */
            bool success = false;
            if (!delete_old) {
                debug ("Copying %s to %s", s.uri, dest.get_uri ());
                success = original.copy (dest, FileCopyFlags.NONE, null, null);
            } else {
                debug("Moving %s to %s", s.uri, dest.get_uri ());
                success = original.move (dest, FileCopyFlags.NONE, null, null);
            }

            if (success) {
                debug ("success copying file");
                s.uri = dest.get_uri ();
                // wait to update media when out of thread
                if (emit_update) {
                    Idle.add ( () => {
                        libraries_manager.local_library.update_media (s, false, false); return false;
                    });
                }
            } else {
                warning("Failure: Could not copy imported media %s to media folder %s", s.uri, dest.get_path());
                return false;
            }

            /* if we are supposed to delete the old, make sure there are no items left in folder if we do */
            if (delete_old) {
                var dummy = new Gee.TreeSet<string> ();
                var old_folder_items = FileUtils.count_music_files (original.get_parent (), dummy);
                // must check for .jpg's as well.

                if (old_folder_items == 0) {
                    message ("going to delete %s because no files are in it\n", original.get_parent ().get_path ());
                    original.get_parent ().delete ();
                }
            }
        } catch (Error err) {
            warning ("Could not copy imported media %s to media folder: %s\n", s.uri, err.message);
            return false;
        }

        return true;
    }

    public void remove_media (Gee.Collection<Media> toRemove) {
        var dummy_list = new Gee.TreeSet<string> ();
        foreach (var s in toRemove) {
            try {
                var file = File.new_for_uri (s.uri);
                file.trash ();
                var old_folder_items = FileUtils.count_music_files (file.get_parent (), dummy_list);
                //TODO: COPY ALBUM AND IMAGE ARTWORK
                if (old_folder_items == 0) {
                    debug("going to delete %s because no files are in it\n", file.get_parent ().get_path ());
                    //original.get_parent ().delete ();
                    var old_folder_parent_items = FileUtils.count_music_files (file.get_parent ().get_parent (), dummy_list);
                    if(old_folder_parent_items == 0) {
                        debug("going to delete %s because no files are in it\n", file.get_parent ().get_parent ().get_path ());
                    }
                }
            } catch (GLib.Error err) {
                warning ("Could not move file %s to trash: %s (you could be using a file system which is not supported)\n", s.uri, err.message);
            }
        }
    }

    private void file_monitored_changed (GLib.File file, GLib.File? other_file, GLib.FileMonitorEvent event_type) {
        switch (event_type) {
            case GLib.FileMonitorEvent.DELETED:
                var media = libraries_manager.local_library.media_from_file (file);
                if (media != null)
                    libraries_manager.local_library.remove_media (media, false);
                var monitor = monitors.get (file.get_uri ());
                if (monitor != null) {
                    var medias_to_remove = new Gee.TreeSet<Noise.Media> ();
                    foreach (var m in libraries_manager.local_library.get_medias ()) {
                        if (m.uri.has_prefix (file.get_uri ()))
                            medias_to_remove.add (m);
                    }

                    libraries_manager.local_library.remove_medias (medias_to_remove, false);
                    monitor.cancel ();
                    monitors.unset (file.get_uri ());
                }

                break;
            case GLib.FileMonitorEvent.CREATED:
                try {
                    var info = file.query_info (FileAttribute.STANDARD_TYPE + "," + GLib.FileAttribute.STANDARD_CONTENT_TYPE, GLib.FileQueryInfoFlags.NONE);
                    if (info.get_file_type () == FileType.REGULAR && FileUtils.is_valid_content_type (info.get_content_type ())) {
                        var list = new Gee.TreeSet<string> ();
                        list.add (file.get_uri ());
                        import_files (list, ImportType.IMPORT);
                    } else if (info.get_file_type () == FileType.DIRECTORY) {
                        var list = new Gee.TreeSet<string> ();
                        FileUtils.count_music_files (file, list);
                        import_files (list, ImportType.IMPORT);
                    }
                } catch (Error e) {
                    critical (e.message);
                }

                break;
            case GLib.FileMonitorEvent.MOVED:
                var media = libraries_manager.local_library.media_from_file (file);
                media.file = other_file;
                libraries_manager.local_library.update_media (media, true, false);
                break;
        }
    }

    public string get_extension (string name) {
        return name.slice (name.last_index_of (".", 0), name.length);
    }

    public void import_files (Gee.Collection<string> files, ImportType type) {
        import_type = type;
        queue_size += files.size;
        if (files.size == 0) {
            queue_finished ();
        } else {
            tagger.discoverer_import_media (files);
        }
    }

    void media_imported (Media m) {
        all_new_imports.add (m);
        libraries_manager.local_library.add_media (m);

        index++;
        if (index == queue_size) {
            queue_finished ();
        }
    }

    void import_error (string file) {
        index++;
        import_errors.add (file);
        if (index == queue_size) {
            queue_finished ();
        }
    }

    void queue_finished () {
        queue_size = 0;
        if (import_errors.size > 0) {
            NotImportedWindow nim = new NotImportedWindow (import_errors, Settings.Main.get_default ().music_folder);
            nim.show ();
        }

        if (all_new_imports.size > 0)
            App.main_window.show_notification (_("Import Complete"), _("%s has imported your library.").printf (((Noise.App) GLib.Application.get_default ()).get_name ()));

        if (import_type == ImportType.PLAYLIST) {
            var to_add = new Gee.LinkedList<int> ();
            foreach (var s in all_new_imports)
                to_add.add (s.rowid);
            new_playlist.add_medias (to_add);
            new_playlist.name = PlaylistsUtils.get_new_playlist_name (libraries_manager.local_library.get_playlists (), new_playlist.name);
            libraries_manager.local_library.add_playlist (new_playlist);
        }

        // if doing import and copy to music folder is enabled, do copy here
        if ((import_type == ImportType.IMPORT || import_type == ImportType.PLAYLIST) && Settings.Main.get_default ().copy_imported_music) {
            NotificationManager.get_default ().update_progress (_("<b>Copying</b> files to <b>Music Folder</b>…"), 0.0);
            copy_imports_async.begin ();
        } else {
            libraries_manager.local_library.finish_file_operations ();
        }

        //cover_importer.discoverer_import_media (all_new_imports);
        all_new_imports.clear ();
        import_errors.clear ();
        cancellable.reset ();
    }

    public async void copy_imports_async () {
        resetProgress (all_new_imports.size);
        foreach (Media s in all_new_imports) {
            if (!cancellable.is_cancelled ()) {
                //current_operation = "<b>Copying " + s.title + "</b> to <b>Music Folder</b>";
                update_file_hierarchy (s, false, false);
            }

            ++index;
        }

        libraries_manager.local_library.finish_file_operations ();
    }
}
