// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
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
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 */

using Gee;

public class Noise.PlaybackManager : Noise.Player {

    public static PlaybackManager? _instance;
    public static PlaybackManager instance {
        get {
            if (_instance == null)
                _instance = new PlaybackManager ();
            return _instance;
        }
    }

    /*
    public Player.Shuffle shuffle_mode {
        set { setShuffleMode (value); }
        // TODO: get { return ... }
    }
    */

	public signal void current_cleared ();
	public signal void history_changed ();

	public signal void queue_cleared  ();
	public signal void media_queued   (Gee.Collection<Media> queued);
	public signal void media_unqueued (Gee.Collection<Media> unqueued);

	public signal void media_played (Media played_media);
	public signal void playback_stopped (int was_playing);


	// id, media of current media.
	private HashMap<int, Media> _current = new Gee.HashMap<int, Media>();

	//list of id's yet to be played while on shuffle
	private HashMap<int, Media> _current_shuffled = new Gee.HashMap<int, Media>();

	// rowid, Media of queue
	private LinkedList<Media> _queue = new Gee.LinkedList<Media>();

	// Media of already played
	private LinkedList<Media> _already_played = new Gee.LinkedList<Media>();


	public int _played_index = 0;//if user press back, this goes back 1 until it hits 0. as new media play, this goes with it
	public int _current_index;
	public int _current_shuffled_index;
	public Noise.MediaInfo media_info { private set; get; }

	// Whether or not a media is being played. Returns true even if the media is paused
	public bool media_active { get { return media_info.media != null; } }

	public bool playing; // TODO { get; private set; }
	bool _playing_queued_song;
	public Player.Repeat repeat;
	public Player.Shuffle shuffle;
	public int next_gapless_id;

	public Noise.Streamer player;


    public PlaybackManager () {
        this.player = new Streamer ();
		media_info = new Noise.MediaInfo();

		int repeatValue = Settings.Main.instance.repeat_mode;
		if(repeatValue == 0)
			repeat = Player.Repeat.OFF;
		else if(repeatValue == 1)
			repeat = Player.Repeat.MEDIA;
		else if(repeatValue == 2)
			repeat = Player.Repeat.ALBUM;
		else if(repeatValue == 3)
			repeat = Player.Repeat.ARTIST;
		else if(repeatValue == 4)
			repeat = Player.Repeat.ALL;
    }


	/**************** Queue Stuff **************************/
	public bool queue_empty() {
		return (_queue.size == 0);
	}
	
	public void clear_queue() {
		_queue.clear();
		queue_cleared ();
	}

	public void queue_media (Gee.Collection<Media> to_queue) {
		if (to_queue.size < 1)
			return;
		
		foreach (var m in to_queue)
			_queue.offer_tail (m);

		media_queued (to_queue);
	}

	public void queue_media_by_id (Collection<int> ids) {
		queue_media (App.library_manager.media_from_ids (ids));		
	}


	public void unqueue_media (Gee.Collection<Media> to_unqueue) {
		foreach (var m in to_unqueue)
			_queue.remove (m);
		media_unqueued (to_unqueue);
	}

	public void unqueue_media_by_id (Collection<int> ids) {
		unqueue_media (App.library_manager.media_from_ids (ids));		
	}

	public Media peek_queue() {
		return _queue.peek_head();
	}
	
	public Media poll_queue() {
		var m = _queue.poll_head ();
		var unqueued = new Gee.LinkedList<Media> ();
		unqueued.add (m);
		media_unqueued (unqueued);
		return m;
	}

	public Collection<Media> queue() {
		return _queue;
	}

	/************ Already Played Stuff **************/
	public void reset_already_played() {
		_already_played.clear();
		history_changed ();
	}

	public void add_already_played (Media m) {
		if(!_already_played.contains (m))
			_already_played.offer_tail (m);
		history_changed ();
	}
	
	public LinkedList<Media> already_played() {
		return _already_played;
	}

	/************ Current medialist stuff ***************/
	public bool playing_queued_song() {
		return _playing_queued_song;
	}
	
	public bool is_shuffled() {
		return _current_shuffled.size > 0;
	}
	
	/* value returned depends on whether shuffle is on or not */
	public int current_index {
		get {
			if(_current_shuffled.size == 0)
				return _current_index;
			else
				return _current_shuffled_index;
		}
		set {
			if(_current_shuffled.size == 0)
				_current_index = value;
			else {
				_current_shuffled_index = value;
			}
		}
	}
	
