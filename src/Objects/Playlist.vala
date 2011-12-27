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

public class BeatBox.Playlist : Object {
	private string _name;
	public TreeViewSetup tvs;
	private int _rowid;
	private Gee.LinkedList<int> _songs;
	
	public Playlist() {
		_name = "New Playlist";
		tvs = new TreeViewSetup("#", Gtk.SortType.ASCENDING, ViewWrapper.Hint.PLAYLIST);
		_songs = new Gee.LinkedList<int>();
	}
	
	public Playlist.from_m3u(LibraryManager lm, string file) {
		_name = "New Playlist";
		tvs = new TreeViewSetup("#", Gtk.SortType.ASCENDING, ViewWrapper.Hint.PLAYLIST);
		_songs = new Gee.LinkedList<int>();
		
		// now try and load m3u file
		// if some files are not found by song_from_file(), ask at end if user would like to import the file to library
		// if so, just do import_individual_files
		// if not, do nothing and accept that music files are scattered. 
	}
	
	public Playlist.with_info(int rowid, string name) {
		_songs = new Gee.LinkedList<int>();
		tvs = new TreeViewSetup("#", Gtk.SortType.ASCENDING, ViewWrapper.Hint.PLAYLIST);
		_rowid = rowid;
		_name = name;
	}
	
	public int rowid {
		get { return _rowid; }
		set { _rowid = value; }
	}
	
	public string name {
		get {return _name; }
		set {_name = value; }
	}
	
	public Gee.LinkedList<int> songs() {
		return _songs;
	}
	
	public void addSong(int id) {
		if(!contains_song(id))
			_songs.add(id);
	}
	
	public void removeSong(int id) {
		_songs.remove(id);
	}
	
	public void clear() {
		_songs.clear();
	}
	
	public void songs_from_string(string songs, LibraryManager lm) {
		string[] song_strings = songs.split("<song_seperator>", 0);
		
		int index;
		for(index = 0; index < song_strings.length - 1; ++index) {
			int id = int.parse(song_strings[index]);
			
			addSong(id);
		}
	}
	
	public string songs_to_string(LibraryManager lm) {
		string rv = "";
		
		foreach(int id in _songs) {
			rv += id.to_string() + "<song_seperator>";
		}
		
		return rv;
	}
	
	public Gee.LinkedList<int> analyze(LibraryManager lm) {
		return _songs;
	}
	
	public bool contains_song(int i) {
		return _songs.contains(i);
	}
	
	public GPod.Playlist get_gpod_playlist() {
		GPod.Playlist rv = new GPod.Playlist(name, false);
		
		rv.sortorder = tvs.get_gpod_sortorder();
		
		return rv;
	}
	
	public bool save_playlist_m3u(LibraryManager lm, string folder) {
		bool rv = false;
		string to_save = "#EXTM3U";
		
		foreach(int i in _songs) {
			Song s = lm.song_from_id(i);
			
			to_save += "\n\n#EXTINF:" + s.length.to_string() + ", " + s.artist + " - " + s.title + "\n" + s.file;
		}
		
		File dest = GLib.File.new_for_path(Path.build_path("/", folder, name.replace("/", "_") + ".m3u"));
		try {
			// find a file path that doesn't exist
			string extra = "";
			while((dest = GLib.File.new_for_path(Path.build_path("/", folder, name.replace("/", "_") + extra + ".m3u"))).query_exists()) {
				extra += "_";
			}
			
			var file_stream = dest.create(FileCreateFlags.NONE);
			
			// Write text data to file
			var data_stream = new DataOutputStream (file_stream);
			data_stream.put_string(to_save);
			rv = true;
		}
		catch(Error err) {
			stdout.printf("Could not save playlist %s to m3u file %s: %s\n", name, dest.get_path(), err.message);
		}
		
		return rv;
	}
}
