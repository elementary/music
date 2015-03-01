/*-Original Authors: Andreas Obergrusberger
 *                   Jörn Magens
 * 
 * Edited by: Scott Ringwelski
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

public class Noise.MPRIS : GLib.Object {
    public MprisPlayer player = null;
    public MprisRoot root = null;
    // Uncomment this when the bug on the playlist selection is fixed
    //public MprisPlaylists playlists = null;
    
    private unowned DBusConnection conn;
    private uint owner_id;
    
    public void initialize () {
        owner_id = Bus.own_name(BusType.SESSION,
                                "org.mpris.MediaPlayer2.Noise",
                                GLib.BusNameOwnerFlags.NONE,
                                on_bus_acquired,
                                on_name_acquired,
                                on_name_lost);

        if(owner_id == 0) {
            warning("Could not initialize MPRIS session.\n");
        }
        else {
            var soundMenu = new SoundMenuIntegration ();
            soundMenu.initialize ();
        }
    }
    
    private void on_bus_acquired (DBusConnection connection, string name) {
        this.conn = connection;
        debug ("bus acquired");
        try {
            root = new MprisRoot ();
            connection.register_object ("/org/mpris/MediaPlayer2", root);
            player = new MprisPlayer (connection);
            connection.register_object ("/org/mpris/MediaPlayer2", player);
            /*playlists = new MprisPlaylists(connection);
            connection.register_object("/org/mpris/MediaPlayer2", playlists);*/
        }
        catch(IOError e) {
            warning("could not create MPRIS player: %s\n", e.message);
        }
    }

    private void on_name_acquired(DBusConnection connection, string name) {
        debug ("name acquired");
    }    

    private void on_name_lost(DBusConnection connection, string name) {
        debug ("name_lost");
    }
}

[DBus(name = "org.mpris.MediaPlayer2")]
public class MprisRoot : GLib.Object {

    public bool CanQuit { 
        get {
            return true;
        } 
    }

    public bool CanRaise { 
        get {
            return true;
        } 
    }
    
    public bool HasTrackList {
        get {
            return false;
        }
    }
    public string DesktopEntry { 
        owned get {
            return "noise";
        } 
    }
    
    public string Identity {
        owned get {
            return ((Noise.App) GLib.Application.get_default ()).get_name ();
        }
    }
    
    public string[] SupportedUriSchemes {
        owned get {
            string[] sa = {"http", "file", "https", "ftp"};
            return sa;
        }
    }
    
    public string[] SupportedMimeTypes {
        owned get {
            return Noise.MEDIA_CONTENT_TYPES;
        }
    }

    public void Quit () {
        Noise.App.main_window.destroy ();
    }
    
    public void Raise () {
        Noise.App.main_window.present ();
    }
}

[DBus(name = "org.mpris.MediaPlayer2.Player")]
public class MprisPlayer : GLib.Object {
    private unowned DBusConnection conn;

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
    
    public MprisPlayer(DBusConnection conn) {
        this.conn = conn;
        _metadata = new HashTable<string,Variant>(str_hash, str_equal);

        Noise.App.player.media_played.connect_after (on_media_played);
        Noise.App.player.playback_stopped.connect_after ( () => update_metadata (null) );

        Noise.libraries_manager.local_library.media_updated.connect_after (refresh_current_media);
        Noise.CoverartCache.instance.changed.connect_after (refresh_current_media);
        Noise.App.main_window.playPauseChanged.connect_after (playing_changed);

        var default_image = Noise.Icons.DEFAULT_ALBUM_ART_2.get_file ();
        default_image_url = default_image != null ? default_image.get_uri () : "";

        // initial update
        refresh_current_media ();
    }

    private void refresh_current_media () {
        var current_media = Noise.App.player.current_media;
        if (current_media != null)
            on_media_played (current_media);
    }

    private void playing_changed() {
        trigger_metadata_update ();
    }
    
    private void trigger_metadata_update() {
        if(update_metadata_source != 0)
            Source.remove(update_metadata_source);

        update_metadata_source = Timeout.add(300, () => {
            //print("trigger_metadata_update %s\n", global.current_artist);
            Variant variant = this.PlaybackStatus;
            
            queue_property_for_notification("PlaybackStatus", variant);
            queue_property_for_notification("Metadata", _metadata);
            update_metadata_source = 0;
            return false;
        });
    }

    private void on_media_played (Noise.Media? s) {
        if (s != Noise.App.player.current_media)
            return;

        update_metadata (s);
    }

