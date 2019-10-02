// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * The Music authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Music. This permission is above and beyond the permissions granted
 * by the GPL license by which Music is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Corentin Noël <corentin@elementary.io>
 */


public interface Music.Device : GLib.Object {
    public signal void initialized (Device d);
    public signal void device_unmounted ();
    public signal void infobar_message (string label, Gtk.MessageType message_type);

    public abstract bool start_initialization ();
    public abstract void finish_initialization ();
    public abstract string get_content_type ();
    public abstract string get_display_name ();
    public abstract string get_empty_device_title ();
    public abstract string get_empty_device_description ();
    public abstract void set_display_name (string name);
    public abstract string get_fancy_description ();
    public abstract void set_mount (Mount mount);
    public abstract Mount? get_mount ();
    public abstract string get_uri ();
    public abstract void set_icon (GLib.Icon icon);
    public abstract GLib.Icon get_icon ();
    public abstract uint64 get_capacity ();
    public abstract string get_fancy_capacity ();
    public abstract uint64 get_used_space ();
    public abstract uint64 get_free_space ();
    public abstract void unmount ();
    public abstract void eject ();
    public abstract void synchronize ();
    public abstract bool only_use_custom_view ();
    public abstract Gtk.Widget? get_custom_view (); // If it's null, use the standard device view
    public abstract bool read_only ();
    public abstract Library get_library ();

    public Gee.Collection<Music.Media> delete_doubles (Gee.Collection<Music.Media> source_list, Gee.Collection<Music.Media> to_remove) {
        var new_list = new Gee.LinkedList<Music.Media> ();
        foreach (var m in source_list) {
            if (m != null) {
                bool needed = true;
                foreach (var med in to_remove) {
                    if (med != null && med.title != null) {
                        if (med.album != null && m.album != null) { // If you don't have the album name, don't care of it
                            if (med.title.down () == m.title.down () && med.artist.down () == m.artist.down () && med.album.down () == m.album.down ()) {
                                needed = false;
                                break;
                            }
                        } else {
                            if (med.title.down () == m.title.down () && med.artist.down () == m.artist.down ()) {
                                needed = false;
                                break;
                            }
                        }
                    }
                }
                if (needed == true) {
                    new_list.add (m);
                }
            }
        }

        return new_list;
    }

    public bool will_fit (Gee.Collection<Music.Media> list) {
        uint64 list_size = 0;
        foreach (var m in list) {
            list_size += m.file_size;
        }

        return get_capacity () > list_size;
    }

    public virtual string get_unique_identifier () {
        Mount? m = get_mount ();
        if (m != null) {
            string uuid = m.get_uuid ();
            File root = m.get_root ();
            string rv = "";
            debug ("uuid: %s\n", uuid);
            if (root != null && root.get_uri () != null) {
                rv += root.get_uri ();
            }
            if (uuid != null && uuid != "") {
                rv += ("/" + uuid);
            }

            return rv;
        } else {
            return get_uri ();
        }
    }
}
