/*
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
    public bool can_scroll_to_current { get; construct; }
    public ViewWrapper.Hint hint { get; construct ;}
    public GenericList generic_list { get; construct; }
    public Gtk.MenuItem contractor_entry;

    private Gtk.MenuItem edit_media;

    public MediaMenu (GenericList generic_list, bool can_scroll_to_current, ViewWrapper.Hint hint) {
        Object (
            can_scroll_to_current: can_scroll_to_current,
            generic_list: generic_list,
            hint: hint
        );
    }

    construct {
        var scroll_to_current = new Gtk.MenuItem.with_label (_("Scroll to Current Song"));
        scroll_to_current.sensitive = false;

        edit_media = new Gtk.MenuItem.with_label (_("Edit Song Info…"));
        var file_browse = new Gtk.MenuItem.with_label (_("Show in File Browser…"));
        contractor_entry = new Gtk.MenuItem.with_label (_("Other Actions"));

        if (can_scroll_to_current) {
            append (scroll_to_current);
            append (new Gtk.SeparatorMenuItem ());
        }

        var read_only = hint == ViewWrapper.Hint.READ_ONLY_PLAYLIST;
        if (read_only == false) {
            append (edit_media);
        }

        append (file_browse);
        append (contractor_entry);

        edit_media.activate.connect (edit_media_clicked);
        file_browse.activate.connect (file_browse_clicked);

        scroll_to_current.activate.connect (() => {
            generic_list.scroll_to_current_media (true);
        });

        App.player.playback_stopped.connect (() => {
            scroll_to_current.sensitive = false;
        });

        App.player.playback_started.connect (() => {
            scroll_to_current.sensitive = true;
        });
    }

    private void edit_media_clicked () {
        var to_edit_med = new Gee.TreeSet<Media> ();
        to_edit_med.add_all (generic_list.get_selected_medias ());

        if (to_edit_med.is_empty) {
            return;
        }

        var first_media = to_edit_med.first ();
        string music_folder_uri = File.new_for_path (Settings.Main.get_default ().music_folder).get_uri ();
        if (to_edit_med.size == 1 && !first_media.file.query_exists () && first_media.uri.has_prefix (music_folder_uri)) {
            first_media.unique_status_image = new ThemedIcon ("process-error-symbolic");
            var fnfd = new FileNotFoundDialog (to_edit_med);
            fnfd.present ();
        } else {
            var media_editor = new MediaEditor (to_edit_med);
            media_editor.show_all ();
        }
    }

    private void file_browse_clicked () {
        foreach (Media media in generic_list.get_selected_medias ()) {
            try {
                Gtk.show_uri (null, media.file.get_parent ().get_uri (), Gdk.CURRENT_TIME);
            } catch (Error err) {
                debug ("Could not browse media %s: %s\n", media.uri, err.message);
            }

            return;
        }
    }

    public void update_sensitivities () {
        switch (hint) {
            case ViewWrapper.Hint.DEVICE_AUDIO:
                edit_media.visible = false;
                break;
            default:
                break;
        }
    }
}
