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

public class BeatBox.Playlist : Object {
	private string _name;
	public TreeViewSetup tvs;
	private int _rowid;
	private Gee.LinkedList<Song> _songs; // hold title, artist, album
	
	public Playlist() {
		_name = "New Playlist";
		tvs = new TreeViewSetup("#", Gtk.SortType.ASCENDING, MusicTreeView.Hint.PLAYLIST);
		_songs = new Gee.LinkedList<Song>();
	}
	
	public Playlist.with_info(int rowid, string name) {
		_songs = new Gee.LinkedList<Song>();
		tvs = new TreeViewSetup("#", Gtk.SortType.ASCENDING, MusicTreeView.Hint.PLAYLIST);
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
	
	public Gee.LinkedList<Song> songs() {
		return _songs;
	}
	
	public void addSong(Song s) {
		_songs.add(s);
	}
	
	public void removeSong(Song s) {
		foreach(Song t in _songs) {
			if(t.title == s.title && t.artist == s.artist && t.album == s.album) {
				_songs.remove(t);
				break;
			}
		}
	}
	
	public void clear() {
		_songs.clear();
	}
	
	public void songs_from_string(string songs) {
		string[] song_strings = songs.split("<song_seperator>", 0);
		
		int index;
		for(index = 0; index < song_strings.length - 1; ++index) {
			string[] pieces_of_song = song_strings[index].split("<value_seperator>", 0);
			
			Song s = new Song("");
			s.title = pieces_of_song[0];
			s.artist = pieces_of_song[1];
			s.album = pieces_of_song[2];
			
			addSong(s);
		}
	}
	
	public string songs_to_string() {
		string rv = "";
		
		foreach(Song s in _songs) {
			rv += s.title + "<value_seperator>" + s.artist + "<value_seperator>" + s.album + "<song_seperator>";
		}
		
		return rv;
	}
	
	public Gee.LinkedList<int> analyze(LibraryManager lm) {
		Gee.LinkedList<int> rv = new Gee.LinkedList<int>();
		stdout.printf("analyzing playlist\n");
		// TODO: prevent adding duplicates multiple times
		foreach(Song s in lm.songs()) {
			foreach(Song l in this._songs) {
				if(s.title == l.title && s.artist == l.artist && s.album == l.album) {
					rv.add(s.rowid);
					break;
				}
			}
		}
		stdout.printf("playlist analyzed\n");
		return rv;
	}
}
