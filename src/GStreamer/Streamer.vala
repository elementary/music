/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
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

using Gst;
using Gtk;

public class Noise.Streamer : Noise.Playback, GLib.Object {
    Noise.Pipeline pipe;

    InstallGstreamerPluginsDialog dialog;
    
    public Gst.Element cdda;
    public bool set_resume_pos;
    
    /* Signals are now in the Playback interface !
    public signal void end_of_stream ();
    public signal void current_position_update (int64 position);
    public signal void media_not_found ();
    public signal void error_occured (); */
    
    public Streamer () {
        pipe = new Noise.Pipeline();

        pipe.bus.add_watch(GLib.Priority.DEFAULT, bus_callback);
        //pipe.playbin.about_to_finish.connect(about_to_finish);
        

        Timeout.add (200, update_position);
    }
    
    public Gee.Collection<string> get_supported_uri () {
        var uris = new Gee.LinkedList<string> ();
        uris.add ("file://");
        uris.add ("http://");
        return uris;
    }

    public bool update_position () {
        if(set_resume_pos || (App.player.media_info != null && App.player.media_info.media != null && get_position() >= (int64)(App.player.media_info.media.resume_pos - 1) * 1000000000)) {
            set_resume_pos = true;
            current_position_update(get_position());
        }
        else if (App.player.media_info != null && App.player.media_info.media != null) {
            pipe.playbin.seek_simple(Gst.Format.TIME, Gst.SeekFlags.FLUSH, (int64)App.player.media_info.media.resume_pos * 1000000000);
        }
        
        return true;
    }
    
    /* Basic playback functions */
    public void play () {
        set_state (State.PLAYING);
    }
    
    public void pause () {
        set_state (State.PAUSED);
    }
    
    public void set_state (State s) {
        pipe.playbin.set_state (s);
    }
    
    public void set_media (Media media) {
        set_state (State.READY);
        debug ("set uri to %s\n", media.uri);
        //pipe.playbin.uri = uri.replace("#", "%23");
        pipe.playbin.set_property ("uri", media.uri.replace("#", "%23"));

        set_state (State.PLAYING);
        
        debug ("setURI seeking to %d\n", App.player.media_info.media.resume_pos);
        pipe.playbin.seek_simple (Gst.Format.TIME, Gst.SeekFlags.FLUSH, (int64)App.player.media_info.media.resume_pos * 1000000000);
        
        play ();
    }
    
    public void set_position (int64 pos) {
        pipe.playbin.seek (1.0,
        Gst.Format.TIME, Gst.SeekFlags.FLUSH,
        Gst.SeekType.SET, pos,
        Gst.SeekType.NONE, get_duration ());
    }
    
    public int64 get_position () {
        int64 rv = (int64)0;
        Format f = Format.TIME;
        
        pipe.playbin.query_position (f, out rv);
        
        return rv;
    }
    
    public int64 get_duration () {
        int64 rv = (int64)0;
        Format f = Format.TIME;
        
        pipe.playbin.query_duration(f, out rv);
        
        return rv;
    }
    
    public void set_volume (double val) {
        pipe.playbin.set_property ("volume", val);
    }
    
    public double get_volume () {
        var val = GLib.Value (typeof(double));
        pipe.playbin.get_property ("volume", ref val);
        return (double)val;
    }
    
    /* Extra stuff */
    public void enable_equalizer () {
        pipe.enableEqualizer ();
    }
    
    public void disable_equalizer() {
        pipe.disableEqualizer ();
    }
    
    public void set_equalizer_gain (int index, int val) {
        pipe.eq.setGain (index, val);
    }
    
    /* Callbacks */
    private bool bus_callback (Gst.Bus bus, Gst.Message message) {
        switch (message.type) {
        case Gst.MessageType.ERROR:
            GLib.Error err;
            string debug;
            message.parse_error (out err, out debug);
            warning ("Error: %s\n", err.message);
            error_occured();
            break;
        case Gst.MessageType.ELEMENT:
            if(message.get_structure() != null && Gst.PbUtils.is_missing_plugin_message(message) && (dialog == null || !dialog.visible)) {
                dialog = new InstallGstreamerPluginsDialog(message);
            }
            break;
        case Gst.MessageType.EOS:
            end_of_stream ();
            break;
        case Gst.MessageType.STATE_CHANGED:
            Gst.State oldstate;
            Gst.State newstate;
            Gst.State pending;
            message.parse_state_changed (out oldstate, out newstate,
                                         out pending);

            if(newstate != Gst.State.PLAYING)
                break;
            
            
            break;
        case Gst.MessageType.TAG:
            Gst.TagList tag_list;
            
            message.parse_tag (out tag_list);
            if (tag_list != null) {
                if (tag_list.get_tag_size(Gst.Tags.TITLE) > 0) {
                    string title = "";
                    tag_list.get_string(Gst.Tags.TITLE, out title);
                    
                    if (App.player.media_info.media.mediatype == 3 && title != "") { // is radio
                        string[] pieces = title.split("-", 0);
                        
                        if (pieces.length >= 2) {
                            string old_title = App.player.media_info.media.title;
                            string old_artist = App.player.media_info.media.artist;
                            App.player.media_info.media.artist = (pieces[0] != null) ? pieces[0].chug().strip() : _("Unknown Artist");
                            App.player.media_info.media.title = (pieces[1] != null) ? pieces[1].chug().strip() : title;
                            
                            if ((old_title != App.player.media_info.media.title || old_artist != App.player.media_info.media.artist) && (App.player.media_info.media != null))
                                App.main_window.media_played (App.player.media_info.media); // pretend as if media changed
                        } else {
                            // if the title doesn't follow the general title - artist format, probably not a media change and instead an advert
                            notification_manager.doSongNotification (App.player.media_info.media.album_artist + "\n" + title);
                        }
                        
                    }
                }
                
            }
            break;
        default:
            break;
        }
 
        return true;
    }
    
    // no longer used since it would cause bugs
    /*void about_to_finish() {
        int i = App.player.getNext(false);
        Media s = App.library_manager.media_from_id(i);
        if(s != null && s.mediatype != 3) { // don't do this with radio stations
            pipe.playbin.uri = s.uri; // probably cdda
        }
        else {
            message ("not doing gapless in streamer because no next song\n");
        }
        
        App.library_manager.next_gapless_id = i;
        Idle.add( () => {
            end_of_stream();
            
            return false;
        });
    }*/
}
