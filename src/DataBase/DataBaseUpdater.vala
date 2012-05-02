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

/* Merely a place holder for multiple pieces of information regarding
 * the current media playing. Mostly here because of dependence. */

using Gee;

public class BeatBox.DataBaseUpdater : GLib.Object {
	private LibraryManager lm;
	private BeatBox.DataBaseManager dbm;
	
	LinkedList<Media> media_updates;
	
	Mutex update_mutex;
	Mutex remove_mutex;
	
	LinkedList<GLib.Object> toUpdate; // a queue of things to update
	LinkedList<GLib.Object> toRemove;
	bool inThread;
	
	public DataBaseUpdater(LibraryManager lm, BeatBox.DataBaseManager databm) {
		this.lm = lm;
		dbm = databm;
		
		media_updates = new LinkedList<Media>();
		toUpdate = new LinkedList<GLib.Object>();
		toRemove = new LinkedList<GLib.Object>();
		inThread = false;
		
		tree_view_setups = new GLib.List<TreeViewSetup>();
		
		Timeout.add(10000, periodic_save);
	}
	
	bool periodic_save() {
		save_others();
		
		return true;
	}
	
	public void update_item(GLib.Object item) {
		if(!(toUpdate.contains(item)))
			toUpdate.offer(item);
		
		update_db_async ();
	}
	
	public void update_media(Media s) {
		update_mutex.lock();
		if(!(media_updates.contains(s)))
			media_updates.offer(s);
		update_mutex.unlock();
		
		update_db_async ();
	}

	private async void update_db_async () {
		if(!inThread) {
			try {
				inThread = true;
				new Thread<void*>.try (null, update_db_thread_function);
			}
			catch(Error err) {
				warning ("Could not create thread to update database: %s \n", err.message);
			}
		}
	}
	
	public void removeItem(GLib.Object item) {
		remove_mutex.lock();
		if(!(toRemove.contains(item)))
			toRemove.offer(item);
		remove_mutex.unlock();
		
		update_db_async ();
	}
	
	public void* update_db_thread_function () {
		while(true) {
			GLib.Object next;
			
			update_mutex.lock();
			remove_mutex.lock();
			if(media_updates.size > 0) {
				dbm.update_medias(media_updates);
				media_updates.clear();
			}
			else if((next = toUpdate.poll()) != null) {
				if(next is Playlist) {
					//dbm.update_playlist((Playlist)next);
				}
				else if(next is SmartPlaylist) {
					//dbm.update_smart_playlist((SmartPlaylist)next);
				}
			}
			else if((next = toRemove.poll()) != null) {
				if(next is LinkedList) {
					dbm.remove_medias((LinkedList<string>)next);
				}
				else if(next is Playlist) {
					dbm.remove_playlist((Playlist)next);
				}
				else if(next is SmartPlaylist) {
					dbm.remove_smart_playlist((SmartPlaylist)next);
				}
			}
			else {
				inThread = false;
				update_mutex.unlock();
				remove_mutex.unlock();
				return null;
			}
			
			update_mutex.unlock();
			remove_mutex.unlock();
		}

	}
	
	GLib.List<TreeViewSetup> tree_view_setups;
	
    public void register_autosaved_column (string name, TreeViewSetup setup) {
        setup.set_data<string>("name", name);
        tree_view_setups.append (setup);
    }
	
	void save_others() {
		var playlists_and_queue = new LinkedList<Playlist>();
		playlists_and_queue.add_all(lm.playlists());
		
		Playlist p_queue = new Playlist();
		p_queue.name = "autosaved_queue";
		p_queue.add_media(lm.queue());
		p_queue.tvs = lm.queue_setup;
		
		Playlist p_history = new Playlist();
		p_history.name = "autosaved_history";
		p_history.tvs = lm.history_setup;
		
		Playlist p_similar = new Playlist();
		p_similar.name = "autosaved_similar";
		p_similar.tvs = lm.similar_setup;
		
		Playlist p_music = new Playlist();
		p_music.name = "autosaved_music";
		p_music.tvs = lm.music_setup;

#if HAVE_PODCASTS
		Playlist p_podcast = new Playlist();
		p_podcast.name = "autosaved_podcast";
		p_podcast.tvs = lm.podcast_setup;
#endif

#if HAVE_INTERNET_RADIO
		Playlist p_station = new Playlist();
		p_station.name = "autosaved_station";
		p_station.tvs = lm.station_setup;
#endif
		
		playlists_and_queue.add(p_queue);
		playlists_and_queue.add(p_history);
		playlists_and_queue.add(p_similar);
		playlists_and_queue.add(p_music);
#if HAVE_PODCASTS
		playlists_and_queue.add(p_podcast);
#endif
#if HAVE_INTERNET_RADIO
		playlists_and_queue.add(p_station);
#endif
		
		debug("Doing periodic save\n");
		
		dbm.save_playlists(playlists_and_queue);
		dbm.save_smart_playlists(lm.smart_playlists());
		dbm.save_artists(lm.lfm.artists());
		dbm.save_albums(lm.lfm.albums());
		dbm.save_tracks(lm.lfm.tracks());
		dbm.save_devices(lm.device_manager.device_preferences());
	}
}
