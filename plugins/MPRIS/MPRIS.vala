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

using Gee;
using Noise;

public class Noise.MPRIS : GLib.Object {
    public MprisPlayer player = null;
    public MprisRoot root = null;
    
    private unowned DBusConnection conn;
    private uint owner_id;
    
    public void initialize () {
        owner_id = Bus.own_name(BusType.SESSION,
                                "org.mpris.MediaPlayer2." + App.instance.exec_name,
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
            return App.instance.get_desktop_file_name ().replace (".desktop", "");
        } 
    }
    
    public string Identity {
        owned get {
            return App.instance.get_name ();
        }
    }
    
    public string[] SupportedUriSchemes {
        owned get {
            string[] sa = {"http", "file", "https", "ftp"};
            return sa;
        }
    }
    
    // TODO: use App.CONTENT_TYPES
    public string[] SupportedMimeTypes {
        owned get {
            return App.get_media_content_types ();
        }
    }

    public void Quit () {
        App.main_window.destroy ();
    }
    
    public void Raise () {
        App.main_window.present();
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

    private enum Direction {
        NEXT = 0,
        PREVIOUS,
        STOP
    }
    
    public MprisPlayer(DBusConnection conn) {
        this.conn = conn;
        _metadata = new HashTable<string,Variant>(str_hash, str_equal);
        
        App.player.media_played.connect(on_media_played);
        App.library_manager.media_updated.connect(media_data_updated);
        App.main_window.playPauseChanged.connect(playing_changed);
    }
    
    void media_data_updated(Gee.LinkedList<int> ids) {
        if(App.player.media_info.media == null)
            return;
        
        foreach(int i in ids) {
            if(i == App.player.media_info.media.rowid) {
                trigger_metadata_update();
                return;
            }
        }
    }
    
    private void playing_changed() {
        trigger_metadata_update();
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

    private void on_media_played (Noise.Media s) {
        if(s != App.player.media_info.media)
            return;

        var url = "file://" + CoverartCache.instance.get_cached_image_path_for_media (s);
        _metadata.insert("mpris:artUrl", url);
        _metadata.insert("mpris:length", App.player.player.getDuration()/1000);

        _metadata.insert("xesam:trackNumber", (int) s.track);
        _metadata.insert("xesam:title", s.get_display_title ());
        _metadata.insert("xesam:album", s.get_display_album ());
        _metadata.insert("xesam:artist", get_simple_string_array (s.get_display_artist ()));
        _metadata.insert("xesam:albumArtist", get_simple_string_array (s.get_display_album_artist ()));
        _metadata.insert("xesam:genre", get_simple_string_array (s.get_display_genre ()));
        _metadata.insert("xesam:asText", s.lyrics);
        _metadata.insert("xesam:comment", get_simple_string_array (s.comment));
        _metadata.insert("xesam:composer", get_simple_string_array (s.get_display_composer ()));
        _metadata.insert("xesam:discNumber", (int) s.album_number);

        _metadata.insert("xesam:url", s.uri);

        _metadata.insert("xesam:userRating", (int) s.rating);
        _metadata.insert("xesam:useCount", (int) s.play_count);

        trigger_metadata_update();
    }

    private static string[] get_simple_string_array (string text) {
        string[] array = new string[0];
        array += text;
        return array;
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
            conn.emit_signal("org.mpris.MediaPlayer2." + App.instance.exec_name,
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
            if(App.player.playing)
                return "Playing";
            else if(!App.player.playing && App.player.media_info.media == null)
                return "Stopped";
            else if(!App.player.playing)
                return "Paused";
            else
                return "Stopped";
        }
    }
    
    public string LoopStatus {
        owned get {
            switch(App.player.repeat) {
                case(Noise.Player.Repeat.OFF):
                    return "None";
                case(Noise.Player.Repeat.MEDIA):
                    return "Track";
                case(Noise.Player.Repeat.ALBUM):
                case(Noise.Player.Repeat.ARTIST):
                case(Noise.Player.Repeat.ALL):
                    return "Playlist";
            }
            
            return "Playlist";
        }
        set {
            switch(value) {
                case("None"):
                    App.player.repeat = Noise.Player.Repeat.OFF;
                    break;
                case("Track"):
                    App.player.repeat = Noise.Player.Repeat.MEDIA;
                    break;
                case("Playlist"):
                    App.player.repeat = Noise.Player.Repeat.ALL;
                    break;
                default:
                    App.player.repeat = Noise.Player.Repeat.ALL;
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
            if (App.player.shuffle == Noise.Player.Shuffle.ALL)
                return true;
            return false;
        }
        set {
            if (value) {
                App.player.setShuffleMode (Noise.Player.Shuffle.ALL, true);
            }
            else {
                App.player.setShuffleMode (Noise.Player.Shuffle.OFF, true);
            }
            
            Variant variant = value;
            queue_property_for_notification ("Shuffle", variant);
        }
    }
    
    public HashTable<string,Variant>? Metadata { //a{sv}
        owned get {
            Variant variant = "1";
            _metadata.insert("mpris:trackid", variant);
            return _metadata;
        }
    }
    
    public double Volume {
        get{
            return App.player.player.getVolume();
        }
        set {
            App.player.player.setVolume(value);
        }
    }
    
    public int64 Position {
        get {
            return (App.player.player.getPosition()/1000);
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
        App.main_window.play_next_media(true);
    }
    
    public void Previous() {
        // inhibit notifications
        App.main_window.play_previous_media(true);
    }
    
    public void Pause() {
        // inhibit notifications
        if(App.player.playing)
            App.main_window.play_media(true);
    }

    public void PlayPause() {
        // inhibit notifications
        App.main_window.play_media(true);
    }

    public void Stop() {
        App.player.stopPlayback();
    }
    
    public void Play() {
        // inhibit notifications
        if(!App.player.playing)
            App.main_window.play_media(true);
    }
    
    public void Seek(int64 Offset) {
        //App.player.player.setPosition(Position/ 1000);
        debug("Must seek!\n");
    }
    
    public void SetPosition(string dobj, int64 Position) {
        App.player.player.setPosition(Position * 1000);
    }
    
    public void OpenUri(string Uri) {
    }
}
