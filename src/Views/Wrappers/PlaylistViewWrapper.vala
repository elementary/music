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
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

public class Music.PlaylistViewWrapper : ViewWrapper {
    public TreeViewSetup tvs { get; construct set; }
    public signal void button_clicked (Playlist p);
    private string message_head;
    private string message_body;

    public PlaylistViewWrapper (Playlist playlist, ViewWrapper.Hint hint, TreeViewSetup tvs, Library library) {
        Object (tvs: tvs, playlist: playlist, hint: hint, library: library);
    }

    construct {
        list_view = new ListView (this, tvs);
        embedded_alert = new Granite.Widgets.AlertView ("", "", "");

        // Refresh view layout
        pack_views ();

        // Do initial population. Further additions and removals will be handled
        // by the handlers connected below through connect_data_signals()
        switch (hint) {
            case Hint.READ_ONLY_PLAYLIST:
                message_head = _("No Songs");
                message_body = _("Updating playlist. Please wait.");
                break;
            case Hint.PLAYLIST:
                message_head = _("No Songs");
                message_body = _("To add songs to this playlist, use the <b>secondary click</b> on an item and choose <b>Add to Playlist</b>.");
                break;
            case Hint.SMART_PLAYLIST:
                embedded_alert.show_action (_("Edit Smart Playlist"));

                embedded_alert.action_activated.connect (() => {
                    button_clicked (playlist);
                });

                message_head = _("No Songs");
                message_body = _("This playlist will be automatically populated with songs that match its rules. To modify these rules, use the <b>secondary click</b> on it in the sidebar and click on <b>Edit</b>. Optionally, you can click on the button below.");
                break;
            case Hint.NONE:
                debug ("Hint = NONE");
                break;
            default:
                assert_not_reached ();
        }

        set_media_async.begin (playlist.medias);
        connect_data_signals ();
    }

    private void connect_data_signals () {
        switch (hint) {
            case Hint.READ_ONLY_PLAYLIST:
            case Hint.PLAYLIST:
            case Hint.SMART_PLAYLIST:
                var p = (Playlist) playlist;

                // Connect to playlist signals
                if (p != null) {
                    p.media_added.connect (on_playlist_media_added);
                    p.media_removed.connect (on_playlist_media_removed);
                    p.cleared.connect (on_playlist_cleared);
                    p.request_play.connect (() => {
                        App.player.clear_queue ();
                        play_first_media (true);
                        App.player.get_next (true);
                    });
                }
                break;
            default:
                assert_not_reached ();
        }
    }

    public void set_no_media_alert_message (string head, string body) {
        message_head = head;
        message_body = body;
    }

    protected override void set_no_media_alert () {
        // show alert if there's no media
        assert (has_embedded_alert);

        embedded_alert.icon_name = "dialog-information";
        embedded_alert.title = message_head;
        embedded_alert.description = message_body;
    }

    private async void on_playlist_media_added (Gee.Collection<Media> to_add) {
        yield add_media_async (to_add);
    }

    private async void on_playlist_media_removed (Gee.Collection<Media> to_remove) {
        yield remove_media_async (to_remove);
    }

    private async void on_playlist_cleared () {
        yield set_media_async (new Gee.ArrayQueue<Media> ());
    }
}
