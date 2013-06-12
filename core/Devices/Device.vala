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


public interface Noise.Device : GLib.Object {
    public signal void initialized (Device d);
    public signal void device_unmounted ();
    public signal void infobar_message (string message, Gtk.MessageType type);
    
    public abstract DevicePreferences get_preferences();
    public abstract bool start_initialization();
    public abstract void finish_initialization();
    public abstract string getContentType();
    public abstract string getDisplayName();
    public abstract string getEmptyDeviceTitle();
    public abstract string getEmptyDeviceDescription();
    public abstract void setDisplayName(string name);
    public abstract string get_fancy_description();
    public abstract void set_mount(Mount mount);
    public abstract Mount? get_mount();
    public abstract string get_uri();
    public abstract void set_icon(GLib.Icon icon);
    public abstract GLib.Icon get_icon();
    public abstract uint64 get_capacity();
    public abstract string get_fancy_capacity();
    public abstract uint64 get_used_space();
    public abstract uint64 get_free_space();
    public abstract void unmount();
    public abstract void eject();
    public abstract void synchronize ();
    public abstract bool only_use_custom_view ();
    public abstract Gtk.Widget? get_custom_view (); // If it's null, use the standard device view
    public abstract bool read_only ();
    public abstract Library get_library ();
    
    public Gee.Collection<Noise.Media> delete_doubles (Gee.Collection<Noise.Media> source_list, Gee.Collection<Noise.Media> to_remove) {
        var new_list = new Gee.LinkedList<Noise.Media> ();
        foreach(var m in source_list) {
            if (m != null) {
                bool needed = true;
                foreach(var med in to_remove) {
                    if (med != null && med.title != null) {
                        if (med.album != null && m.album != null) { // If you don't have the album name, don't care of it
                            if(med.title.down() == m.title.down() && med.artist.down() == m.artist.down() && med.album.down() == m.album.down()) {
                                needed = false;
                                break;
                            }
                        } else {
                            if(med.title.down() == m.title.down() && med.artist.down() == m.artist.down()) {
                                needed = false;
                                break;
                            }
                        }
                    }
                }
                if (needed == true)
                    new_list.add (m);
            }
        }
        
        return new_list;
    }
    
    public bool will_fit(Gee.Collection<Noise.Media> list) {
        uint64 list_size = 0;
        foreach(var m in list) {
            list_size += m.file_size;
        }
        
        return get_capacity() > list_size;
    }
    
    public bool will_fit_without(Gee.Collection<Noise.Media> list, Gee.Collection<Noise.Media> without) {
        uint64 list_size = 0;
        uint64 without_size = 0;
        foreach (var m in list) {
            list_size += m.file_size;
        }
        foreach (var m in without) {
            without_size += m.file_size;
        }
        if (without_size > list_size) {
            return true;
        } else {
            return get_capacity () > (list_size - without_size);
        }
    }
    
    public string get_unique_identifier() {
        Mount? m = get_mount();
        if (m != null) {
            string uuid = m.get_uuid();
            File root = m.get_root();
            string rv = "";
            debug ("uuid: %s\n", uuid);
            if(root != null && root.get_uri() != null) {
                rv += root.get_uri();
            }
            if(uuid != null && uuid != "") {
                rv += ("/" + uuid);
            }
            
            return rv;
        } else {
            return get_uri();
        }
    }
}
