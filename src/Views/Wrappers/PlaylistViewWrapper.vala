// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

public class Noise.PlaylistViewWrapper : ViewWrapper {
    public int playlist_id { get; construct set; default = -1; }
    public TreeViewSetup tvs;
    public signal void button_clicked (int playlist_id);

    public PlaylistViewWrapper (int playlist_id, ViewWrapper.Hint hint, TreeViewSetup? tvs = null, Library library) {
        base (hint, library);
        if (tvs == null)
            this.tvs = new TreeViewSetup(ListColumn.NUMBER, Gtk.SortType.ASCENDING, hint);
        else
            this.tvs = tvs;

        this.playlist_id = playlist_id;
        relative_id = playlist_id;

        build_async.begin ();
    }

    private async void build_async () {
        Idle.add_full (VIEW_CONSTRUCT_PRIORITY, build_async.callback);
        yield;

        list_view = new ListView (this, tvs);
        embedded_alert = new Granite.Widgets.EmbeddedAlert ();

        // Refresh view layout
        pack_views ();

        // Do initial population. Further additions and removals will be handled
        // by the handlers connected below through connect_data_signals()
        if (hint == Hint.SMART_PLAYLIST) {
            // this sets the media indirectly through the signal handlers connected above
            yield set_media_async (library.smart_playlist_from_id (playlist_id).medias);
        } else if (hint == Hint.PLAYLIST) {
            yield set_media_async (library.playlist_from_id (playlist_id).medias);
        } else {
            assert_not_reached ();
        }

        connect_data_signals ();
    }

    private void connect_data_signals () {
        switch (hint) {
            case Hint.PLAYLIST:
                var p = library.playlist_from_id (playlist_id);

                // Connect to playlist signals
                if (p != null) {
                    p.media_added.connect (on_playlist_media_added);
                    p.media_removed.connect (on_playlist_media_removed);
                    p.cleared.connect (on_playlist_cleared);
                    p.request_play.connect (() => {App.player.clearCurrent(); play_first_media (true);App.player.getNext(true);});
                }
            break;
            
            case Hint.SMART_PLAYLIST:
                var p = library.smart_playlist_from_id (playlist_id);

                // Connect to smart playlist signals
                if (p != null) {
                    p.media_added.connect (on_playlist_media_added);
                    p.media_removed.connect (on_playlist_media_removed);
                    p.cleared.connect (on_playlist_cleared);
                    p.request_play.connect (() => {App.player.clearCurrent(); play_first_media (true);App.player.getNext(true);});
                }
            break;
            
            default:
                assert_not_reached ();
        }
    }

    protected override void set_no_media_alert () {
        // show alert if there's no media
        assert (has_embedded_alert);

        if (hint == Hint.PLAYLIST) {
            embedded_alert.set_alert (_("No Songs"), _("To add songs to this playlist, use the <b>secondary click</b> on an item and choose <b>Add to Playlist</b>."), null, true, Gtk.MessageType.INFO);
        } else if (hint == Hint.SMART_PLAYLIST) {
            var action = new Gtk.Action ("smart-playlist-rules-edit",
                                         _("Edit Smart Playlist"),
                                         null,
                                         null);
            // Connect to the 'activate' signal
            action.activate.connect ( () => {
                button_clicked (playlist_id);
                //lw.sideTree.playlistMenuEditClicked (); // Show this playlist's edit dialog
            });

            var actions = new Gtk.Action[1];
            actions[0] = action;

            embedded_alert.set_alert (_("No Songs"), _("This playlist will be automatically populated with songs that match its rules. To modify these rules, use the <b>secondary click</b> on it in the sidebar and click on <b>Edit</b>. Optionally, you can click on the button below."), actions, true, Gtk.MessageType.INFO);
        }
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

