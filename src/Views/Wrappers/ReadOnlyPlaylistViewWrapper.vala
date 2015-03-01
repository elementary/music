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
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

public class Noise.ReadOnlyPlaylistViewWrapper : ViewWrapper {
    public int playlist_id { get; construct set; default = -1; }
    public TreeViewSetup tvs;
    private string message_head;
    private string message_body;
    private Gtk.MessageType message_type;
    public bool is_queue;

    public ReadOnlyPlaylistViewWrapper (int playlist_id, TreeViewSetup? tvs = null, bool? is_queue = false, Library library) {
        base (ViewWrapper.Hint.READ_ONLY_PLAYLIST, library);
        if (tvs == null)
            this.tvs = new TreeViewSetup(ListColumn.NUMBER, Gtk.SortType.ASCENDING, ViewWrapper.Hint.READ_ONLY_PLAYLIST);
        else
            this.tvs = tvs;
        
        this.is_queue = is_queue;
        message_head = _("No Songs");
        message_body = _("Updating playlist. Please wait.");
        message_type = Gtk.MessageType.INFO;

        this.playlist_id = playlist_id;
        relative_id = playlist_id;

        build_async.begin ();
    }

    private async void build_async () {
        Idle.add_full (VIEW_CONSTRUCT_PRIORITY, build_async.callback);
        yield;

        list_view = new ListView (this, tvs, false, this.is_queue);
        embedded_alert = new Granite.Widgets.EmbeddedAlert ();

        // Refresh view layout
        pack_views ();

        // Do initial population. Further additions and removals will be handled
        // by the handlers connected below through connect_data_signals()
        yield set_media_async (library.playlist_from_id (playlist_id).medias);

        connect_data_signals ();
    }

    private void connect_data_signals () {
        // Connect to playlist signals
        var p = library.playlist_from_id (playlist_id);
        if (p != null) {
            p.media_added.connect (add_media_async);
            p.media_removed.connect (remove_media_async);
            p.cleared.connect (on_playlist_cleared);
            p.request_play.connect (() => {App.player.clearCurrent(); play_first_media (true);App.player.getNext(true);});
        }
    }

    public void set_no_media_alert_message (string head, string body, Gtk.MessageType? type = Gtk.MessageType.INFO) {
        message_head = head;
        message_body = body;
        message_type = type;
    }

    protected override void set_no_media_alert () {
        // show alert if there's no media
        assert (has_embedded_alert);

        embedded_alert.set_alert (message_head, message_body, null, true, message_type);
    }

    private async void on_playlist_cleared () {
        yield set_media_async (new Gee.ArrayQueue<Media> ());
    }
}
