using Gst;
using Gtk;

public class BeatBox.Streamer : GLib.Object {
	LibraryManager lm;
	LibraryWindow lw;
	BeatBox.Pipeline pipe;
	
	InstallGstreamerPluginsDialog dialog;
	
	/** signals **/
	public signal void end_of_stream();
	public signal void current_position_update(int64 position);
	public signal void song_not_found();
	
	public Streamer(LibraryManager lm, LibraryWindow lw, string[] args) {
		Gst.init(ref args);
		
		this.lm = lm;
		this.lw = lw;
		
		pipe = new BeatBox.Pipeline();
		
		pipe.bus.add_watch(busCallback);
		pipe.playbin.about_to_finish.connect(about_to_finish);
		
		Timeout.add(500, doPositionUpdate);
	}
	
	public void songRipped(Song s) {
		setURI("file://" + s.file);
	}
	
	public bool doPositionUpdate() {
		current_position_update(getPosition());
		Timeout.add(500, doPositionUpdate);
		
		return false;
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
		pipe.playbin.uri = uri.replace("#", "%23");
		
		if(pipe.video.element != null) {
			var xoverlay = pipe.video.element as XOverlay;
			xoverlay.set_xwindow_id(Gdk.X11Window.get_xid(lw.videoArea.get_window ()));
		}
		
		setState(State.PLAYING);
		
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
			
			Idle.add( () => {
				if(pipe.videoStreamCount() > 0) {
					if(lw.viewSelector.get_children().length() != 4) {
						//stdout.printf("turning on video\n");
						var viewSelectorStyle = lw.viewSelector.get_style_context ();
						var view_video_icon = lm.icons.view_video_icon.render (Gtk.IconSize.MENU, viewSelectorStyle);
						lw.viewSelector.append(new Gtk.Image.from_pixbuf(view_video_icon));
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
			
			
			break;
		case Gst.MessageType.TAG:
            Gst.TagList tag_list;
            
            message.parse_tag (out tag_list);
            if(tag_list != null) {
				if(tag_list.get_tag_size(TAG_TITLE) > 0) {
					string title = "";
					tag_list.get_string(TAG_TITLE, out title);
					
					if(lm.song_info.song.mediatype == 3 && title != "") { // is radio
						string[] pieces = title.split("-", 0);
						
						if(pieces.length >= 2) {
							string old_title = lm.song_info.song.title;
							string old_artist = lm.song_info.song.artist;
							lm.song_info.song.artist = (pieces[0] != null) ? pieces[0].chug().strip() : "Unknown Artist";
							lm.song_info.song.title = (pieces[1] != null) ? pieces[1].chug().strip() : title;
							
							if(old_title != lm.song_info.song.title || old_artist != lm.song_info.song.artist)
								lw.song_played(lm.song_info.song.rowid, lm.song_info.song.rowid); // pretend as if song changed
						}
						else {
							// if the title doesn't follow the general title - artist format, probably not a song change and instead an advert
							lw.topDisplay.set_label_markup(lm.song_info.song.album_artist + "\n" + title);
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
	
	void about_to_finish() {
		int i = lm.getNext(false);
		Song s = lm.song_from_id(i);
		if(s != null && s.mediatype != 3) { // don't do this with radio stations
			if(!s.isPreview && !s.file.contains("cdda://") && !s.file.contains("http://")) // normal file
				pipe.playbin.uri = "file://" + s.file;
			else
				pipe.playbin.uri = s.file; // probably cdda
		}
		
		lm.next_gapless_id = i;
		Idle.add( () => {
			end_of_stream();
			
			return false;
		});
	}
}
