/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
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

using TagLib;
using GLib;
using Gee;

public class BeatBox.FileOperator : Object {
	private BeatBox.LibraryManager lm;
	private BeatBox.Settings settings;
	
	bool inThread;
	LinkedList<Song> toSave;
	
	public int index;
	public int item_count;
	public signal void fo_progress(string? message, double progress);
	public signal void import_cancelled();
	public signal void rescan_cancelled();
	
	public bool cancelled; // set to true if user cancels
	bool cancelSent; // needed to not send cancel signal twice (in recursive function)
	
	public FileOperator(BeatBox.LibraryManager lmm, BeatBox.Settings sett) {
		lm = lmm;
		settings = sett;
		inThread = false;
		toSave = new LinkedList<Song>();
		cancelled = false;
		cancelSent = false;
		
		lm.progress_cancel_clicked.connect( () => { cancelled = true; } );
	}
	
	public void resetProgress(int items) {
		index = 0;
		item_count = items;
		cancelled = false;
		cancelSent = false;
	}
	
	private static bool is_valid_file_type(string type) {
		var typeDown = type.down();
		
		return (typeDown.has_suffix(".mp3") || typeDown.has_suffix(".m4a") || 
				typeDown.has_suffix(".wma") || typeDown.has_suffix(".ogg") || 
				typeDown.has_suffix(".flac") || typeDown.has_suffix(".mp4") || 
				typeDown.has_suffix(".oga") || typeDown.has_suffix(".m4p") ||
				typeDown.has_suffix(".aac") || typeDown.has_suffix(".alac"));
	}
	
