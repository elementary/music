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

public class BeatBox.Streamer : GLib.Object {
	LibraryManager lm;
	LibraryWindow lw;
	BeatBox.Pipeline pipe;
	
	InstallGstreamerPluginsDialog dialog;
	
	public bool checked_video;
	public bool set_resume_pos;
	
	/** signals **/
	public signal void end_of_stream();
	public signal void current_position_update(int64 position);
	public signal void media_not_found();
	
	public Streamer(LibraryManager lm, LibraryWindow lw, string[] args) {
		Gst.init(ref args);
		
		this.lm = lm;
		this.lw = lw;
		
		pipe = new BeatBox.Pipeline();
		
		pipe.bus.add_watch(busCallback);
		//pipe.playbin.about_to_finish.connect(about_to_finish);
		
		Timeout.add(200, doPositionUpdate); // do this 5 times per second
	}
	
	public bool doPositionUpdate() {
		if(set_resume_pos || getPosition() >= (int64)(lm.media_info.media.resume_pos - 1) * 1000000000) {
			set_resume_pos = true;
			current_position_update(getPosition());
		}
		else {
			pipe.playbin.seek_simple(Gst.Format.TIME, Gst.SeekFlags.FLUSH, (int64)lm.media_info.media.resume_pos * 1000000000);
		}
		
		return true;
	}
	
	/* Basic playback functions */
	public void play() {
		setState(State.PLAYING);
	}
	
	public void pause() {
		setState(State.PAUSED);
	}
	
	public void setState(State s) {
		pipe.playbin.set_state(s);
	}
	
	public void setURI(string uri) {
		setState(State.READY);
		debug("set uri to %s\n", uri);
		pipe.playbin.uri = uri.replace("#", "%23");

#if HAVE_PODCASTS
		if(lw.initialization_finished && pipe.video.element != null) {
			var xoverlay = pipe.video.element as XOverlay;
			xoverlay.set_xwindow_id(Gdk.X11Window.get_xid(lw.videoArea.get_window ()));
		}
#endif
		
		setState(State.PLAYING);
		
		debug("setURI seeking to %d\n", lm.media_info.media.resume_pos);
		pipe.playbin.seek_simple(Gst.Format.TIME, Gst.SeekFlags.FLUSH, (int64)lm.media_info.media.resume_pos * 1000000000);
		
		play();
	}
	
	public void setPosition(int64 pos) {
		pipe.playbin.seek(1.0,
		Gst.Format.TIME, Gst.SeekFlags.FLUSH,
		Gst.SeekType.SET, pos,
		Gst.SeekType.NONE, getDuration());
	}
	
	public int64 getPosition() {
		int64 rv = (int64)0;
		Format f = Format.TIME;
		
		pipe.playbin.query_position(ref f, out rv);
		
		return rv;
	}
	
	public int64 getDuration() {
		int64 rv = (int64)0;
		Format f = Format.TIME;
		
		pipe.playbin.query_duration(ref f, out rv);
		
		return rv;
	}
	
	public void setVolume(double val) {
		pipe.playbin.volume = val;
	}
	
	public double getVolume() {
		return pipe.playbin.volume;
	}
	
	/* Extra stuff */
	public void enableEqualizer() {
		pipe.enableEqualizer();
	}
	
	public void disableEqualizer() {
		pipe.disableEqualizer();
	}
	
	public void setEqualizerGain(int index, int val) {
		pipe.eq.setGain(index, val);
	}
	
	/* Callbacks */
	private bool busCallback(Gst.Bus bus, Gst.Message message) {
		switch (message.type) {
		case Gst.MessageType.ERROR:
			GLib.Error err;
			string debug;
			message.parse_error (out err, out debug);
			warning ("Error: %s\n", err.message);
			
			break;
		case Gst.MessageType.ELEMENT:
			if(message.get_structure() != null && is_missing_plugin_message(message) && (dialog == null || !dialog.visible)) {
				dialog = new InstallGstreamerPluginsDialog(lm, lw, message);
			}
			break;
		case Gst.MessageType.EOS:
			end_of_stream();
			break;
		case Gst.MessageType.STATE_CHANGED:
			Gst.State oldstate;
            Gst.State newstate;
            Gst.State pending;
            message.parse_state_changed (out oldstate, out newstate,
                                         out pending);

            if(newstate != Gst.State.PLAYING)
				break;
			
			if(!checked_video) {
				Idle.add( () => {
					checked_video = true;
					if(pipe.videoStreamCount() > 0) {
						stdout.printf("Video stream found in media\n");
					}
					else if(getPosition() > 0) {
						// TODO: Hide video graphics if necessary
					}
					
					return false;
				});
			}
			
			
			break;
		case Gst.MessageType.TAG:
            Gst.TagList tag_list;
            
            message.parse_tag (out tag_list);
            if(tag_list != null) {
				if(tag_list.get_tag_size(TAG_TITLE) > 0) {
					string title = "";
					tag_list.get_string(TAG_TITLE, out title);
					
					if(lm.media_info.media.mediatype == 3 && title != "") { // is radio
						string[] pieces = title.split("-", 0);
						
						if(pieces.length >= 2) {
							string old_title = lm.media_info.media.title;
							string old_artist = lm.media_info.media.artist;
							lm.media_info.media.artist = (pieces[0] != null) ? pieces[0].chug().strip() : "Unknown Artist";
							lm.media_info.media.title = (pieces[1] != null) ? pieces[1].chug().strip() : title;
							
							if(old_title != lm.media_info.media.title || old_artist != lm.media_info.media.artist)
								lw.media_played(lm.media_info.media.rowid, lm.media_info.media.rowid); // pretend as if media changed
						}
						else {
							// if the title doesn't follow the general title - artist format, probably not a media change and instead an advert
							lw.topDisplay.set_label_markup(lm.media_info.media.album_artist + "\n" + title);
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
		int i = lm.getNext(false);
		Media s = lm.media_from_id(i);
		if(s != null && s.mediatype != 3) { // don't do this with radio stations
			pipe.playbin.uri = s.uri; // probably cdda
		}
		else {
			stdout.printf("not doing gapless in streamer because no next song\n");
		}
		
		lm.next_gapless_id = i;
		Idle.add( () => {
			end_of_stream();
			
			return false;
		});
	}*/
}
