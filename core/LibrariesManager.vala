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
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

public class Noise.LibrariesManager : GLib.Object {
    
    public signal void library_removed (Library library);
    public signal void library_added (Library library);
    
    public signal void cancel_transfer ();
    public signal void operation_terminated ();
    
    public double progress;
    public string current_operation;
    private string old_search = null;
    
    private Gee.HashMap<Library, int> libraries;
    private int current_index = 0;
    public Library local_library;
    
    public LibrariesManager () {
        libraries = new Gee.HashMap<Library, int> ();
    }
    
    public void add_library (Library library) {
        if (!libraries.keys.contains (library)) {
            libraries.set (library, current_index);
            library_added (library);
        }
    }
    
    public void remove_library (Library library) {
        if (libraries.keys.contains (library)) {
            library_removed (library);
            libraries.unset (library);
        }
    }
    
    public Library? get_library_from_index (int index) {
        foreach (var entry in libraries.entries) {
            if (entry.value == index)
                return entry.key;
        }
        return null;
    }
    
    public void search_for_string (string search) {
        if (old_search == search)
            return;
        old_search = search;
        foreach (var library in libraries.keys) {
            library.search_medias (search);
        }
    }
    
    public void transfer_to_local_library (Gee.Collection<Media> to_transfer) {
        if (local_library == null)
            return;
        if(to_transfer == null || to_transfer.size == 0) {
            warning("No songs in transfer list\n");
            return;
        }
        
        debug ("Found %d medias to import.", to_transfer.size);
        
        transfer_medias_async.begin (to_transfer);
        return;
    }
    
    public async void transfer_medias_async (Gee.Collection<Noise.Media> list) {
        if(list == null || list.size == 0)
            return;
        
        int index = 0;
        
        progress = 0;
        Timeout.add(500, do_progress_notification_with_timeout);
        
        int total = list.size;
        var copied_list = new Gee.TreeSet<Media> ();
        
        foreach(var m in list) {
            
            if(File.new_for_uri(m.uri).query_exists()) {
                try {
                    File dest = FileUtils.get_new_destination(m);
                    if(dest == null)
                        break;
                    
                    /* copy the file over */
                    bool success = false;
                    success = m.file.copy (dest, FileCopyFlags.NONE, null, null);
                    
                    if(success) {
                        Noise.Media copy = m.copy();
                        debug("success copying file\n");
                        copy.uri = dest.get_uri();
                        copy.rowid = 0;
                        copy.isTemporary = false;
                        copy.date_added = (int)time_t();
                        copied_list.add (copy);
                    }
                    else {
                        warning("Failure: Could not copy imported media %s to media folder %s", m.uri, dest.get_path());
                        break;
                    }
                }
                catch(Error err) {
                    warning("Could not copy imported media %s to media folder: %s\n", m.uri, err.message);
                    break;
                }
                
                current_operation = _("Importing <b>$NAME</b> by <b>$ARTIST</b> to library…");
                current_operation = current_operation.replace ("$NAME", m.get_display_title ());
                current_operation = current_operation.replace ("$ARTIST", m.get_display_artist ());
            } else {
                message ("Skipped transferring media %s. Either already in library, or has invalid file path.\n", m.get_display_title ());
            }
            index++;
            progress = (double)index/total;
        }
        
        progress = 1;
        
        Idle.add( () => {
            local_library.add_medias (copied_list);
            return false;
        });
    }
    
    public bool do_progress_notification_with_timeout () {
        
        NotificationManager.get_default ().update_progress (current_operation.replace("&", "&amp;"), progress);
        
        if (progress < 1) {
            return true;
        }
        
        return false;
    }
}
