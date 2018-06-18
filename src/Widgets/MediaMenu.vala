/*-
 * Copyright (c) 2018 elementary LLC. (https://elementary.io)
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
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 */

public class Noise.MediaMenu : Gtk.Menu {
    private Gee.TreeSet<Media> media { get; construct; }

    public MediaMenu (Gee.TreeSet<Media> media) {
        Object (media: media);
    }

    construct {
        var edit_media = new Gtk.MenuItem.with_label (_("Edit Song Info"));
        edit_media.activate.connect (edit_clicked);

        var file_browse = new Gtk.MenuItem.with_label (_("Show in File Browser"));
        file_browse.activate.connect (file_browse_clicked);

        var contractor_entry = new Gtk.MenuItem.with_label (_("Other Actions"));

        var queue = new Gtk.MenuItem.with_label (C_("Action item (verb)", "Queue"));
        queue.activate.connect (queue_clicked);

        var add_to_playlist = new Gtk.MenuItem.with_label (_("Add to Playlist"));

        var remove = new Gtk.MenuItem.with_label (_("Remove Song"));
        remove.activate.connect (remove_clicked);

        var rate_media = new Granite.Widgets.RatingMenuItem ();
        rate_media.activate.connect (rate_clicked);

        append (edit_media);
        append (file_browse);
        append (contractor_entry);
        append (rate_media);
        append (new Gtk.SeparatorMenuItem ());
        append (queue);
        append (add_to_playlist);
        append (new Gtk.SeparatorMenuItem ());
        append (remove);
    }

    private void edit_clicked () {
        if (media.is_empty) {
            return;
        }

        var first_media = media.first ();
        string music_folder_uri = File.new_for_path (Settings.Main.get_default ().music_folder).get_uri ();
        if (media.size == 1 && !first_media.file.query_exists () && first_media.uri.has_prefix (music_folder_uri)) {
            first_media.unique_status_image = new ThemedIcon ("process-error-symbolic");
            var fnfd = new FileNotFoundDialog (media);
            fnfd.present ();
        } else {
            var se = new MediaEditor (media);
            se.show_all ();
        }
    }

    private void media_file_browse_clicked () {
        foreach (Media m in media) {
            try {
                Gtk.show_uri (null, m.file.get_parent ().get_uri (), Gdk.CURRENT_TIME);
            } catch (Error err) {
                debug ("Could not browse media %s: %s\n", m.uri, err.message);
            }

            return;
        }
    }

    private void media_menu_queue_clicked () {
        App.player.queue_medias (media);
    }

    private void media_menu_new_playlist_clicked () {
        var p = new StaticPlaylist ();
        p.add_medias (media);
        p.name = PlaylistsUtils.get_new_playlist_name (parent_wrapper.library.get_playlists ());
        parent_wrapper.library.add_playlist (p);
    }

    private void media_rate_media_clicked () {
        int new_rating = media_rate_media.rating_value;
        foreach (Media m in media) {
            m.rating = new_rating;
        }
    }

    private void removed_clicked () {
        var dialog = new RemoveFilesDialog (media);
        dialog.remove_media.connect ((delete_files) => {
            App.main_window.library_manager.remove_medias (media, delete_files);
        });
    }
}
