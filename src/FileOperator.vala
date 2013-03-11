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
        notification_manager.progress_canceled.connect( () => { 
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
    
    
    public bool update_file_hierarchy(Media s, bool delete_old, bool emit_update) {
        try {
            File dest = FileUtils.get_new_destination(s);
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
                        libraries_manager.local_library.update_media (s, false, false); return false;
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
                var old_folder_items = FileUtils.count_music_files(original.get_parent(), ref dummy);
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
                
                var old_folder_items = FileUtils.count_music_files(file.get_parent(), ref dummy_list);
                    
                //TODO: COPY ALBUM AND IMAGE ARTWORK
                if(old_folder_items == 0) {
                    debug("going to delete %s because no files are in it\n", file.get_parent().get_path());
                    //original.get_parent().delete();
                    
                    var old_folder_parent_items = FileUtils.count_music_files(file.get_parent().get_parent(), ref dummy_list);
                    
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
    
    public void import_files (Collection<string> files, ImportType type) {
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
            libraries_manager.local_library.add_medias (new_imports); // give user some feedback
            new_imports.clear();
        } else if (index == 1) {
            libraries_manager.local_library.add_medias (new_imports); // give user the first feedback
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
        libraries_manager.local_library.music_imported (all_new_imports, import_errors);
        libraries_manager.local_library.add_medias (new_imports);
        new_imports.clear();
        
        if(import_type == ImportType.PLAYLIST) {
            var to_add = new LinkedList<int>();
            foreach (var s in all_new_imports)
                to_add.add (s.rowid);
            new_playlist.add_medias (to_add);
            new_playlist.name = PlaylistsUtils.get_new_playlist_name (libraries_manager.local_library.get_playlists (), new_playlist.name);
            libraries_manager.local_library.add_playlist (new_playlist);
        }
        
        // if doing import and copy to music folder is enabled, do copy here
        if((import_type == ImportType.IMPORT || import_type == ImportType.PLAYLIST) && main_settings.copy_imported_music) {
            fo_progress(_("<b>Copying</b> files to <b>Music Folder</b>…"), 0.0);
            
            Threads.add (copy_imports_thread);
        }
        else {
            libraries_manager.local_library.music_added(import_type == ImportType.RESCAN ? new LinkedList<string>() : import_errors);
            libraries_manager.local_library.finish_file_operations();
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
            libraries_manager.local_library.music_added(import_errors);
            libraries_manager.local_library.finish_file_operations();
            
            return false;
        });
    }
}
