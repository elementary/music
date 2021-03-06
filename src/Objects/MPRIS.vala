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
 */

namespace Music.MPRIS {
    public void initialize () {
        var owner_id = Bus.own_name (BusType.SESSION,
                                "org.mpris.MediaPlayer2.io.elementary.music",
                                GLib.BusNameOwnerFlags.NONE,
                                on_bus_acquired,
                                null,
                                null);

        if (owner_id == 0) {
            warning ("Could not initialize MPRIS session.\n");
        }
    }

    private void on_bus_acquired (DBusConnection connection, string name) {
        try {
            connection.register_object ("/org/mpris/MediaPlayer2", new MprisRoot ());
            connection.register_object ("/org/mpris/MediaPlayer2", new MprisPlayer (connection));
            // Uncomment this when the bug on the playlist selection is fixed
            // connection.register_object ("/org/mpris/MediaPlayer2", new MprisPlaylists (connection));
        } catch (IOError e) {
            warning ("could not create MPRIS player: %s\n", e.message);
        }
    }
}

[DBus (name = "org.mpris.MediaPlayer2")]
public class MprisRoot : GLib.Object {
    public bool can_quit {
        get {
            return true;
        }
    }

    public bool can_raise {
        get {
            return true;
        }
    }

    public bool has_track_list {
        get {
            return false;
        }
    }
    public string desktop_entry {
        owned get {
            return ((Gtk.Application) GLib.Application.get_default ()).application_id;
        }
    }

    public string identity {
        owned get {
            return Build.EXEC_NAME;
        }
    }

    public string[] supported_uri_schemes {
        owned get {
            return {"http", "file", "https", "ftp"};
        }
    }

    public string[] supported_mime_types {
        owned get {
            return Music.MEDIA_CONTENT_TYPES;
        }
    }

    public void quit () throws GLib.Error {
        Music.App.main_window.destroy ();
    }

    public void raise () throws GLib.Error {
        Music.App.main_window.present ();
    }
}

[DBus (name = "org.mpris.MediaPlayer2.Player")]
public class MprisPlayer : GLib.Object {
    [DBus (visible = false)]
    public unowned DBusConnection conn { get; construct set; }

    private const string INTERFACE_NAME = "org.mpris.MediaPlayer2.Player";
    private uint send_property_source = 0;
    private uint update_metadata_source = 0;
    private HashTable<string,Variant> changed_properties = null;
    private HashTable<string,Variant> _metadata;
    private string default_image_url;

    private enum Direction {
        NEXT = 0,
        PREVIOUS,
        STOP
    }

    public MprisPlayer (DBusConnection conn) {
        Object (conn: conn);
    }

    construct {
        _metadata = new HashTable<string, Variant> (str_hash, str_equal);

        Music.App.player.media_played.connect_after (on_media_played);
        Music.App.player.playback_stopped.connect_after (() => { update_metadata (null); });

        Music.libraries_manager.local_library.media_updated.connect_after (refresh_current_media);
        Music.App.main_window.play_pause_changed.connect_after (playing_changed);

        var default_image = new Music.Icon ("albumart_2").get_file ();
        default_image_url = default_image != null ? default_image.get_uri () : "";

        // initial update
        refresh_current_media ();
    }

    private void refresh_current_media () {
        var current_media = Music.App.player.current_media;
        if (current_media != null) {
            on_media_played (current_media);
        }
    }

    private void playing_changed () {
        trigger_metadata_update ();
    }

    private void trigger_metadata_update () {
        if (update_metadata_source != 0) {
            Source.remove (update_metadata_source);
        }

        update_metadata_source = Timeout.add (300, () => {
            //print ("trigger_metadata_update %s\n", global.current_artist);
            Variant variant = playback_status;

            queue_property_for_notification ("PlaybackStatus", variant);
            queue_property_for_notification ("Metadata", _metadata);
            update_metadata_source = 0;
            return false;
        });
    }

    private void on_media_played (Music.Media? s) {
        if (s == Music.App.player.current_media) {
            update_metadata (s);
        }
    }

    private void update_metadata (Music.Media? s) {
        if (s == null) {
            _metadata.remove_all ();
        } else {
            set_media_metadata (s);
        }

        trigger_metadata_update ();
    }

