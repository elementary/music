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

public class Noise.FileOperator : Object {
    public signal void fo_progress(string? message, double progress);
    public signal void import_cancelled();
    public signal void rescan_cancelled();

    public GStreamerTagger tagger;
    
    bool inThread;
    LinkedList<Media> toSave;
    
    public int index;
    public int item_count;
    int queue_size = 0;
    
    public bool cancelled; // set to true if user cancels
    bool cancelSent; // needed to not send cancel signal twice (in recursive function)
    
    ImportType import_type;
    StaticPlaylist new_playlist;
    LinkedList<Media> new_imports;
    LinkedList<Media> all_new_imports;
    LinkedList<string> import_errors;

    public enum ImportType  {
        SET,
        RESCAN,
        PLAYLIST,
        IMPORT
    }
    
    public FileOperator() {
        inThread = false;
        toSave = new LinkedList<Media>();
        cancelled = false;
        cancelSent = false;
        new_imports = new LinkedList<Media>();
        import_errors = new LinkedList<string>();
        tagger = new GStreamerTagger();
        
        tagger.media_imported.connect(media_imported);
        tagger.import_error.connect(import_error);
        tagger.queue_finished.connect(queue_finished);
        // Use right encoding
        TagLib.ID3v2.set_default_text_encoding (TagLib.ID3v2.Encoding.UTF8);
    }
    
    public void connect_to_manager () {
        App.library_manager.progress_cancel_clicked.connect( () => { 
            cancelled = true;
            tagger.cancel_operations();
        } );
    }

    public void resetProgress(int items) {
        index = 0;
        item_count = items;
        cancelled = false;
        cancelSent = false;
    }

    private static bool is_valid_content_type (string content_type) {
        return FileUtils.is_valid_content_type (content_type, App.get_media_content_types ());
    }
    
    public int count_music_files (File music_folder, ref LinkedList<string> files) {
        FileInfo file_info = null;
        
        try {
            var enumerator = music_folder.enumerate_children(FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE + "," + FileAttribute.STANDARD_CONTENT_TYPE, 0);
            while ((file_info = enumerator.next_file ()) != null) {
                var file = music_folder.get_child (file_info.get_name ());

                if(file_info.get_file_type() == FileType.REGULAR && is_valid_content_type(file_info.get_content_type ())) {
                    index++;
                    files.add (file.get_uri ());
                }
                else if(file_info.get_file_type() == FileType.DIRECTORY) {
                    count_music_files (file, ref files);
                }
            }
        }
        catch(Error err) {
            warning("Could not pre-scan music folder. Progress percentage may be off: %s\n", err.message);
        }

        return index;
    }
    
    
    public void save_media (Collection<Media> to_save) {
        foreach(Media s in to_save) {
            if(!s.isTemporary && !s.isPreview && File.new_for_uri(s.uri).get_path().has_prefix(main_settings.music_folder))
                toSave.offer(s);
        }
        
        if(!inThread) {
            inThread = true;
            Threads.add (save_media_thread);
        }
    }

    public void save_media_thread () {
        while(true) {
            Media s = toSave.poll();
            
            if(s == null) {
                inThread = false;
                return;
            }
            
            if(main_settings.write_metadata_to_file) {
                TagLib.File tag_file;
                tag_file = new TagLib.File(File.new_for_uri(s.uri).get_path());
                
                if(tag_file != null && tag_file.tag != null && tag_file.audioproperties != null) {
                    try {
                        tag_file.tag.title = s.title;
                        tag_file.tag.artist = s.artist;
                        tag_file.tag.album = s.album;
                        tag_file.tag.genre = s.genre;
                        tag_file.tag.comment = s.comment;
                        tag_file.tag.year = s.year;
                        tag_file.tag.track  = s.track;
                        
                        tag_file.save();
                    }
                    finally {
                        
                    }
                }
                else {
                    debug ("Could not save %s.\n", s.uri);
                }
            }
            
            if(main_settings.update_folder_hierarchy)
                update_file_hierarchy(s, true, false);
        }
    }
    
