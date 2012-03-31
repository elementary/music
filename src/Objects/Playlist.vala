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
 
using Gee;

public class BeatBox.Playlist : Object {
	private string _name;
	public TreeViewSetup tvs;
	private int _rowid;
	private Gee.LinkedList<int> _medias;

	private ViewWrapper _view_wrapper;
	public ViewWrapper view_wrapper {
		get {
			return _view_wrapper;
		}
		set {
			if (_view_wrapper == null)
				_view_wrapper = value;
		}
	}

	public Playlist() {
		_name = "New Playlist";
		tvs = new TreeViewSetup("#", Gtk.SortType.ASCENDING, ViewWrapper.Hint.PLAYLIST);
		_medias = new Gee.LinkedList<int>();
	}
	
	public Playlist.with_info(int rowid, string name) {
		_medias = new Gee.LinkedList<int>();
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
	
	public Gee.LinkedList<int> medias() {
		return _medias;
	}
	
	public void addMedia(Collection<int> ids) {
		//if(!contains_media(id))
		foreach (int id in ids)
			_medias.add(id);

		if (view_wrapper != null)
			view_wrapper.add_media (ids);
	}
	
	public void removeMedia(Collection<int> ids) {
		foreach (int id in ids)
			_medias.remove(id);

		if (view_wrapper != null)
			view_wrapper.remove_media (ids);
	}
	
	public void clear() {
		_medias.clear();
		
		if (view_wrapper != null)
			view_wrapper.set_media (_medias);
	}
	
	public void medias_from_string(string medias, LibraryManager lm) {
		string[] media_strings = medias.split(",", 0);
		
		int index;
		var to_add = new LinkedList<int>();
		for(index = 0; index < media_strings.length - 1; ++index) {
			int id = int.parse(media_strings[index]);
			
			to_add.add (id);
		}

		addMedia (to_add);
	}
	
	public string medias_to_string(LibraryManager lm) {
		string rv = "";
		
		foreach(int id in _medias) {
			rv += id.to_string() + ",";
		}
		
		return rv;
	}
	
	public Gee.LinkedList<int> analyze(LibraryManager lm) {
		return _medias;
	}
	
	public bool contains_media(int i) {
		return _medias.contains(i);
	}
	
	public GPod.Playlist get_gpod_playlist() {
		GPod.Playlist rv = new GPod.Playlist(name, false);
		
		rv.sortorder = tvs.get_gpod_sortorder();
		
		return rv;
	}
	
	// how to specify a file?
	public bool save_playlist_m3u(LibraryManager lm, string folder) {
		bool rv = false;
		string to_save = "#EXTM3U";
		
		foreach(int i in _medias) {
			Media s = lm.media_from_id(i);
			
			to_save += "\n\n#EXTINF:" + s.length.to_string() + ", " + s.artist + " - " + s.title + "\n" + File.new_for_uri(s.uri).get_path();
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
	
	public bool save_playlist_pls(LibraryManager lm, string folder) {
		bool rv = false;
		string to_save = "[playlist]\n\nNumberOfEntries=" + _medias.size.to_string() + "\nVersion=2";
		
		int index = 1;
		foreach(int i in _medias) {
			Media s = lm.media_from_id(i);
			
			to_save += "\n\nFile" + index.to_string() + "=" + File.new_for_uri(s.uri).get_path() + "\nTitle" + index.to_string() + "=" + s.title + "\nLength" + index.to_string() + "=" + s.length.to_string();
			++index;
		}
		
		File dest = GLib.File.new_for_path(Path.build_path("/", folder, name.replace("/", "_") + ".pls"));
		try {
			// find a file path that doesn't exist
			string extra = "";
			while((dest = GLib.File.new_for_path(Path.build_path("/", folder, name.replace("/", "_") + extra + ".pls"))).query_exists()) {
				extra += "_";
			}
			
			var file_stream = dest.create(FileCreateFlags.NONE);
			
			// Write text data to file
			var data_stream = new DataOutputStream (file_stream);
			data_stream.put_string(to_save);
			rv = true;
		}
		catch(Error err) {
			stdout.printf("Could not save playlist %s to pls file %s: %s\n", name, dest.get_path(), err.message);
		}
		
		return rv;
	}
	
	public static bool parse_paths_from_m3u(LibraryManager lm, string path, ref Gee.LinkedList<string> locals, ref Gee.LinkedList<Media> stations) {
		// now try and load m3u file
		// if some files are not found by media_from_file(), ask at end if user would like to import the file to library
		// if so, just do import_individual_files
		// if not, do nothing and accept that music files are scattered.
		
		var file = File.new_for_path(path);
		if(!file.query_exists())
			return false;
		
		try {
			string line;
			string previous_line = "";
			var dis = new DataInputStream(file.read());
			
			while ((line = dis.read_line(null)) != null) {
				if(line.has_prefix("http:/")) {
					Media s = new Media(line);
					s.mediatype = 3;
					
					s.album_artist = "Radio Station";
					
					if(s.length <= 0)
						stations.add(s);
					else
						locals.add(line);
				}
				else if(line[0] != '#' && line.replace(" ", "").length > 0) {
					locals.add(line);
				}
				
				previous_line = line;
			}
		}
		catch(Error err) {
			stdout.printf("Could not load m3u file at %s: %s\n", path, err.message);
			return false;
		}
		
		return true;
	}
	
	public static bool parse_paths_from_pls(LibraryManager lm, string path, ref Gee.LinkedList<string> locals, ref Gee.LinkedList<Media> stations) {
		var files = new HashMap<int, string>();
		var titles = new HashMap<int, string>();
		var lengths = new HashMap<int, string>();
		
		var file = File.new_for_path(path);
		if(!file.query_exists())
			return false;
		
		try {
			string line;
			var dis = new DataInputStream(file.read());
			
			while ((line = dis.read_line(null)) != null) {
				if(line.has_prefix("File")) {
					parse_index_and_value("File", line, ref files);
				}
				else if(line.has_prefix("Title")) {
					parse_index_and_value("Title", line, ref titles);
				}
				else if(line.has_prefix("Length")) {
					parse_index_and_value("Length", line, ref lengths);
				}
			}
		}
		catch(Error err) {
			stdout.printf("Could not load m3u file at %s: %s\n", path, err.message);
			return false;
		}
		
		foreach(var entry in files.entries) {
			if(entry.value.has_prefix("http:/")/* && lengths.get(entry.key) != null && int.parse(lengths.get(entry.key)) <= 0*/)  {
				Media s = new Media(entry.value);
				s.mediatype = 3;
				s.album_artist = titles.get(entry.key);
				
				if(s.album_artist == null)
					s.album_artist = "Radio Station";
				
				stations.add(s);
			}
			else {
				locals.add(entry.value);
			}
		}
		
		
		return true;
	}
	
	public static void parse_index_and_value(string prefix, string line, ref HashMap<int, string> map) {
		int index;
		string val;
		string[] parts = line.split("=", 2);
		
		index = int.parse(parts[0].replace(prefix,""));
		val = parts[1];
		
		map.set(index, val);
	}
}
