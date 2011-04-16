using TagLib;
using Gee;

public class BeatBox.FileOperator : Object {
	private BeatBox.LibraryManager lm;
	private BeatBox.Settings settings;
	
	bool inThread;
	LinkedList<Song> toSave;
	
	int index;
	int item_count;
	public signal void fo_progress(string? message, double progress);
	
	public FileOperator(BeatBox.LibraryManager lmm, BeatBox.Settings sett) {
		lm = lmm;
		settings = sett;
		inThread = false;
		toSave = new LinkedList<Song>();
	}
	
	public void resetProgress(int items) {
		index = 0;
		item_count = items;
	}
	
	private bool is_valid_file_type(string type) {
		return (type.down().has_suffix(".mp3") || type.down().has_suffix(".m4a") || type.down().has_suffix(".wma") || type.down().has_suffix(".ogg") || type.down().has_suffix(".flac") || type.down().has_suffix(".mp4") || type.down().has_suffix(".ogg"));
	}
	
	public int count_music_files(GLib.File music_folder) {
		GLib.FileInfo file_info = null;
		
		try {
			var enumerator = music_folder.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
			while ((file_info = enumerator.next_file ()) != null) {
				var file_path = music_folder.get_path() + "/" + file_info.get_name();
				
				if(file_info.get_file_type() == GLib.FileType.REGULAR && is_valid_file_type(file_info.get_name())) {
					index++;
				}
				else if(file_info.get_file_type() == GLib.FileType.DIRECTORY)
					count_music_files(GLib.File.new_for_path(file_path));
			}
		}
		catch(GLib.Error err) {
			stdout.printf("Could not pre-scan music folder. Progress percentage may be off: %s\n", err.message);
		}
        
        return index;
	}
	
	public void get_music_files(GLib.File music_folder, ref LinkedList<Song> songs, ref LinkedList<string> not_imported) {
		GLib.FileInfo file_info = null;
		
		try {
			var enumerator = music_folder.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
			while ((file_info = enumerator.next_file ()) != null) {
				var file_path = music_folder.get_path() + "/" + file_info.get_name();
				
				if(file_info.get_file_type() == GLib.FileType.REGULAR && is_valid_file_type(file_info.get_name())) {
					++index;
					fo_progress(null, (double)((double)index)/((double)item_count));
					
					Song s = import_song(file_path);
					
					if(s != null) {
						songs.add(s);
					}
					else
						not_imported.add(file_path);
				}
				else if(file_info.get_file_type() == GLib.FileType.DIRECTORY){
					get_music_files(GLib.File.new_for_path(file_path), ref songs, ref not_imported);
				}
			}
		}
		catch(GLib.Error err) {
			stdout.printf("Could not get music: %s\n", err.message);
		}
	}
	
	public void get_music_files_individually(LinkedList<string> files, ref LinkedList<Song> songs, ref LinkedList<string> not_imported) {
		foreach(string file in files) {
			try {
				GLib.File gio_file = GLib.File.new_for_uri(file);
				FileInfo file_info = gio_file.query_info("*", FileQueryInfoFlags.NONE);
				string file_path = gio_file.get_path();
				
				if(file_info.get_file_type() == GLib.FileType.REGULAR && is_valid_file_type(file_info.get_name())) {
					++index;
					fo_progress(null, (double)((double)index)/((double)item_count));
					
					Song s = import_song(file_path);
					
					if(s != null) {
						songs.add(s);
					}
					else
						not_imported.add(file_path);
				}
				else if(file_info.get_file_type() == GLib.FileType.DIRECTORY){
					get_music_files(GLib.File.new_for_path(file_path), ref songs, ref not_imported);
				}
			}
			catch(GLib.Error err) {
				stdout.printf("Could not get song %s: %s\n", file, err.message);
			}
		}
	}
        
	/** rescans the music folder to update the db to the folder situation.
	 * If song is in folder, and in db, re-add
	 * If song is not in folder and in db,remove
	 * If song is in both, do nothing.
	 * @param music_folder The folder to rescan
	 * @param current_song_paths Paths of files already in db. once file
	 * is re-added, set string to "ADDED". at end, remove all songs that
	 * are not re-added.
	 * @return file paths of songs no longer available. TODO: should out that
	 */
	public void rescan_music(GLib.File music_folder, ref LinkedList<string> current_song_paths, ref LinkedList<string> not_imported, ref LinkedList<Song> new_songs) {
		GLib.FileInfo file_info = null;
		
		int songs_added = 0;
		try {
			var enumerator = music_folder.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
			while ((file_info = enumerator.next_file ()) != null) {
				var file_path = music_folder.get_path() + "/" + file_info.get_name();
				
				fo_progress(null, (double)((double)index)/((double)item_count));
				
				if(file_info.get_file_type() == GLib.FileType.REGULAR && is_valid_file_type(file_info.get_name())) {
					if(current_song_paths.contains(file_path)) {
						current_song_paths.remove(file_path);
							
						++index;
					}
					else if(!current_song_paths.contains(file_path)) {
						Song s = import_song(file_path);
						
						if(s != null) {
							new_songs.add(s);
						}
						else
							not_imported.add(file_path);
						
						++songs_added;
					}
				}
				else if(file_info.get_file_type() == GLib.FileType.DIRECTORY){
					rescan_music(GLib.File.new_for_path(file_path), ref current_song_paths, ref not_imported, ref new_songs);
				}
			}
		}
		catch(GLib.Error err) {
			stdout.printf("Could not rescan music folder: %s\n", err.message);
		}
	}
	