    public File? get_new_destination(Media s) {
        File dest;
        
        try {
            /* initialize file objects */
            File original = File.new_for_uri(s.uri);
            
            var ext = "";
            if(s.uri.has_prefix("cdda://"))
                ext = ".mp3";
            else
                ext = get_extension(s.uri);
            
            dest = File.new_for_path(Path.build_path("/", main_settings.music_folder, s.get_display_album_artist ().replace("/", "_"), s.get_display_album ().replace("/", "_"), s.track.to_string() + " - " + s.get_display_title ().replace("/", "_") + ext));
            
            if(original.get_path() == dest.get_path()) {
                debug("File is already in correct location\n");
                return null;
            }
            
            string extra = "";
            while((dest = File.new_for_path(Path.build_path("/", main_settings.music_folder, s.get_display_album_artist ().replace("/", "_"), s.get_display_album ().replace("/", "_"), s.track.to_string() + " - " + s.get_display_title ().replace("/", "_") + extra + ext))).query_exists()) {
                extra += "_";
            }
            
            /* make sure that the parent folders exist */
            if(!dest.get_parent().query_exists())
                dest.get_parent().make_directory_with_parents(null);
        }
        catch(Error err) {
            debug("Could not find new destination!: %s\n", err.message);
        }
        
        return dest;
    }
    
    public bool update_file_hierarchy(Media s, bool delete_old, bool emit_update) {
        try {
            File dest = get_new_destination(s);
            if(dest == null)
                return true;
            
            File original = File.new_for_uri(s.uri);
            
            /* copy the file over */
            bool success = false;
            if(!delete_old) {
                debug("Copying %s to %s\n", s.uri, dest.get_uri());
                success = original.copy(dest, FileCopyFlags.NONE, null, null);
            }
            else {
                debug("Moving %s to %s\n", s.uri, dest.get_uri());
                success = original.move(dest, FileCopyFlags.NONE, null, null);
            }
            
            if(success) {
                debug("success copying file\n");
                s.uri = dest.get_uri();
                
                // wait to update media when out of thread
                if(emit_update) {
                    Idle.add( () => {
                        App.library_manager.update_media_item (s, false, false); return false;
                    });
                }
            }
            else {
                warning("Failure: Could not copy imported media %s to media folder %s", s.uri, dest.get_path());
                return false;
            }
            
            /* if we are supposed to delete the old, make sure there are no items left in folder if we do */
            if(delete_old) {
                var dummy = new LinkedList<string>();
                var old_folder_items = count_music_files(original.get_parent(), ref dummy);
                // must check for .jpg's as well.
                
                if(old_folder_items == 0) {
                    message ("going to delete %s because no files are in it\n", original.get_parent().get_path());
                    original.get_parent().delete();
                }
            }
        }
        catch(Error err) {
            warning("Could not copy imported media %s to media folder: %s\n", s.uri, err.message);
            return false;
        }
        return true;
    }
    
    public void remove_media (Collection<string> toRemove) {
        var dummy_list = new LinkedList<string>();
        foreach(string s in toRemove) {
            try {
                var file = File.new_for_uri(s);
                file.trash();
                
                var old_folder_items = count_music_files(file.get_parent(), ref dummy_list);
                    
                //TODO: COPY ALBUM AND IMAGE ARTWORK
                if(old_folder_items == 0) {
                    debug("going to delete %s because no files are in it\n", file.get_parent().get_path());
                    //original.get_parent().delete();
                    
                    var old_folder_parent_items = count_music_files(file.get_parent().get_parent(), ref dummy_list);
                    
                    if(old_folder_parent_items == 0) {
                        debug("going to delete %s because no files are in it\n", file.get_parent().get_parent().get_path());
                    }
                }
            }
            catch(Error err) {
                warning("Could not move file %s to trash: %s (you could be using a file system which is not supported)\n", s, err.message);
            }
        }
    }
    
    public string get_extension(string name) {
        return name.slice(name.last_index_of(".", 0), name.length);
    }
    
    private Gee.LinkedList<string> convert_paths_to_uris (Gee.LinkedList<string> paths) {
        var uris = new Gee.LinkedList<string> ();
        foreach (var path in paths) {
            uris.add (File.new_for_path (path).get_uri ());
        }
        return uris;
    }
    
