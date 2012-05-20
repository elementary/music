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

using Gtk;
using Gee;

/**
 * Used for Playlists and Smart Playlists
 */

public class BeatBox.PlaylistViewWrapper : ViewWrapper {
    public int playlist_id { get; private set; default = -1; }

    public PlaylistViewWrapper (LibraryWindow lw, TreeViewSetup tvs, int playlist_id) {
        var vw_hint = tvs.get_hint ();
        base (lw, vw_hint);

        this.playlist_id = playlist_id;
        relative_id = playlist_id;

        if (vw_hint == Hint.PLAYLIST) {
            var p = lm.playlist_from_id (playlist_id);

            // Connect to playlist signals
            if (p != null) {
                p.media_added.connect (on_playlist_media_added);
                p.media_removed.connect (on_playlist_media_removed);
                p.cleared.connect (on_playlist_cleared);
            }
        }
        else if (vw_hint == Hint.SMART_PLAYLIST) {
            var p = lm.smart_playlist_from_id (playlist_id);

            // Connect to playlist signals
            if (p != null) {
                p.changed.connect (on_smart_playlist_changed);
            }
        }

        // Add album view
        album_view = new AlbumView (this);

        // Add list view
        list_view = new ListView (this, tvs);

        // Alert box
        embedded_alert = new Granite.Widgets.EmbeddedAlert ();            

		// Refresh view layout
		pack_views ();

        set_alert ();
    }

    private void set_alert () {
        // show alert if there's no media
        if (has_embedded_alert) {
            if (hint == Hint.PLAYLIST) {
                embedded_alert.set_alert (_("No Songs"), _("To add songs to this playlist, use the <b>secondary click</b> on an item and choose <b>Add to Playlist</b>."), null, true, Gtk.MessageType.INFO);
            }
            else if (hint == Hint.SMART_PLAYLIST) {
                var action = new Gtk.Action ("smart-playlist-rules-edit",
                                             _("Edit Smart Playlist"),
                                             _("Click on the button to edit playlist rules"),
                                             Gtk.Stock.EDIT);
                // Connect to the 'activate' signal
                action.activate.connect ( () => {
                    lw.sideTree.playlistMenuEditClicked (); // Show this playlist's edit dialog
                });

                var actions = new Gtk.Action[1];
                actions[0] = action;

                embedded_alert.set_alert (_("No Songs"), _("This playlist will be automatically populated with songs that match its rules. To modify these rules, use the <b>secondary click</b> on it in the sidebar and click on <b>Edit</b>. Optionally, you can click on the button below."), actions, true, Gtk.MessageType.INFO);
            }
        }
    }


    /**
     * DATA STUFF
     */

    /* SMART PLAYLISTS */

    private void on_smart_playlist_changed (Gee.Collection<Media> new_media) {
        if (hint != Hint.SMART_PLAYLIST)
            return;

        set_media (new_media);
    }

    /* NORMAL PLAYLISTS */

    private void on_playlist_media_added (Gee.Collection<Media> to_add) {
        if (hint != Hint.PLAYLIST)
            return;

        add_media (to_add);
    }

    private void on_playlist_media_removed (Gee.Collection<Media> to_remove) {
        if (hint != Hint.PLAYLIST)
            return;

        remove_media (to_remove);
    }

    private void on_playlist_cleared () {
         if (hint != Hint.PLAYLIST)
            return;

        set_media (new Gee.LinkedList<Media> ());
    }
}