    private void update_metadata (Noise.Media? s) {
        if (s == null)
            _metadata.remove_all ();
        else
            set_media_metadata (s);

        trigger_metadata_update ();
    }

    private void set_media_metadata (Noise.Media s) {
        _metadata = new HashTable<string, Variant> (null, null);

        _metadata.insert("mpris:trackid", get_track_id (s));
        _metadata.insert("mpris:length", Noise.App.player.player.get_duration () / Noise.Numeric.MILI_INV);

        var art_file = Noise.CoverartCache.instance.get_cached_image_file (s);
        _metadata.insert("mpris:artUrl", art_file != null ? art_file.get_uri () : default_image_url);
        _metadata.insert("xesam:trackNumber", (int) s.track);
        _metadata.insert("xesam:title", s.get_display_title ());
        _metadata.insert("xesam:album", s.get_display_album ());
        _metadata.insert("xesam:artist", get_simple_string_array (s.get_display_artist ()));
        _metadata.insert("xesam:albumArtist", get_simple_string_array (s.get_display_album_artist ()));
        _metadata.insert("xesam:genre", get_simple_string_array (s.get_display_genre ()));
        _metadata.insert("xesam:asText", s.lyrics);
        _metadata.insert("xesam:comment", get_simple_string_array (s.comment));
        _metadata.insert("xesam:composer", get_simple_string_array (s.get_display_composer ()));
        _metadata.insert("xesam:url", s.uri);
        _metadata.insert("xesam:discNumber", (int) s.album_number);
        _metadata.insert("xesam:userRating", (int) s.rating);
        _metadata.insert("xesam:useCount", (int) s.play_count);
    }

    private static string[] get_simple_string_array (string? text) {
        if (text == null)
            return new string [0];
        string[] array = new string[0];
        array += text;
        return array;
    }

    private ObjectPath get_track_id (Noise.Media m) {
        return new ObjectPath ("/org/pantheon/noise/Track/%d".printf (m.rowid));
    }

    private bool send_property_change() {
        
        if(changed_properties == null)
            return false;
        
        var builder             = new VariantBuilder(VariantType.ARRAY);
        var invalidated_builder = new VariantBuilder(new VariantType("as"));
        
        foreach(string name in changed_properties.get_keys()) {
            Variant variant = changed_properties.lookup(name);
            builder.add("{sv}", name, variant);
        }
        
        changed_properties = null;
        
        try {
            conn.emit_signal (null,
                              "/org/mpris/MediaPlayer2", 
                              "org.freedesktop.DBus.Properties", 
                              "PropertiesChanged", 
                              new Variant("(sa{sv}as)", 
                                         INTERFACE_NAME, 
                                         builder, 
                                         invalidated_builder)
                             );
        }
        catch(Error e) {
            print("Could not send MPRIS property change: %s\n", e.message);
        }
        send_property_source = 0;
        return false;
    }
    
    private void queue_property_for_notification(string property, Variant val) {
        // putting the properties into a hashtable works as akind of event compression
        
        if(changed_properties == null)
            changed_properties = new HashTable<string,Variant>(str_hash, str_equal);
        
        changed_properties.insert(property, val);
        
        if(send_property_source == 0) {
            send_property_source = Idle.add(send_property_change);
        }
    }
    
    public string PlaybackStatus {
        owned get { //TODO signal org.freedesktop.DBus.Properties.PropertiesChanged
            if(Noise.App.player.playing)
                return "Playing";
            else if(!Noise.App.player.playing && Noise.App.player.current_media == null)
                return "Stopped";
            else if(!Noise.App.player.playing)
                return "Paused";
            else
                return "Stopped";
        }
    }
    
    public string LoopStatus {
        owned get {
            switch(Noise.Settings.Main.get_default ().repeat_mode) {
                case(Noise.Settings.Repeat.OFF):
                    return "None";
                case(Noise.Settings.Repeat.MEDIA):
                    return "Track";
                case(Noise.Settings.Repeat.ALBUM):
                case(Noise.Settings.Repeat.ARTIST):
                case(Noise.Settings.Repeat.ALL):
                    return "Playlist";
            }
            
            return "Playlist";
        }
        set {
            switch(value) {
                case("None"):
                    Noise.App.player.set_repeat_mode (Noise.Settings.Repeat.OFF);
                    break;
                case("Track"):
                    Noise.App.player.set_repeat_mode (Noise.Settings.Repeat.MEDIA);
                    break;
                case("Playlist"):
                    Noise.App.player.set_repeat_mode (Noise.Settings.Repeat.ALL);
                    break;
                default:
                    Noise.App.player.set_repeat_mode (Noise.Settings.Repeat.ALL);
                    break;
            }
            
            Variant variant = value;
            queue_property_for_notification("LoopStatus", variant);
        }
    }
    