    /* should be called from thread */
    public void import_from_playlist_file_info(Gee.HashMap<string, Gee.LinkedList<string>> playlists) {
        
        foreach (var playlist in playlists.entries) {
            if (playlist.value.get (0).has_prefix ("/")) {
                App.library_manager.add_files_to_library (convert_paths_to_uris (playlist.value));
            } else {
                App.library_manager.add_files_to_library (playlist.value);
            }
        }
        
        foreach (var playlist in playlists.entries) {
            App.library_manager.start_file_operations(C_("Importing playlist", "Importing <b>%s</b> to Library…").printf (playlist.key));
            var new_playlist = new StaticPlaylist();
            new_playlist.name = playlist.key;
            var medias_to_use = playlist.value;
            var to_add = new LinkedList<Media> ();
            foreach (var media in App.library_manager.media ()) {
                if (medias_to_use.contains (media.file.get_path())) {
                    to_add.add (media);
               }
            }
            new_playlist.add_medias (to_add);
            App.library_manager.add_playlist (new_playlist);
            App.library_manager.finish_file_operations();
        }
        
        /*foreach(string path in paths[0]) {
            Media s;
            if( (s = App.library_manager.media_from_file(File.new_for_path (path))) != null)
                internals.add(s.rowid);

                externals.add(path);
        }
        
        new_playlist.name = names[0];
        var to_add = new LinkedList<int>();
        foreach(int i in internals) {
            to_add.add (i);
            App.library_manager.music_added(import_type == ImportType.RESCAN ? new LinkedList<string>() : import_errors);
            App.library_manager.finish_file_operations();
        }

        new_playlist.add_media (to_add);

        if (other_names_list.length > 0) {
            import_from_playlist_file_info({other_names_list[other_playlists_added]}, {other_paths_list[other_playlists_added]});
            other_playlists_added++;
            if (other_playlists_added == other_names_list.length)
            other_names_list = {};
        }*/
    }
    
    public void import_files (LinkedList<string> files, ImportType type) {
        all_new_imports = new LinkedList<Media>();
        new_imports.clear();
        import_errors.clear();
        import_type = type;
        queue_size = files.size;
        
        if(files.size == 0) {
            queue_finished();
        }
        else {
            tagger.discoverer_import_media (files);
        }
    }
    
    void media_imported(Media m) {
        new_imports.add(m);
        all_new_imports.add(m);
        ++index;
        
        if (index == queue_size) {
            queue_finished();
        } else if (new_imports.size >= 200) {
            App.library_manager.add_media (new_imports); // give user some feedback
            new_imports.clear();
        }
    }
    
    void import_error(string file) {
        ++index;
        import_errors.add(file);
        if (index == queue_size) {
            queue_finished();
        }
    }
    
    void queue_finished() {
        App.library_manager.music_imported (all_new_imports, import_errors);
        App.library_manager.add_media (new_imports);
        new_imports.clear();
        
        if(import_type == ImportType.PLAYLIST) {
            var to_add = new LinkedList<int>();
            foreach (var s in all_new_imports)
                to_add.add (s.rowid);
            new_playlist.add_medias (to_add);
            new_playlist.name = PlaylistsUtils.get_new_playlist_name (App.library_manager.playlists (), new_playlist.name);
            App.library_manager.add_playlist (new_playlist);
        }
        
        // if doing import and copy to music folder is enabled, do copy here
        if((import_type == ImportType.IMPORT || import_type == ImportType.PLAYLIST) && main_settings.copy_imported_music) {
            fo_progress(_("<b>Copying</b> files to <b>Music Folder</b>…"), 0.0);
            
            Threads.add (copy_imports_thread);
        }
        else {
            App.library_manager.music_added(import_type == ImportType.RESCAN ? new LinkedList<string>() : import_errors);
            App.library_manager.finish_file_operations();
        }
    }
    
    public void copy_imports_thread() {
        resetProgress(all_new_imports.size);

        foreach(Media s in all_new_imports) {
            if(!cancelled) {
                //current_operation = "<b>Copying " + s.title + "</b> to <b>Music Folder</b>";
                update_file_hierarchy(s, false, false);
            }
            
            ++index;
        }
        
        Idle.add( () => {
            App.library_manager.music_added(import_errors);
            App.library_manager.finish_file_operations();
            
            return false;
        });
    }
}