	public Media mediaFromCurrentIndex (int index_in_current) {
		if(shuffle == Player.Shuffle.OFF)
			return _current.get(index_in_current);
		else
			return _current_shuffled.get(index_in_current);
	}
	
	public Collection<Media> current_media () {
		if(shuffle == Player.Shuffle.OFF)
			return _current_shuffled.values;
		else
			return _current.values;
	}
	
	
	public void clearCurrent() {
		current_cleared();
		_current.clear();
		
		shuffle = Player.Shuffle.OFF; // must manually reshuffle
	}


	public void addToCurrent (Media m) {
		_current.set (_current.size, m);
	}
	
	public void setShuffleMode(Player.Shuffle mode, bool reshuffle) {
		/*if(mode == shuffle)
			return;
		*/
		Settings.Main.instance.shuffle_mode = mode;
		shuffle = mode;
		
		if(!reshuffle)
			return;
		
		_current_shuffled.clear();
		_current_shuffled_index = 0;
		
		if(mode == Player.Shuffle.OFF) {
			if(media_active) {
				//make sure we continue playing where we left off
				for(int i = 0; i < _current.size; ++i) {
					if(_current.get(i) == media_info.media) {
						_current_index = i;
						return;
					}
				}
			}
			else {
				_current_index = 0;
			}
		}
		else if(mode == Player.Shuffle.ALL) {
			//create temp list of all of current's media
			var temp = new LinkedList<Media>();
			foreach(var m in _current.values) {
				temp.add (m);
			}
			
			//loop through all current media id's and pick a random one remaining
			//and set that int i as one of those this is confusing just a sort
			//_current_shuffled.set(0, media_info.media.rowid);
			for(int i = 1;i < _current.size; ++i) {
				int random = GLib.Random.int_range(0, temp.size);
				
				//if(temp.get(random) != media_info.media.rowid) {
				if(media_active && temp.get(random) == media_info.media) {
					_current_shuffled.set(0, media_info.media);
					--i;
				}
				else {
					_current_shuffled.set(i, temp.get(random));
				}
				temp.remove(temp.get(random));
			}
		}
	}
	
