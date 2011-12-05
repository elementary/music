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
			string[] pieces_of_song = song_strings[index].split("<value_seperator>", 0);

			Song s = lm.song_from_name(pieces_of_song[0], pieces_of_song[1]);
			addSong(s.rowid);
		}
	}
	
	public string songs_to_string(LibraryManager lm) {
		string rv = "";
		
		foreach(int id in _songs) {
			Song s = lm.song_from_id(id);
			rv += s.title + "<value_seperator>" + s.artist + "<song_seperator>";
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
}