    public double Rate {
        get {
            return (double)1.0;
        }
        set {
        }
    }
    
    public bool Shuffle {
        get {
            if (Noise.Settings.Main.get_default ().shuffle_mode == Noise.Settings.Shuffle.ALL)
                return true;
            return false;
        }
        set {
            if (value) {
                Noise.App.player.set_shuffle_mode (Noise.Settings.Shuffle.ALL);
            }
            else {
                Noise.App.player.set_shuffle_mode (Noise.Settings.Shuffle.OFF);
            }
            
            Variant variant = value;
            queue_property_for_notification ("Shuffle", variant);
        }
    }
    
    public HashTable<string,Variant>? Metadata { //a{sv}
        owned get {
            update_metadata (Noise.App.player.current_media);
            return _metadata;
        }
    }
    
    public double Volume {
        get{
            return Noise.App.player.volume;
        }
        set {
            Noise.App.player.volume = value;
        }
    }
    
    public int64 Position {
        get {
            return (Noise.App.player.player.get_position()/(int64)Noise.Numeric.MILI_INV);
        }
    }
    
    /*public double MinimumRate {
        get {
            return (double)1.0;
        }
    }

    public double MaximumRate {
        get {
            return (double)1.0;
        }
    }*/

    public bool CanGoNext {
        get {
            return true;
        }
    }
    
    public bool CanGoPrevious {
        get {
            return true;
        }
    }
    
    public bool CanPlay {
        get {
            return true;
        }
    }
    
    public bool CanPause {
        get {
            return true;
        }
    }
    
    public bool CanSeek {
        get {
            return true;
        }
    }
    
    public bool CanControl {
        get {
            return true;
        }
    }
    
    public signal void Seeked(int64 Position);

    public void Next() {
        // inhibit notifications
        Noise.App.main_window.play_next_media(true);
    }
    
    public void Previous() {
        // inhibit notifications
        Noise.App.main_window.play_previous_media(true);
    }
    
    public void Pause() {
        // inhibit notifications
        if(Noise.App.player.playing)
            Noise.App.player.pause_playback ();
    }

    public void PlayPause() {
        // inhibit notifications
        Noise.App.main_window.play_media(true);
    }

    public void Stop() {
        if(Noise.App.player.playing)
            Noise.App.player.stop_playback();
    }
    
    public void Play() {
        // inhibit notifications
        if(!Noise.App.player.playing)
            Noise.App.player.start_playback ();
    }

    public void Seek(int64 Offset) {
        int64 Position = this.Position + Offset;
        if (Position < 0)
            Position = 0;

        if (Position < Noise.App.player.player.get_duration () / Noise.Numeric.MILI_INV) {
            SetPosition ("", Position);
            Seeked (Position);
        } else if (CanGoNext) {
            Next ();
        }
    }
    
    public void SetPosition(string dobj, int64 Position) {
        Noise.App.player.player.set_position(Position * (int64)Noise.Numeric.MILI_INV);
    }
    
    public void OpenUri(string Uri) {
        
    }
}
    
[DBus(name = "org.mpris.MediaPlayer2.Playlists")]
public class MprisPlaylists : GLib.Object {
    public struct MprisPlaylist {
        ObjectPath Id;
        string Name;
        string Icon;
    }

    public struct MaybePlaylist {
        bool Valid;
        MprisPlaylist Playlist;
    }

    private unowned DBusConnection conn;
    private MaybePlaylist active_playlist;
    private const string INTERFACE_NAME = "org.mpris.MediaPlayer2.Playlists";
    const string PLAYLIST_ID = "/org/pantheon/noise/Playlists/%d";

    private uint send_property_source = 0;
    private HashTable<string,Variant> changed_properties = null;

    public MprisPlaylists(DBusConnection conn) {
        this.conn = conn;

        Noise.libraries_manager.local_library.playlist_added.connect(playlist_added);
        Noise.libraries_manager.local_library.playlist_removed.connect(playlist_removed);
    }

    void playlist_added(Noise.Playlist p) {
        Variant variant = this.PlaylistCount;
        queue_property_for_notification("PlaylistCount", variant);
    }

