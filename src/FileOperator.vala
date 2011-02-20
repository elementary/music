using TagLib;
using Gee;

public class BeatBox.FileOperator : Object {
	private BeatBox.LibraryManager lm;
	private BeatBox.Settings settings;
	
	Song temp_song;
	
	int index;
	int item_count;
	public signal void fo_progress(string message, double progress);
	
	public FileOperator(BeatBox.LibraryManager lmm, BeatBox.Settings sett) {
		lm = lmm;
		settings = sett;
	}
	
	public void resetProgress(int items) {
		index = 0;
		item_count = items;
	}
	
	private bool is_valid_file_type(string type) {
		return (type.has_suffix(".mp3") || type.has_suffix(".m4a") || type.has_suffix(".wma") || type.has_suffix(".flac") || type.has_suffix(".mp4"));
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
        
        return (index != 0) ? index : 1000;
	}
	
	public void get_music_files(GLib.File music_folder, ref LinkedList<Song> songs, ref LinkedList<string> not_imported) {
		GLib.FileInfo file_info = null;
		TagLib.File tag_file;
		
		try {
			var enumerator = music_folder.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
			while ((file_info = enumerator.next_file ()) != null) {
				var file_path = music_folder.get_path() + "/" + file_info.get_name();
				
				if(file_info.get_file_type() == GLib.FileType.REGULAR && is_valid_file_type(file_info.get_name())) {
					++index;
					fo_progress(null, (double)((double)index)/((double)item_count));
					
					Song s = import_song(file_path);
					
					if(s != null)
							songs.add(s);
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
	public void rescan_music(GLib.File music_folder, ref LinkedList<string> current_song_paths, ref LinkedList<string> not_imported) {
		GLib.FileInfo file_info = null;
		TagLib.File tag_file;
		
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
						
						if(s != null)
							lm.add_song(s);
						else
							not_imported.add(file_path);
						
						++songs_added;
					}
				}
				else if(file_info.get_file_type() == GLib.FileType.DIRECTORY){
					rescan_music(GLib.File.new_for_path(file_path), ref current_song_paths, ref not_imported);
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
		
		//db_progress("Adding file " + file_path, 0.0);
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
			}
			finally {
				if(s.title == null || s.title == "") s.title = "Unkown";
				if(s.artist == null || s.artist == "") s.artist = "Unkown";
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
		var enumerator = album_folder.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
		while ((file_info = enumerator.next_file ()) != null) {
			var file_path = album_folder.get_path() + "/" + file_info.get_name();
			
			if(file_info.get_file_type() == GLib.FileType.REGULAR && is_image_file_type(file_info.get_name())) {
				return file_path;
			}
		}
		
		return null;
	}
	
	public Gdk.Pixbuf? save_album(Song s, string uri) {
		Gdk.Pixbuf rv;
		
		if(uri == null || uri == "") {
			return null;
		}
		
		GLib.File file = GLib.File.new_for_uri(uri);
		FileInputStream filestream;
		
		try {
			filestream = file.read(null);
			rv = new Gdk.Pixbuf.from_stream_at_scale(filestream, 200, 200, true, null);
			
			string option_keys;
			string option_values;
			rv.savev(get_folder(s.file) + s.album + ".jpg", "jpeg", out option_keys, out option_values);
		}
		catch(GLib.Error err) {
			stdout.printf("Could not save album art from %s: %s\n", uri, err.message);
			rv = null;
		}
		
		return rv;
	}
	
	public string? find_artist_image(Song s) {
		// get the folder of the folder
		string artist_folder_string = get_folder(get_folder(s.file));
		GLib.File artist_folder = GLib.File.new_for_path(artist_folder_string);
		
		//now search this folder for an .jpg or .png
		GLib.FileInfo file_info = null;
		var enumerator = artist_folder.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
		while ((file_info = enumerator.next_file ()) != null) {
			var file_path = artist_folder.get_path() + "/" + file_info.get_name();
			
			if(file_info.get_file_type() == GLib.FileType.REGULAR && is_image_file_type(file_info.get_name())) {
				return file_path;
			}
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
			rv = new Gdk.Pixbuf.from_stream_at_scale(filestream, 200, 200, true, null);
			
			string option_keys;
			string option_values;
			rv.savev(get_folder(get_folder(s.file)) + s.artist + ".jpg", "jpeg", out option_keys, out option_values);
		}
		catch(GLib.Error err) {
			stdout.printf("Could not save artist image from %s: %s\n", uri, err.message);
			rv = null;
		}
		
		return rv;
	}
	
	public void save_song(Song s) {
		temp_song = s;
		
		try {
				Thread.create<void*>(save_song_thread, false);
		}
		catch(GLib.Error err) {
				stdout.printf("Could not create thread to rescan music folder: %s\n", err.message);
		}
	}
        
	public void* save_song_thread () {
		TagLib.File tag_file;
		
		stdout.printf("Saving file %s \n", temp_song.file);
		tag_file = new TagLib.File(temp_song.file);
		
		if(tag_file != null && tag_file.tag != null && tag_file.audioproperties != null) {
			try {
				tag_file.tag.title = temp_song.title;
				tag_file.tag.artist = temp_song.artist;
				tag_file.tag.album = temp_song.album;
				tag_file.tag.genre = temp_song.genre;
				tag_file.tag.comment = temp_song.comment;
				tag_file.tag.year = temp_song.year;
				tag_file.tag.track  = temp_song.track;
				
				tag_file.save();
			}
			finally {
				
			}
		}
		else {
			stdout.printf("Could not save %s.\n", temp_song.file);
		}
		
		return null;
	}
	
	public void update_file_hierarchy(Song s) {
		stdout.printf("TODO: Actually update file hierarchy based on artist and album\n");
		/** If there is a change, first make new folders and save to their. Then count number of files in
		 * old folder. if only the one we just moved, delete folders. Otherwise
		 * just delete the old file. Don't forget to move album and image artwork
		 */
	}
}