	private static bool is_valid_image_type(string type) {
		var typeDown = type.down();
		
		return (typeDown.has_suffix(".jpg") || typeDown.has_suffix(".jpeg") ||
				typeDown.has_suffix(".png"));
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
				else if(file_info.get_file_type() == GLib.FileType.DIRECTORY) {
					count_music_files(GLib.File.new_for_path(file_path));
				}
			}
		}
		catch(GLib.Error err) {
			stdout.printf("Could not pre-scan music folder. Progress percentage may be off: %s\n", err.message);
		}
        
        return index;
	}
	
	public void get_music_files_set(GLib.File music_folder, ref LinkedList<Song> songs, ref LinkedList<string> not_imported) {
		GLib.FileInfo file_info = null;
		string artPath = "";
		
		if(cancelled) {
			return;
		}
		
		try {
			/* get a list of all images in folder as potential album art choices */
			var image_list = new LinkedList<string>();
			var enumerator = music_folder.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
			while ((file_info = enumerator.next_file ()) != null) {
				
				if(file_info.get_file_type() == GLib.FileType.REGULAR && is_valid_image_type(file_info.get_name())) {
					image_list.add(file_info.get_name());
				}
			}
			
			/* now choose one based on priorities */
			foreach(string sU in image_list) {
				var s = sU.down();
				if(s.contains("folder.")) {
					artPath = music_folder.get_path() + "/" + sU;
					break;
				}
				else if(s.contains("cover."))
					artPath = music_folder.get_path() + "/" + sU;
				else if(!artPath.contains("cover.") && s.contains("album."))
					artPath = music_folder.get_path() + "/" + sU;
				else if(artPath == "")
					artPath = music_folder.get_path() + "/" + sU;
			}
			
			enumerator = music_folder.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
			while ((file_info = enumerator.next_file ()) != null) {
				var file_path = music_folder.get_path() + "/" + file_info.get_name();
				
				if(file_info.get_file_type() == GLib.FileType.REGULAR && is_valid_file_type(file_info.get_name())) {
					++index;
					
					Song s = import_song(file_path);
					
					if(s != null) {
						songs.add(s);
						
						if(songs.size % 500 == 0) {
							lm.add_songs(songs, true);
							
							songs.clear();
						}
						
						s.setAlbumArtPath(artPath);
					}
					else
						not_imported.add(file_path);
				}
				else if(file_info.get_file_type() == GLib.FileType.DIRECTORY){
					get_music_files_set(GLib.File.new_for_path(file_path), ref songs, ref not_imported);
				}
			}
		}
		catch(GLib.Error err) {
			stdout.printf("Could not get music: %s\n", err.message);
		}
	}
	
	public void get_music_files_folder(GLib.File music_folder, ref LinkedList<Song> songs, ref LinkedList<string> not_imported) {
		GLib.FileInfo file_info = null;
		string artPath = "";
		
		if(cancelled) {
			return;
		}
		
		try {
			/* get a list of all images in folder as potential album art choices */
			var image_list = new LinkedList<string>();
			var enumerator = music_folder.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
			while ((file_info = enumerator.next_file ()) != null) {
				
				if(file_info.get_file_type() == GLib.FileType.REGULAR && is_valid_image_type(file_info.get_name())) {
					image_list.add(file_info.get_name());
				}
			}
			
			/* now choose one based on priorities */
			foreach(string sU in image_list) {
				var s = sU.down();
				if(s.contains("folder.")) {
					artPath = music_folder.get_path() + "/" + sU;
					break;
				}
				else if(s.contains("cover."))
					artPath = music_folder.get_path() + "/" + sU;
				else if(!artPath.contains("cover.") && s.contains("album."))
					artPath = music_folder.get_path() + "/" + sU;
				else if(artPath == "")
					artPath = music_folder.get_path() + "/" + sU;
			}
				
			enumerator = music_folder.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
			while ((file_info = enumerator.next_file ()) != null) {
				var file_path = music_folder.get_path() + "/" + file_info.get_name();
				
				if(file_info.get_file_type() == GLib.FileType.REGULAR && is_valid_file_type(file_info.get_name())) {
					++index;
					
					Song s = import_song(file_path);
					
					if(s != null) {
						songs.add(s);
						s.setAlbumArtPath(artPath);
					}
					else
						not_imported.add(file_path);
				}
				else if(file_info.get_file_type() == GLib.FileType.DIRECTORY){
					get_music_files_folder(GLib.File.new_for_path(file_path), ref songs, ref not_imported);
				}
			}
		}
		catch(GLib.Error err) {
			stdout.printf("Could not get music: %s\n", err.message);
		}
	}
	
	public void get_music_files_individually(LinkedList<string> paths, ref LinkedList<Song> songs, ref LinkedList<string> not_imported) {
		foreach(string file in paths) {
			
			if(cancelled) {
				return;
			}
			
			try {
				GLib.File gio_file = GLib.File.new_for_path(file);
				FileInfo file_info = gio_file.query_info("*", FileQueryInfoFlags.NONE);
				string file_path = gio_file.get_path();
				
				if(file_info.get_file_type() == GLib.FileType.REGULAR && is_valid_file_type(file_info.get_name())) {
					++index;
					
					Song s = import_song(file_path);
					
					if(s != null) {
						songs.add(s);
					}
					else
						not_imported.add(file_path);
				}
				else if(file_info.get_file_type() == GLib.FileType.DIRECTORY){
					get_music_files_folder(GLib.File.new_for_path(file_path), ref songs, ref not_imported);
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
		string current_artist = "";
		string current_album = ""; // these are purposely reset on recursive call
		string artPath = "";
		
		if(cancelled) {
			return;
		}
			
		
		int songs_added = 0;
		try {
			/* get a list of all images in folder as potential album art choices */
			var image_list = new LinkedList<string>();
			var enumerator = music_folder.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
			while ((file_info = enumerator.next_file ()) != null) {
				
				if(file_info.get_file_type() == GLib.FileType.REGULAR && is_valid_image_type(file_info.get_name())) {
					image_list.add(file_info.get_name());
				}
			}
			
			/* now choose one based on priorities */
			foreach(string sU in image_list) {
				var s = sU.down();
				if(s.contains("folder.")) {
					artPath = music_folder.get_path() + "/" + sU;
					break;
				}
				else if(s.contains("cover."))
					artPath = music_folder.get_path() + "/" + sU;
				else if(!artPath.contains("cover.") && s.contains("album."))
					artPath = music_folder.get_path() + "/" + sU;
				else if(artPath == "")
					artPath = music_folder.get_path() + "/" + sU;
			}
				
			enumerator = music_folder.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
			while ((file_info = enumerator.next_file ()) != null) {
				var file_path = music_folder.get_path() + "/" + file_info.get_name();
				
				if(file_info.get_file_type() == GLib.FileType.REGULAR && is_valid_file_type(file_info.get_name())) {
					if(current_song_paths.contains(file_path)) {
						current_song_paths.remove(file_path);
						
						++index;
					}
					else if(!current_song_paths.contains(file_path)) {
						Song s = import_song(file_path);
						
						if(s != null) {
							new_songs.add(s);
							current_artist = s.artist;
							current_album = s.album;
							
							s.setAlbumArtPath(artPath);
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
				
				s.album_artist = s.artist;
				s.album_number = 1;
			}
		}
		else {
			return null;
		}
		
		return s;
	}
	
	public void save_album(Song s, string uri) {
		if(uri == null || uri == "") {
			return;
		}
		
		GLib.File file = GLib.File.new_for_uri(uri);
		if(file == null) {
			return;
		}
		
		FileInputStream filestream;
		
		try {
			Gdk.Pixbuf rv;
			filestream = file.read(null);
			rv = new Gdk.Pixbuf.from_stream(filestream, null);
			var dest = Path.build_path("/", GLib.File.new_for_path(s.file).get_parent().get_path(), "Album.jpg");
			rv.save(dest, "jpeg");
			
			Gee.LinkedList<Song> updated_songs = new Gee.LinkedList<Song>();
			foreach(int i in lm.song_ids()) {
				if(lm.song_from_id(i).artist == s.artist && lm.song_from_id(i).album == s.album) { 
					stdout.printf("setting album art for %s by %s\n", lm.song_from_id(i).title, lm.song_from_id(i).artist);
					lm.song_from_id(i).setAlbumArtPath(dest);
					updated_songs.add(lm.song_from_id(i));
				}
			}
			
			lm.update_songs(updated_songs, false, false);
			
			// for sound menu (dbus doesn't like linked lists)
			if(updated_songs.contains(lm.song_info.song))
				lm.update_song(lm.song_info.song, false, false);
		}
		catch(GLib.Error err) {
			stdout.printf("Could not save album to file: %s\n", err.message);
		}
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
			rv.save(Path.build_path("/", GLib.File.new_for_path(s.file).get_parent().get_parent().get_path(), "Artist.jpg"), "jpeg");
		}
		catch(GLib.Error err) {
			rv = null;
		}
		
		return rv;
	}
	
	public void save_songs(Collection<Song> to_save) {
		foreach(Song s in to_save) {
			if(!(toSave.contains(s)) && !s.isTemporary && !s.isPreview && s.file.has_prefix(lm.settings.getMusicFolder()))
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
				update_file_hierarchy(s, true, false);
		}
	}
	
	public GLib.File get_new_destination(Song s) {
		GLib.File dest;
		
		try {
			/* initialize file objects */
			GLib.File original;
			if(s.file.has_prefix("http://"))
				original = GLib.File.new_for_uri(s.file);
			else
				original = GLib.File.new_for_path(s.file);
			
			var ext = get_extension(s.file);
			
			dest = GLib.File.new_for_path(Path.build_path("/", settings.getMusicFolder(), s.artist.replace("/", "_"), s.album.replace("/", "_"), s.track.to_string() + " " + s.title.replace("/", "_") + ext));
			
			if(original.get_path() == dest.get_path()) {
				stdout.printf("File is already in correct location\n");
				return null;
			}
			
			string extra = "";
			while((dest = GLib.File.new_for_path(Path.build_path("/", settings.getMusicFolder(), s.artist.replace("/", "_"), s.album.replace("/", "_"), s.track.to_string() + " " + s.title.replace("/", "_") + extra + ext))).query_exists()) {
				extra += "_";
			}
			
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
		}
		catch(GLib.Error err) {
			stdout.printf("Could not find new destination!: %s\n", err.message);
		}
		
		return dest;
	}
	
	public void update_file_hierarchy(Song s, bool delete_old, bool emit_update) {
		try {
			GLib.File dest = get_new_destination(s);
			
			if(dest == null)
				return;
			
			GLib.File original;
			if(s.file.has_prefix("http://"))
				original = GLib.File.new_for_uri(s.file);
			else
				original = GLib.File.new_for_path(s.file);
			
			var ext = get_extension(s.file);
			
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
			
			if(success) {
				stdout.printf("success copying file\n");
				s.file = dest.get_path();
				
				// wait to update song when out of thread
				if(emit_update) {
					Idle.add( () => {
						lm.update_song(s, false, false); return false;
					});
				}
				
				if(original.get_uri().has_prefix("file://") && original.get_parent().get_path() != null &&
				s.getAlbumArtPath().contains(original.get_parent().get_path())) {
					var songFile = GLib.File.new_for_path(s.getAlbumArtPath());
					var albumArtDest = Path.build_path("/", dest.get_parent().get_path(), "Album.jpg");
					
					if(!GLib.File.new_for_path(albumArtDest).query_exists() && songFile.query_exists() &&
					songFile.copy(GLib.File.new_for_path(albumArtDest), FileCopyFlags.NONE, null, null)) {
						stdout.printf("Copying album art to %s\n", albumArtDest);
						s.setAlbumArtPath(albumArtDest);
					}
				}
			}
			else
				stdout.printf("Failure: Could not copy imported song %s to media folder %s\n", s.file, dest.get_path());
			
			/* if we are supposed to delete the old, make sure there are no items left in folder if we do */
			if(delete_old) {
				var old_folder_items = count_music_files(original.get_parent());
				// must check for .jpg's as well.
				
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
				//Gtk.MessageDialog md = new Gtk.MessageDialog(lm.lw, Gtk.DialogFlags.MODAL, Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, "Could not trash file %s, would you like to permanently delete it? You cannot undo these changes.", s);
			}
		}
	}
	
	public static void guess_content_type(GLib.File root, ref int audio, ref int other) {
		GLib.FileInfo file_info = null;
		
		try {
			var enumerator = root.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
			while ((file_info = enumerator.next_file ()) != null) {
				var file_path = root.get_path() + "/" + file_info.get_name();
				
				if(file_info.get_file_type() == GLib.FileType.REGULAR && is_valid_file_type(file_info.get_name())) {
					++audio;
				}
				else if(file_info.get_file_type() == GLib.FileType.REGULAR) {
					++other;
				}
				else if(file_info.get_file_type() == GLib.FileType.DIRECTORY)
					guess_content_type(GLib.File.new_for_path(file_path), ref audio, ref other);
			}
		}
		catch(GLib.Error err) {
			stdout.printf("Could not guess content types: %s\n", err.message);
		}
	}
	
	public string get_extension(string name) {
		return name.slice(name.last_index_of(".", 0), name.length);
	}
	
	/* should be called from thread */
	public Playlist import_from_playlist_file_info(string name, LinkedList<string> paths, ref LinkedList<Song> new_songs, ref LinkedList<string> not_imported) {
		Playlist rv = new Playlist();
		var internals = new LinkedList<int>();
		var externals = new LinkedList<string>();
		
		foreach(string path in paths) {
			Song s;
			if( (s = lm.song_from_file(path)) != null)
				internals.add(s.rowid);
			else
				externals.add(path);
		}
		
		rv.name = name;
		foreach(int i in internals)
			rv.addSong(i);
		
		/* this is pretty much copied from lm.import_files_individually */
		// first get the files
		bool was_cancelled = cancelled;
		resetProgress(externals.size - 1);
		Timeout.add(500, lm.doProgressNotificationWithTimeout);
		
		get_music_files_individually(externals, ref new_songs, ref not_imported);
		
		//add to library
		lm.add_songs(new_songs, true);
		foreach(var s in new_songs)
			rv.addSong(s.rowid);
		
		// now copy them into the library (if settings say to)
		resetProgress(new_songs.size);
		if(settings.getCopyImportedMusic())
			lm.progress_notification("<b>Copying</b> files to <b>Music Folder</b>...", 0.0);
		
		Timeout.add(500, lm.doProgressNotificationWithTimeout);
		
		foreach(Song s in new_songs) {
			if(settings.getCopyImportedMusic() && !was_cancelled)
				update_file_hierarchy(s, false, false);
			
			index++;
		}
		
		lm.file_operations_done();
		
		return rv;
	}
}