    private void set_media_metadata (Music.Media s) {
        _metadata = new HashTable<string, Variant> (null, null);

        _metadata.insert ("mpris:trackid", get_track_id (s));
        _metadata.insert ("mpris:length", Music.App.player.player.get_duration () / Music.TimeUtils.MILI_INV);

        var art_file = s.album_info.get_cached_cover_file ();
        _metadata.insert ("mpris:artUrl", art_file != null ? art_file.get_uri () : default_image_url);
        _metadata.insert ("xesam:trackNumber", (int) s.track);
        _metadata.insert ("xesam:title", s.get_display_title ());
        _metadata.insert ("xesam:album", s.get_display_album ());
        _metadata.insert ("xesam:artist", get_simple_string_array (s.get_display_artist ()));
        _metadata.insert ("xesam:albumArtist", get_simple_string_array (s.get_display_album_artist ()));
        _metadata.insert ("xesam:genre", get_simple_string_array (s.get_display_genre ()));
        _metadata.insert ("xesam:asText", s.lyrics);
        _metadata.insert ("xesam:comment", get_simple_string_array (s.comment));
        _metadata.insert ("xesam:composer", get_simple_string_array (s.get_display_composer ()));
        _metadata.insert ("xesam:url", s.uri);
        _metadata.insert ("xesam:discNumber", (int) s.album_number);
        _metadata.insert ("xesam:userRating", (int) s.rating);
        _metadata.insert ("xesam:useCount", (int) s.play_count);
    }

    private static string[] get_simple_string_array (string? text) {
        if (text == null) {
            return new string[0];
        }
        string[] array = new string[0];
        array += text;
        return array;
    }

    private ObjectPath get_track_id (Music.Media m) {
        return new ObjectPath ("/io/elementary/music/Track/%lld".printf (m.rowid));
    }

    private bool send_property_change () {
        if (changed_properties == null) {
            return false;
        }

        var builder = new VariantBuilder (VariantType.ARRAY);
        var invalidated_builder = new VariantBuilder (new VariantType ("as"));

        foreach (string name in changed_properties.get_keys ()) {
            Variant variant = changed_properties.lookup (name);
            builder.add ("{sv}", name, variant);
        }

        changed_properties = null;

        try {
            conn.emit_signal (null,
                              "/org/mpris/MediaPlayer2",
                              "org.freedesktop.DBus.Properties",
                              "PropertiesChanged",
                              new Variant ("(sa{sv}as)",
                                         INTERFACE_NAME,
                                         builder,
                                         invalidated_builder)
                             );
        } catch (Error e) {
            print ("Could not send MPRIS property change: %s\n", e.message);
        }
        send_property_source = 0;
        return false;
    }

    private void queue_property_for_notification (string property, Variant val) {
        // putting the properties into a hashtable works as akind of event compression

        if (changed_properties == null) {
            changed_properties = new HashTable<string, Variant> (str_hash, str_equal);
        }

        changed_properties.insert (property, val);

        if (send_property_source == 0) {
            send_property_source = Idle.add (send_property_change);
        }
    }

    public string playback_status {
        owned get { //TODO signal org.freedesktop.DBus.Properties.PropertiesChanged
            if (Music.App.player.playing) {
                return "Playing";
            } else if (!Music.App.player.playing && Music.App.player.current_media == null) {
                return "Stopped";
            } else if (!Music.App.player.playing) {
                return "Paused";
            } else {
                return "Stopped";
            }
        }
    }

    public string loop_status {
        owned get {
            switch (Music.App.settings.get_enum ("repeat-mode")) {
                case (Music.PlaybackManager.RepeatMode.OFF):
                    return "None";
                case (Music.PlaybackManager.RepeatMode.MEDIA):
                    return "Track";
                case (Music.PlaybackManager.RepeatMode.ALBUM):
                case (Music.PlaybackManager.RepeatMode.ARTIST):
                case (Music.PlaybackManager.RepeatMode.ALL):
                default:
                    return "Playlist";
            }
        }
        set {
            switch (value) {
                case ("None"):
                    Music.App.player.set_repeat_mode (Music.PlaybackManager.RepeatMode.OFF);
                    break;
                case ("Track"):
                    Music.App.player.set_repeat_mode (Music.PlaybackManager.RepeatMode.MEDIA);
                    break;
                case ("Playlist"):
                    Music.App.player.set_repeat_mode (Music.PlaybackManager.RepeatMode.ALL);
                    break;
                default:
                    Music.App.player.set_repeat_mode (Music.PlaybackManager.RepeatMode.ALL);
                    break;
            }

            Variant variant = value;
            queue_property_for_notification ("LoopStatus", variant);
        }
    }