	public Song? import_song(string file_path) {
		Song s = new Song(file_path);
		TagLib.File tag_file;
		
		tag_file = new TagLib.File(file_path);
		
		if(tag_file != null && tag_file.tag != null && tag_file.audioproperties != null) {
			try {
				s.title = tag_file.tag.title;
				s.artist = tag_file.tag.artist;
				s.album = tag_file.tag.album;
				s.genre = tag_file.tag.genre;
				s.comment = tag_file.tag.comment;
				s.year = (int)tag_file.tag.year;
				s.track = (int)tag_file.tag.track;
				s.bitrate = tag_file.audioproperties.bitrate;
				s.length = tag_file.audioproperties.length;
				s.samplerate = tag_file.audioproperties.samplerate;
				s.date_added = (int)time_t();
				
				/* get the size and convert to MB */
				s.file_size = (int)(GLib.File.new_for_path(file_path).query_info("*", FileQueryInfoFlags.NONE).get_size()/1000000);
				
			}
			finally {
				if(s.title == null || s.title == "") {
					string[] paths = file_path.split("/", 0);
					s.title = paths[paths.length - 1];
				}
				if(s.artist == null || s.artist == "") s.artist = "Unknown";
			}
		}
		else {
			return null;
		}
		
		return s;
	}
	
	private bool is_image_file_type(string type) {
		return (type.has_suffix(".jpg") || type.has_suffix(".png"));
	}
	
	//use gio.file.get_parent() instead
	public static string get_folder(string file) {
		string[] paths = file.split("/", 0);
		
		//this makes it work correctly for all cases
		if(!file.has_suffix("/"))
			paths += " ";
		
		string folder_string = "";
		for(int index = 0; index < paths.length - 2;++index)
			folder_string += paths[index] + "/";
			
		return folder_string;
	}
	
	public string? find_album(Song s) {
		string album_folder_string = get_folder(s.file);
		GLib.File album_folder = GLib.File.new_for_path(album_folder_string);
		
		//now search this folder for an .jpg or .png
		GLib.FileInfo file_info = null;
		
		try {
			var enumerator = album_folder.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
			while ((file_info = enumerator.next_file ()) != null) {
				var file_path = album_folder.get_path() + "/" + file_info.get_name();
				
				if(file_info.get_file_type() == GLib.FileType.REGULAR && is_image_file_type(file_info.get_name()) && s.album in file_info.get_name()) {
					return file_path;
				}
			}
		}
		catch(GLib.Error err) {
			stdout.printf("Could not find album artwork: %s\n", err.message);
		}
		
		return null;
	}
	
	public Gdk.Pixbuf? save_album(Song s, string uri) {
		Gdk.Pixbuf rv;
		
		if(uri == null || uri == "") {
			return null;
		}
		
		GLib.File file = GLib.File.new_for_uri(uri);
		if(file == null) {
			return null;
		}
		
		FileInputStream filestream;
		
		try {
			filestream = file.read(null);
			rv = new Gdk.Pixbuf.from_stream(filestream, null);
			rv.save(get_folder(s.file) + s.album.replace("/", "_") + ".jpg", "jpeg");
		}
		catch(GLib.Error err) {
			rv = null;
		}
		
		return rv;
	}
	
	public string? find_artist_image(Song s) {
		// get the folder of the folder
		string artist_folder_string = get_folder(get_folder(s.file));
		GLib.File artist_folder = GLib.File.new_for_path(artist_folder_string);
		GLib.FileInfo file_info = null;
		
		try {
			var enumerator = artist_folder.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
			while ((file_info = enumerator.next_file ()) != null) {
				var file_path = artist_folder.get_path() + "/" + file_info.get_name();
				
				if(file_info.get_file_type() == GLib.FileType.REGULAR && is_image_file_type(file_info.get_name())) {
					return file_path;
				}
			}
		}
		catch(GLib.Error err) {
			stdout.printf("Could not find artist image: %s\n", err.message);
		}	
		
		return null;
	}
	
	public Gdk.Pixbuf? save_artist_image(Song s, string uri) {
		Gdk.Pixbuf rv;
		
		if(uri == null || uri == "") {
			return null;
		}
		
		GLib.File file = GLib.File.new_for_uri(uri);
		FileInputStream filestream;
		
		try {
			filestream = file.read(null);
			rv = new Gdk.Pixbuf.from_stream(filestream, null);
			rv.save(get_folder(get_folder(s.file)) + s.artist + ".jpg", "jpeg");
		}
		catch(GLib.Error err) {
			rv = null;
		}
		
		return rv;
	}
	
