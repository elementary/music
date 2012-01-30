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
		
		Timeout.add(500, doPositionUpdate);
	}
	
	/*public void mediaRipped(Media s) {
		setURI(s.uri);
	}*/
	
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
		stdout.printf("set uri to %s\n", uri);
		pipe.playbin.uri = uri.replace("#", "%23");
		
		if(lw.initializationFinished && pipe.video.element != null) {
			var xoverlay = pipe.video.element as XOverlay;
			xoverlay.set_xwindow_id(Gdk.X11Window.get_xid(lw.videoArea.get_window ()));
		}
		
		setState(State.PLAYING);
		
		stdout.printf("setURI seeking to %d\n", lm.media_info.media.resume_pos);
		pipe.playbin.seek_simple(Gst.Format.TIME, Gst.SeekFlags.FLUSH, (int64)lm.media_info.media.resume_pos * 1000000000);
		
		play();
		/*if(lm.media_info.media.mediatype == 1 || lm.media_info.media.mediatype == 2) {
			lw.topDisplay.change_value(Gtk.ScrollType.NONE, lm.media_info.media.resume_pos);
			stdout.printf("setting media position to %d\n", lm.media_info.media.resume_pos);
		}*/
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
			stdout.printf ("Error: %s\n", err.message);
			
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
            /*stdout.printf ("state changed: %s->%s:%s\n",
                           oldstate.to_string (), newstate.to_string (),
                           pending.to_string ());*/
                           
            if(newstate != Gst.State.PLAYING)
				break;
			
			//if(getPosition() < (lm.media_info.media.resume_pos * 1000000000)) {
				//stdout.printf("!!!!!!!!trying to resume at %d\n", lm.media_info.media.resume_pos);
				//set_resume_pos = true;
				//pipe.playbin.seek(1.0, Gst.Format.TIME, SeekType.FLUSH | SeekType.SKIP, lm.media_info.media.resume_pos * 1000000000, Gst.SeekType.NONE, getDuration());
				//setPosition(lm.media_info.media.resume_pos * 1000000000);
				//current_position_update(lm.media_info.media.resume_pos * 1000000000);
			//}
			//else {
			//	set_resume_pos = true;
			//}
			
			if(!checked_video) {
				Idle.add( () => {
					checked_video = true;
					if(pipe.videoStreamCount() > 0) {
						if(lw.viewSelector.get_children().length() != 4) {
							//stdout.printf("turning on video\n");
							lw.viewSelector.append(Icons.VIEW_VIDEO_ICON.render_image (Gtk.IconSize.MENU));
							lw.viewSelector.selected = 3;
						}
					}
					else if(getPosition() > 0 && lw.viewSelector.get_children().length() == 4) {
						//stdout.printf("turning off video\n");
						if(lw.viewSelector.selected == 3) {
							lw.viewSelector.selected = 1; // show list
						}
						
						if(lw.viewSelector.get_children().length() == 4) {
							lw.viewSelector.remove(3);
						}
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
