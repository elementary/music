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
					stdout.printf("dbu speaking\n");
					dbm.update_songs(((LinkedList<Song>)next));
					stdout.printf("dbu logging off\n");
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
					//dbm.remove_songs((LinkedList<string>)next);
				}
			}
			else {
				inThread = false;
				return null;
			}
		}

	}
}