    public double rate {
        get {
            return 1.0;
        }
        set {}
    }

    public bool shuffle {
        get {
            return Music.App.settings.get_enum ("shuffle-mode") == Music.PlaybackManager.ShuffleMode.ALL;
        }
        set {
            if (value) {
                Music.App.player.set_shuffle_mode (Music.PlaybackManager.ShuffleMode.ALL);
            } else {
                Music.App.player.set_shuffle_mode (Music.PlaybackManager.ShuffleMode.OFF);
            }

            Variant variant = value;
            queue_property_for_notification ("Shuffle", variant);
        }
    }

    public HashTable<string, Variant>? metadata { //a{sv}
        owned get {
            update_metadata (Music.App.player.current_media);
            return _metadata;
        }
    }

    public double volume {
        get {
            return Music.App.player.volume;
        }
        set {
            Music.App.player.volume = value;
        }
    }

    public int64 position {
        get {
            return (Music.App.player.player.get_position () / (int64)Music.TimeUtils.MILI_INV);
        }
    }

    public bool can_go_next {
        get {
            return true;
        }
    }

    public bool can_go_previous {
        get {
            return true;
        }
    }

    public bool can_play {
        get {
            return true;
        }
    }

    public bool can_pause {
        get {
            return true;
        }
    }

    public bool can_seek {
        get {
            return true;
        }
    }

    public bool can_control {
        get {
            return true;
        }
    }

    public signal void seeked (int64 position);

    public void next () throws GLib.Error {
        // inhibit notifications
        Music.App.main_window.play_next_media (true);
    }

    public void previous () throws GLib.Error {
        // inhibit notifications
        Music.App.main_window.play_previous_media (true);
    }

    public void pause () throws GLib.Error {
        // inhibit notifications
        if (Music.App.player.playing) {
            Music.App.player.pause_playback ();
        }
    }

    public void play_pause () throws GLib.Error {
        // inhibit notifications
        Music.App.main_window.play_media (true);
    }

    public void stop () throws GLib.Error {
        if (Music.App.player.playing) {
            Music.App.player.stop_playback ();
        }
    }

    public void play () throws GLib.Error {
        // inhibit notifications
        if (!Music.App.player.playing) {
            Music.App.player.start_playback ();
        }
    }

    public void seek (int64 offset) throws GLib.Error {
        int64 position = this.position + offset;
        if (position < 0) {
            position = 0;
        }

        if (position < Music.App.player.player.get_duration () / Music.TimeUtils.MILI_INV) {
            set_position ("", position);
            seeked (position);
        } else if (can_go_next) {
            next ();
        }
    }

    public void set_position (string dobj, int64 position) throws GLib.Error {
        Music.App.player.player.set_position (position * (int64)Music.TimeUtils.MILI_INV);
    }

    public void open_uri (string uri) throws GLib.Error {
        // TODO
    }
}

[DBus (name = "org.mpris.MediaPlayer2.Playlists")]
public class MprisPlaylists : GLib.Object {
    public struct MprisPlaylist {
        ObjectPath id;
        string name;
        string icon;
    }

    public struct MaybePlaylist {
        bool valid;
        MprisPlaylist playlist;
    }

    [DBus (visible = false)]
    public unowned DBusConnection conn { get; construct set; }
    private const string INTERFACE_NAME = "org.mpris.MediaPlayer2.Playlists";
    const string PLAYLIST_ID = "/io/elementary/music/Playlists/%d";

    private uint send_property_source = 0;
    private HashTable<string,Variant> changed_properties = null;

    public MprisPlaylists (DBusConnection conn) {
        Object (conn: conn);
    }

    construct {
        Music.libraries_manager.local_library.playlist_added.connect (playlist_added);
        Music.libraries_manager.local_library.playlist_removed.connect (playlist_removed);
    }

    void playlist_added (Music.Playlist p) {
        Variant variant = this.playlist_count;
        queue_property_for_notification ("PlaylistCount", variant);
    }

