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

    public PlaylistViewWrapper (LibraryWindow lw, TreeViewSetup tvs, int playlist_id) {
        base (lw, tvs.get_hint ());
        this.playlist_id = playlist_id;
        relative_id = playlist_id;

        if (hint == Hint.PLAYLIST) {
            var p = lm.playlist_from_id (playlist_id);

            // Connect to playlist signals
            if (p != null) {
                p.media_added.connect (on_playlist_media_added);
                p.media_removed.connect (on_playlist_media_removed);
                p.cleared.connect (on_playlist_cleared);
            }
        }
        else if (hint == Hint.SMART_PLAYLIST) {
            var p = lm.smart_playlist_from_id (playlist_id);

            // Connect to playlist signals
            if (p != null) {
                p.changed.connect (on_smart_playlist_changed);
            }
        }
        else {
            return_if_reached ();
        }

        build_async (tvs);

        if (hint == Hint.SMART_PLAYLIST) {
            // this sets the media indirectly through the signal handlers connected above
            lm.media_from_smart_playlist (playlist_id);
        }
        else if (hint == Hint.PLAYLIST) {
            set_media_async (lm.media_from_playlist (playlist_id));
        }
        else {
            assert_not_reached ();
        }
    }

    private async void build_async (TreeViewSetup tvs) {
        Idle.add_full (VIEW_CONSTRUCT_PRIORITY, build_async.callback);
        yield;

        grid_view = new GridView (this);
        list_view = new ListView (this, tvs);
        embedded_alert = new Granite.Widgets.EmbeddedAlert ();            

		// Refresh view layout
		pack_views ();
    }

    protected override void set_no_media_alert () {
        // show alert if there's no media
        assert (has_embedded_alert);

        if (hint == Hint.PLAYLIST) {
            embedded_alert.set_alert (_("No Songs"), _("To add songs to this playlist, use the <b>secondary click</b> on an item and choose <b>Add to Playlist</b>."), null, true, Gtk.MessageType.INFO);
        }
        else if (hint == Hint.SMART_PLAYLIST) {
            var action = new Gtk.Action ("smart-playlist-rules-edit",
                                         _("Edit Smart Playlist"),
                                         null,
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


    /**
     * DATA STUFF
     */

    /* SMART PLAYLISTS */

    private async void on_smart_playlist_changed (Gee.Collection<Media> new_media) {
        return_if_fail (hint == Hint.SMART_PLAYLIST);

  	    var to_add = new Gee.LinkedList<Media> ();
        var to_remove = new Gee.LinkedList<Media> ();
        var new_media_table = new Gee.HashMap<Media, int> ();

       	foreach (var m in new_media) {
   	    	// if not already in the table, add
   	    	if (!media_table.has_key (m))
                to_add.add (m);
            // Make a copy of the list
            new_media_table.set (m, 1);
         }

         // if something is in the table but not in new_media, remove
         foreach (var m in get_media_list ()) {
             if (!new_media_table.has_key (m))
                 to_remove.add (m);
         }

       	 remove_media_async (to_remove);
       	 add_media_async (to_add);
    }

    /* NORMAL PLAYLISTS */

    private void on_playlist_media_added (Gee.Collection<Media> to_add) {
        return_if_fail (hint == Hint.PLAYLIST);
        add_media_async (to_add);
    }

    private void on_playlist_media_removed (Gee.Collection<Media> to_remove) {
        return_if_fail (hint == Hint.PLAYLIST);
        remove_media_async (to_remove);
    }

    private void on_playlist_cleared () {
        return_if_fail (hint != Hint.PLAYLIST);
        set_media_async (new Gee.LinkedList<Media> ());
    }
}

