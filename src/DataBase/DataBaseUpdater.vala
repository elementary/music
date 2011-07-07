/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originaly Written by Scott Ringwelski for BeatBox Music Player
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
 * the current song playing. Mostly here because of dependence. */

using Gee;

public class BeatBox.DataBaseUpdater : GLib.Object {
	private BeatBox.DataBaseManager dbm;
	
	LinkedList<GLib.Object> toUpdate; // a queue of things to update
	LinkedList<GLib.Object> toRemove;
	bool inThread;
	
	public DataBaseUpdater(BeatBox.DataBaseManager databm) {
		dbm = databm;
		
		toUpdate = new LinkedList<GLib.Object>();
		toRemove = new LinkedList<GLib.Object>();
		inThread = false;
	}
	
	public void updateItem(GLib.Object item) {
		if(!(toUpdate.contains(item)))
			toUpdate.offer(item);
		
		if(!inThread) {
			try {
				inThread = true;
				Thread.create<void*>(update_db_thread_function, false);
			}
			catch(GLib.ThreadError err) {
				stdout.printf("Could not create thread to update database: %s \n", err.message);
			}
		}
	}
	
	public void removeItem(GLib.Object item) {
		if(!(toRemove.contains(item)))
			toRemove.offer(item);
		
		if(!inThread) {
			try {
				inThread = true;
				Thread.create<void*>(update_db_thread_function, false);
			}
			catch(GLib.ThreadError err) {
				stdout.printf("Could not create thread to update database: %s \n", err.message);
			}
		}
	}
	
	public void* update_db_thread_function () {
//		while(true) {
//			GLib.Object next = toUpdate.poll();
			
//			if(next == null) { /* nothing to update, anything to remove? */
//				next = toRemove.poll();
				
//				if(next == null) {
//					inThread = false;
//					return null;
//				}
				
//				if(next is LinkedList<string>) {
//					dbm.remove_songs((LinkedList<string>)next);
//				}
//			}
			
//			if(next is LinkedList<Song>) {
//				dbm.update_songs(((LinkedList<Song>)next));
//			}
//			else if(next is Playlist) {
//				dbm.update_playlist((Playlist)next);
//			}
//			else if(next is SmartPlaylist) {
//				dbm.update_smart_playlist((SmartPlaylist)next);
//			}
//		}
		
		while(true) {
			GLib.Object next;
			if((next = toUpdate.poll()) != null) {
				if(next is LinkedList<Song>) {
					dbm.update_songs(((LinkedList<Song>)next));
				}
				else if(next is Playlist) {
					//dbm.update_playlist((Playlist)next);
				}
				else if(next is SmartPlaylist) {
					//dbm.update_smart_playlist((SmartPlaylist)next);
				}
			}
			else if((next = toRemove.poll()) != null) {
				if(next is LinkedList<string>) {
					dbm.remove_songs((LinkedList<string>)next);
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
				return null;
			}
		}

	}
}