	public void save_songs(Collection<Song> to_save) {
		foreach(Song s in to_save) {
			if(!(toSave.contains(s)))
				toSave.offer(s);
		}
		
		if(!inThread) {
			try {
				inThread = true;
				Thread.create<void*>(save_song_thread, false);
			}
			catch(GLib.Error err) {
				stdout.printf("Could not create thread to rescan music folder: %s\n", err.message);
			}
		}
	}
        
	public void* save_song_thread () {
		while(true) {
			Song s = toSave.poll();
			
			if(s == null) {
				inThread = false;
				return null;
			}
			
			TagLib.File tag_file;
			
			stdout.printf("Saving file %s \n", s.file);
			tag_file = new TagLib.File(s.file);
			
			if(tag_file != null && tag_file.tag != null && tag_file.audioproperties != null) {
				try {
					tag_file.tag.title = s.title;
					tag_file.tag.artist = s.artist;
					tag_file.tag.album = s.album;
					tag_file.tag.genre = s.genre;
					tag_file.tag.comment = s.comment;
					tag_file.tag.year = s.year;
					tag_file.tag.track  = s.track;
					
					tag_file.save();
				}
				finally {
					
				}
			}
			else {
				stdout.printf("Could not save %s.\n", s.file);
			}
			
			if(settings.getUpdateFolderHierarchy())
				update_file_hierarchy(s, true);
		}
	}
	
	public void update_file_hierarchy(Song s, bool delete_old) {
		try {
			/* initialize file objects */
			var original = GLib.File.new_for_path(s.file);
			var file_info = original.query_info ("*", FileQueryInfoFlags.NONE, null);
			var dest = GLib.File.new_for_path(settings.getMusicFolder() + "/" + s.artist.replace("/", "_") + "/" + s.album.replace("/", "_") + "/" + file_info.get_name());
			
			if(original.get_path() == dest.get_path())
				return;
			
			/* make sure that the parent folders exist */
			if(!dest.get_parent().get_parent().query_exists()) {
				stdout.printf("artist folder %s does not exist\n", dest.get_parent().get_parent().get_path());
				
				try {
					dest.get_parent().get_parent().make_directory(null);
					dest.get_parent().make_directory(null);
				}
				catch(GLib.Error err) {
					stdout.printf("Could not create folder to copy to: %s\n", err.message);
					// does it make sense to return here?
				}
			}
			else if(!dest.get_parent().query_exists()) {
				stdout.printf("album folder %s does not exist\n", dest.get_parent().get_path());
				
				try {
					dest.get_parent().make_directory(null);
				}
				catch(GLib.Error err) {
					stdout.printf("Could not create folder to copy to: %s\n", err.message);
					// does it make sense to return here?
				}
			}
			
			/* copy the file over */
			bool success = false;
			if(!delete_old) {
				stdout.printf("Copying %s to %s\n", s.file, dest.get_path());
				success = original.copy(dest, FileCopyFlags.NONE, null, null);
			}
			else {
				stdout.printf("Moving %s to %s\n", s.file, dest.get_path());
				success = original.move(dest, FileCopyFlags.NONE, null, null);
			}
			
			if(success)
				s.file = dest.get_path();
			else
				stdout.printf("Failure: Could not copy imported song %s to media folder %s\n", s.file, dest.get_path());
			
			/* if we are supposed to delete the old, make sure there are no items left in folder if we do */
			if(delete_old) {
				var old_folder_items = count_music_files(original.get_parent());
				
				if(old_folder_items == 0) {
					stdout.printf("going to delete %s because no files are in it\n", original.get_parent().get_path());
					original.get_parent().delete();
				}
			}
		}
		catch(GLib.Error err) {
			stdout.printf("Could not copy imported song %s to media folder: %s\n", s.file, err.message);
		}
	}
	
	public void remove_songs(Collection<string> toRemove) {
		foreach(string s in toRemove) {
			try {
				var file = GLib.File.new_for_path(s);
				file.trash();
				
				var old_folder_items = count_music_files(file.get_parent());
					
				//TODO: COPY ALBUM AND IMAGE ARTWORK
				if(old_folder_items == 0) {
					stdout.printf("going to delete %s because no files are in it\n", file.get_parent().get_path());
					//original.get_parent().delete();
					
					var old_folder_parent_items = count_music_files(file.get_parent().get_parent());
					
					if(old_folder_parent_items == 0) {
						stdout.printf("going to delete %s because no files are in it\n", file.get_parent().get_parent().get_path());
					}
				}
			}
			catch(GLib.Error err) {
				stdout.printf("Could not move file %s to trash: %s (you could be using a file system which is not supported)\n", s, err.message);
				
				//tell the user the file could not be moved and ask if they'd like to delete permanently instead.
				Gtk.MessageDialog md = new Gtk.MessageDialog(lm.lw, Gtk.DialogFlags.MODAL, Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, "Could not trash file %s, would you like to permanently delete it? You cannot undo these changes.", s);
			}
		}
	}
}
