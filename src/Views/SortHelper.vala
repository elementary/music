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

using Gtk;
using Gee;

public class BeatBox.SortHelper : GLib.Object {
	BeatBox.LibraryManager lm;
	
	public SortHelper(LibraryManager lm) {
		this.lm = lm;
	}
	
	public void loadSongs(TreeModel model, TreeIter a, TreeIter b, out Song a_song, out Song b_song) {
		int a_id, b_id;
		
		model.get(a, 0, out a_id);
		model.get(b, 0, out b_id);
		
		a_song = lm.song_from_id(a_id);
		b_song = lm.song_from_id(b_id);
	}
	
	/*public int trackCompareFunc(TreeModel model, TreeIter a, TreeIter b) {
		Song a_song, b_song;
		loadSongs(model, a, b, out a_song, out b_song);
		
		if(a_song.track == b_song.track)
			return (a_song.file.down() > b_song.file.down()) ? 1 : -1;
		else
			return (a_song.track > b_song.track) ? 1 : -1;
	}
	*/
	public int trackCompareFunc(TreeModel model, TreeIter a, TreeIter b) {
		Song a_song, b_song;
		loadSongs(model, a, b, out a_song, out b_song);
		
		if(a_song.track == b_song.track)
			return (a_song.file.down() > b_song.file.down()) ? 1 : -1;
		else
			return (a_song.track > b_song.track) ? 1 : -1;
	}
	
	public int artistCompareFunc(TreeModel model, TreeIter a, TreeIter b) {
		Song a_song, b_song;
		loadSongs(model, a, b, out a_song, out b_song);
		
		if(a_song.artist.down() == b_song.artist.down() && a_song.album.down() == b_song.album.down() && a_song.track == b_song.track)
			return (a_song.file.down() > b_song.file.down()) ? 1 : -1;
		else if(a_song.artist.down() == b_song.artist.down() && a_song.album.down() == b_song.album.down())
			return a_song.track - b_song.track;
		else if(a_song.artist.down() == b_song.artist.down())
			return (a_song.album.down() > b_song.album.down()) ? 1 : -1;
		else
			return (a_song.artist.down() > b_song.artist.down()) ? 1 : -1;
	}
	
	public int albumCompareFunc(TreeModel model, TreeIter a, TreeIter b) {
		Song a_song, b_song;
		loadSongs(model, a, b, out a_song, out b_song);
		
		if(a_song.album.down() == b_song.album.down() && a_song.track == b_song.track)
			return (a_song.file.down() > b_song.file.down()) ? 1 : -1;
		else if(a_song.album.down() == b_song.album.down())
			return a_song.track - b_song.track;
		else
			return (a_song.album.down() > b_song.album.down()) ? 1 : -1;
	}
}
