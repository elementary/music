// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2017 elementary LLC. (https://elementary.io)
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
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Noise.Plugins.CDViewWrapper : ViewWrapper {
    public TreeViewSetup tvs;
    private string message_head;
    private string message_body;

    public CDViewWrapper (Noise.StaticPlaylist p) {
        base (ViewWrapper.Hint.READ_ONLY_PLAYLIST, libraries_manager.local_library);
        tvs = new TreeViewSetup (ViewWrapper.Hint.PLAYLIST);
        message_head = _("An Error Occured");
        message_body = _("There was an error while loading this Audio CD.");

        build_async.begin (p);
        p.media_added.connect (on_playlist_media_added);
        p.media_removed.connect (on_playlist_media_removed);
        p.cleared.connect (on_playlist_cleared);
        hexpand = true;
        vexpand = false;
    }

    private async void build_async (Noise.StaticPlaylist p) {
        Idle.add_full (VIEW_CONSTRUCT_PRIORITY, build_async.callback);
        yield;

        list_view = new ListView (this, tvs, false);
        embedded_alert = new Granite.Widgets.AlertView ("", "", "");

        // Refresh view layout
        pack_views ();

        // Do initial population. Further additions and removals will be handled
        // by the handlers connected below through connect_data_signals()
        yield set_media_async (p.medias);

    }

    public void set_no_media_alert_message (string head, string body) {
        message_head = head;
        message_body = body;
    }

    protected override void set_no_media_alert () {
        // show alert if there's no media
        assert (has_embedded_alert);

        embedded_alert.icon_name = "dialog-error";
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
        yield set_media_async (new Gee.LinkedList<Media> ());
    }
}