    void playlist_removed(Noise.Playlist p) {
        Variant variant = this.PlaylistCount;
        queue_property_for_notification("PlaylistCount", variant);
    }

    private void queue_property_for_notification(string property, Variant val) {
        // putting the properties into a hashtable works as akind of event compression
        if(changed_properties == null)
            changed_properties = new HashTable<string,Variant>(str_hash, str_equal);

        changed_properties.insert(property, val);

        if(send_property_source == 0) {
            send_property_source = Idle.add(send_property_change);
        }
    }

    // This is same as the Player above
    // FIXME: Put this somewhere that can be used by all
    // All this is used for right now is PlaylistCount property
    private bool send_property_change() {
        if(changed_properties == null)
            return false;

        var builder             = new VariantBuilder(VariantType.ARRAY);
        var invalidated_builder = new VariantBuilder(new VariantType("as"));

        foreach(string name in changed_properties.get_keys()) {
            Variant variant = changed_properties.lookup(name);
            builder.add("{sv}", name, variant);
        }

        changed_properties = null;

        try {
            conn.emit_signal(null,
                             "/org/mpris/MediaPlayer2", 
                             "org.freedesktop.DBus.Properties", 
                             "PropertiesChanged", 
                             new Variant("(sa{sv}as)", 
                                         INTERFACE_NAME, 
                                         builder, 
                                         invalidated_builder)
                             );
            message("Sent properties changed signal\n");
        }
        catch(Error e) {
            print("Could not send MPRIS property change: %s\n", e.message);
        }

        send_property_source = 0;
        return false;
    }

    public void ActivatePlaylist(ObjectPath path) {
        string playlist_id = path.replace ("/org/pantheon/noise/Playlists/", "");

        Noise.Playlist p = Noise.libraries_manager.local_library.playlist_from_id (int.parse (playlist_id));
        if(p == null) {
            warning ("Selected playlist had invalid path %s and could not be found", path);
            return;
        }
        p.request_play ();
    }

    public MprisPlaylist?[] GetPlaylists(uint index, uint maxcount, string playlist_ordering, bool reversed) {
        debug("Get Playlist called with index %u and maxcount %u\n", index, maxcount);
        var playlists = new Gee.LinkedList<Noise.Playlist>();

        foreach (var p in Noise.libraries_manager.local_library.get_playlists ()) {
            if (reversed) {
                playlists.offer_tail (p);
            } else {
                playlists.offer_head (p);
            }
        }

        int i = 0;
        var rv = new Gee.LinkedList<MprisPlaylist?>();
        foreach(Noise.Playlist p in playlists) {
            ObjectPath path = new ObjectPath(PLAYLIST_ID.printf(p.rowid));

            MprisPlaylist to_add = MprisPlaylist();
            to_add.Id = path;
            to_add.Name = p.name;
            to_add.Icon = "file://" + Build.ICON_DIR + "/hicolor/16x16/mimetypes/" + p.icon.to_string () + ".svg";

            rv.add(to_add);
            debug("Added playlist %s %s\n", path, p.name);

            if(i >= maxcount)
                break;
        }

        return rv.to_array();
    }

    public signal void PlaylistChanged(Variant playlist);

    public uint PlaylistCount {
        get {
            return (uint)(Noise.libraries_manager.local_library.get_playlists ().size + Noise.libraries_manager.local_library.get_smart_playlists ().size);
        }
    }

    private static string[] all_orderings = { "UserDefined"};
    public string[] Orderings {
        get {
            return all_orderings;
        }
    }

    public MaybePlaylist ActivePlaylist {
        get {
            // FIXME: Should be a real playlist
            Noise.Playlist p = null;

            if(p == null) {
                active_playlist.Valid = true; // Set it to true to force that 'Playlist' shows
                MprisPlaylist mprisP = MprisPlaylist();
                mprisP.Id = new ObjectPath(PLAYLIST_ID.printf(0));
                mprisP.Name = _("Playlists"); // Just a filler, should never show
                mprisP.Icon = "";
                active_playlist.Playlist = mprisP;
            } else {
                active_playlist.Valid = true;
                MprisPlaylist mprisP = MprisPlaylist();
                mprisP.Id = new ObjectPath(PLAYLIST_ID.printf(p.rowid));
                mprisP.Name = p.name;
                mprisP.Icon = "file://" + Build.ICON_DIR + "/hicolor/16x16/mimetypes/" + p.icon.to_string () + ".svg";
                active_playlist.Playlist = mprisP;
            }

            return active_playlist;
        }
    }

}