	public Media? getNext(bool play) {
		Media? rv = null;
		
		// next check if user has queued media
		if(!queue_empty()) {
			rv = poll_queue();
			_playing_queued_song = true;
		}
		else if(_current_shuffled.size != 0) {
			_playing_queued_song = false;
			
			if(media_info.media == null) {
				_current_shuffled_index = 0;
				rv = _current_shuffled.get(0);
			}
			else if(repeat == Player.Repeat.MEDIA) {
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else if(_current_shuffled_index == (_current_shuffled.size - 1)) {// consider repeat options
				if(repeat == Player.Repeat.ALL)
					_current_shuffled_index = 0;
				else {
					/* reset to no media playing */
					media_info.media = null;
					_current_shuffled.clear();
					_current.clear();
					_current_shuffled_index = 0;
					_current_index = 0;
					
					if(play)
						stopPlayback();
					
					return null;
				}
				
				rv = _current_shuffled.get(0);
			}
			else if(_current_shuffled_index >= 0 && _current_shuffled_index < (_current_shuffled.size - 1)){
				// make sure we are repeating what we need to be
				if(repeat == Player.Repeat.ARTIST && _current_shuffled.get(_current_shuffled_index + 1).artist != _current_shuffled.get(_current_shuffled_index).artist) {
					while(_current_shuffled.get(_current_shuffled_index - 1).artist == media_info.media.artist)
						--_current_shuffled_index;
				}
				else if(repeat == Player.Repeat.ALBUM && _current_shuffled.get(_current_shuffled_index + 1).album != _current_shuffled.get(_current_shuffled_index).album) {
					while(_current_shuffled.get(_current_shuffled_index - 1).album == media_info.media.album)
						--_current_shuffled_index;
				}
				else {
					++_current_shuffled_index;
				}
				
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else {
				foreach(Media s in App.library_manager.media ())
					addToCurrent(s);
				
				_current_shuffled_index = 0;
				setShuffleMode(Player.Shuffle.ALL, true);
				rv = _current_shuffled.get(0);
			}
		}
		else {
			_playing_queued_song = false;
			
			if(media_info.media == null) {
				_current_index = 0;
				rv = _current.get(0);
			}
			else if(repeat == Player.Repeat.MEDIA) {
				rv = _current.get(_current_index);
			}
			else if(_current_index == (_current.size - 1)) {// consider repeat options
				if(repeat == Player.Repeat.ALL)
					_current_index = 0;
				else {
					if(play)
						stopPlayback();
					return null;
				}
				
				rv = _current.get(0);
			}
			else if(_current_index >= 0 && _current_index < (_current.size - 1)){
				// make sure we are repeating what we need to be
				if(repeat == Player.Repeat.ARTIST && _current.get(_current_index + 1).artist != _current.get(_current_index).artist) {
					while(_current.get(_current_index - 1).artist == media_info.media.artist)
						--_current_index;
				}
				else if(repeat == Player.Repeat.ALBUM && _current.get(_current_index + 1).album != _current.get(_current_index).album) {
					while(_current.get(_current_index - 1).album == media_info.media.album)
						--_current_index;
				}
				else
					++_current_index;
				
				rv = _current.get(_current_index);
			}
			else {
				foreach(Media s in App.library_manager.media ())
					addToCurrent(s);
				
				_current_index = 0;
				rv = _current.get(0);
			}
		}
		
		if(play)
			playMedia(rv, false);
		
		return rv;
	}
	
	// TODO: remove code redundancy
	public Media? getPrevious(bool play) {
		Media? rv = null;
		
		if(_current_shuffled.size != 0) {
			_playing_queued_song = false;
			
			if(media_info.media == null) {
				_current_shuffled_index = _current_shuffled.size - 1;
				rv = _current_shuffled.get (_current_shuffled_index);
			}
			else if(repeat == Player.Repeat.MEDIA) {
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else if(_current_shuffled_index == 0) {// consider repeat options
				if(repeat == Player.Repeat.ALL)
					_current_shuffled_index = _current_shuffled.size - 1;
				else {
					stopPlayback();
					return null;
				}
				
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else if(_current_shuffled_index > 0 && _current_shuffled_index < _current_shuffled.size){
				// make sure we are repeating what we need to be
				if(repeat == Player.Repeat.ARTIST && _current_shuffled.get(_current_shuffled_index - 1).artist != _current_shuffled.get(_current_shuffled_index).artist) {
					while(_current_shuffled.get(_current_shuffled_index + 1).artist == media_info.media.artist)
						++_current_shuffled_index;
				}
				else if(repeat == Player.Repeat.ALBUM && _current_shuffled.get(_current_shuffled_index - 1).album != _current_shuffled.get(_current_shuffled_index).album) {
					while(_current_shuffled.get(_current_shuffled_index + 1).album == media_info.media.album)
						++_current_shuffled_index;
				}
				else
					--_current_shuffled_index;
				
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else {
				foreach(Media s in App.library_manager.media ())
					addToCurrent(s);
				
				_current_shuffled_index = _current_shuffled.size - 1;
				rv = _current_shuffled.get(_current_shuffled_index);
			}
		}
		else {
			_playing_queued_song = false;
			
			if(media_info.media == null) {
				_current_index = _current.size - 1;
				rv = _current.get(_current_index);
			}
			else if(repeat == Player.Repeat.MEDIA) {
				rv = _current.get(_current_index);
			}
			else if(_current_index == (0)) {// consider repeat options
				if(repeat == Player.Repeat.ALL)
					_current_index = _current.size - 1;
				else {
					stopPlayback();
					return null;
				}
				
				rv = _current.get(_current_index);
			}
			else if(_current_index > 0 && _current_index < _current.size){
				// make sure we are repeating what we need to be
				
				if(repeat == Player.Repeat.ARTIST && _current.get(_current_index - 1).artist != _current.get(_current_index).artist) {
					while(_current.get(_current_index + 1).artist == media_info.media.artist)
						++_current_index;
				}
				else if(repeat == Player.Repeat.ALBUM && _current.get(_current_index - 1).album != _current.get(_current_index).album) {
					while(_current.get(_current_index + 1).album == media_info.media.album)
						++_current_index;
				}
				else
					--_current_index;
				
				rv = _current.get(_current_index);
			}
			else {
				foreach(Media s in App.library_manager.media ())
					addToCurrent(s);
				
				_current_index = _current.size - 1;
				rv = _current.get(_current_index);
			}
		}
		
		if(play)
			playMedia(rv, false);
		
		return rv;
	}
	
	
	public void playMedia(Media m, bool use_resume_pos) {
		
		/*if(m.isTemporary) {
			_media.set(PREVIEW_MEDIA_ID, m);
			playMediaInternal(PREVIEW_MEDIA_ID, use_resume_pos);
		}
		else {
		*/
			playMediaInternal(m.rowid, use_resume_pos);
		//}
	}
	
	void playMediaInternal(int id, bool use_resume_pos) {
		int old_id = -1;
		
		if(id == 0 || App.library_manager.media_from_id(id) == null)
			return;
		
		// save previous media's id
		if(media_active)
			old_id = media_info.media.rowid;
		
		// set the current media
		media_info.media = App.library_manager.media_from_id(id);
		Media m = App.library_manager.media_from_id(id);
		
		// To avoid infinite loop, if we come across a song we already know does not exist
		// stop playback
		if(m.location_unknown) {
			if(File.new_for_uri(m.uri).query_exists()) { // we did not know location, but it has re-appearred
				m.location_unknown = false;
				m.unique_status_image = null;
				//LibraryWindow.instance.media_found(m.rowid);
			}
			else { // to avoid infinite loop with repeat on, don't try to play next again
				stopPlayback();
				return;
			}
		}
		
		// check that the file exists FIXME: Avoid reading settings everytime a song is played
		var music_folder_uri = File.new_for_path(Settings.Main.instance.music_folder).get_uri();
		if((Settings.Main.instance.music_folder != "" && m.uri.has_prefix(music_folder_uri) && !GLib.File.new_for_uri(m.uri).query_exists())) {
			m.unique_status_image = Icons.PROCESS_ERROR.render(Gtk.IconSize.MENU, ((ViewWrapper)LibraryWindow.instance.sideTree.getWidget(LibraryWindow.instance.sideTree.library_music_iter)).list_view.get_style_context());
			m.location_unknown = true;
			//LibraryWindow.instance.media_not_found(id);
			getNext(true);
			return;
		}
		else {
			if(m.location_unknown && m.unique_status_image != null) {
				m.unique_status_image = null;
				m.location_unknown = false;
			}
		}

        change_gains_thread ();
		
		if(m.mediatype == MediaType.PODCAST || m.mediatype == MediaType.AUDIOBOOK || use_resume_pos)
			player.set_resume_pos = false;

		// actually play the media asap
		if(next_gapless_id == 0) {
			player.setURI(m.uri);
		}
		else {
			next_gapless_id = 0;
		}
		
		//pause if paused
		if(!playing)
			player.pause();
		
		//update settings
		//if(id != PREVIEW_MEDIA_ID)
			Settings.Main.instance.last_media_playing = id;
		
		if (m != null)
			media_played (m);
		
		/* if same media 1 second later... */
		Timeout.add(1000, () => {
			if (m != null && media_info.media == m) {
				// potentially fix media length
				uint player_duration_s = (uint)(player.getDuration() / Numeric.NANO_INV);
				if (player_duration_s > 1) {
				    int delta_s = (int)player_duration_s - (int)(m.length / Numeric.MILI_INV);
				    if (Math.fabs ((double)delta_s) > 3) {
					    m.length = (uint)(player_duration_s * Numeric.MILI_INV);
					    App.library_manager.update_media_item (m, false, false);
                    }
				}
			}
			
			return false;
			
		});
	}

	public void* change_gains_thread () {
		if (Settings.Equalizer.instance.equalizer_enabled) {
			bool automatic_enabled = Settings.Equalizer.instance.auto_switch_preset;
			string selected_preset = Settings.Equalizer.instance.selected_preset;

			foreach(var p in Settings.Equalizer.instance.getPresets ()) {
				if(p != null && media_active)  {
					var preset_name = p.name.down ();
					var media_genre = media_info.media.genre.down();

					bool match_genre = (preset_name in media_genre) || (media_genre in preset_name);

					if ( (automatic_enabled && match_genre) ||
					     (!automatic_enabled && p.name == selected_preset))
					{
						for(int i = 0; i < 10; ++i)
							player.setEqualizerGain(i, p.getGain(i));
					
						return null;
					}
				}
			}

			foreach(var p in Equalizer.get_default_presets ()) {
				if(p != null && media_active)  {
					var preset_name = p.name.down ();
					var media_genre = media_info.media.genre.down();

					bool match_genre = (preset_name in media_genre) || (media_genre in preset_name);

					if ( (automatic_enabled && match_genre) ||
					     (!automatic_enabled && p.name == selected_preset))
					{
						for(int i = 0; i < 10; ++i)
							player.setEqualizerGain(i, p.getGain(i));
					
						return null;
					}
				}
			}
		}

		for (int i = 0; i < 10; ++i)
			player.setEqualizerGain(i, 0);		
		
		return null;
	}

	public void stopPlayback() {
		player.pause();
		
		int was_playing = 0;
		if(media_active)
			was_playing = media_info.media.rowid;
		
		Settings.Main.instance.last_media_playing = 0;
		media_info.update(null, null, null, null);
		
		playback_stopped(was_playing);
	}


}