    void playlist_removed (Music.Playlist p) {
        Variant variant = this.playlist_count;
        queue_property_for_notification ("PlaylistCount", variant);
    }

    private void queue_property_for_notification (string property, Variant val) {
        // putting the properties into a hashtable works as akind of event compression
        if (changed_properties == null) {
            changed_properties = new HashTable<string,Variant> (str_hash, str_equal);
        }

        changed_properties.insert (property, val);

        if (send_property_source == 0) {
            send_property_source = Idle.add (send_property_change);
        }
    }

    // This is same as the Player above
    // FIXME: Put this somewhere that can be used by all
    // All this is used for right now is PlaylistCount property
    private bool send_property_change () {
        if (changed_properties == null) {
            return false;
        }

        var builder = new VariantBuilder (VariantType.ARRAY);
        var invalidated_builder = new VariantBuilder (new VariantType ("as"));

        foreach (string name in changed_properties.get_keys ()) {
            Variant variant = changed_properties.lookup (name);
            builder.add ("{sv}", name, variant);
        }

        changed_properties = null;

        try {
            conn.emit_signal (null,
                             "/org/mpris/MediaPlayer2",
                             "org.freedesktop.DBus.Properties",
                             "PropertiesChanged",
                             new Variant ("(sa{sv}as)",
                                         INTERFACE_NAME,
                                         builder,
                                         invalidated_builder)
                             );
            message ("Sent properties changed signal\n");
        }
        catch (Error e) {
            print ("Could not send MPRIS property change: %s\n", e.message);
        }

        send_property_source = 0;
        return false;
    }

    public void activate_playlist (ObjectPath path) throws GLib.Error {
        string playlist_id = path.replace ("/io/elementary/music/Playlists/", "");

        Music.Playlist p = Music.libraries_manager.local_library.playlist_from_id (int.parse (playlist_id));
        if (p == null) {
            warning ("Selected playlist had invalid path %s and could not be found", path);
            return;
        }
        p.request_play ();
    }

    public MprisPlaylist?[] get_playlists (uint index, uint maxcount, string playlist_ordering, bool reversed) throws GLib.Error {
        debug ("Get Playlist called with index %u and maxcount %u\n", index, maxcount);
        var playlists = new Gee.LinkedList<Music.Playlist> ();

        foreach (var p in Music.libraries_manager.local_library.get_playlists ()) {
            if (reversed) {
                playlists.offer_tail (p);
            } else {
                playlists.offer_head (p);
            }
        }

        int i = 0;
        var rv = new Gee.LinkedList<MprisPlaylist?> ();
        foreach (Music.Playlist p in playlists) {
            ObjectPath path = new ObjectPath (PLAYLIST_ID.printf (p.rowid));

            MprisPlaylist to_add = MprisPlaylist ();
            to_add.id = path;
            to_add.name = p.name;

            rv.add (to_add);
            debug ("Added playlist %s %s\n", path, p.name);

            if (i >= maxcount) {
                break;
            }
        }

        return rv.to_array ();
    }

    public signal void playlist_changed (Variant playlist);

    public uint playlist_count {
        get {
            return (uint)(Music.libraries_manager.local_library.get_playlists ().size + Music.libraries_manager.local_library.get_smart_playlists ().size);
        }
    }

    private static string[] all_orderings = { "UserDefined" };
    public string[] orderings {
        get {
            return all_orderings;
        }
    }

    public MaybePlaylist active_playlist {
        owned get {
            // FIXME: Should be a real playlist
            Music.Playlist p = null;
            var active_playlist = MaybePlaylist ();

            if (p == null) {
                active_playlist.valid = true; // Set it to true to force that 'Playlist' shows
                MprisPlaylist mpris_p = MprisPlaylist ();
                mpris_p.id = new ObjectPath (PLAYLIST_ID.printf (0));
                mpris_p.name = _ ("Playlists"); // Just a filler, should never show
                mpris_p.icon = "";
                active_playlist.playlist = mpris_p;
            } else {
                active_playlist.valid = true;
                MprisPlaylist mpris_p = MprisPlaylist ();
                mpris_p.id = new ObjectPath (PLAYLIST_ID.printf (p.rowid));
                mpris_p.name = p.name;
                active_playlist.playlist = mpris_p;
            }

            return active_playlist;
        }
    }
}
