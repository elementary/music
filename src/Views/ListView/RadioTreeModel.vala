/*-
 * Copyright (c) 2011-2012           Scott Ringwelski <sgringwe@mtu.edu>
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

using Gtk;
using Gee;
using GLib;

public class BeatBox.RadioTreeModel : BaseTreeModel {
	LibraryManager lm;
	GLib.Icon _playing;
	
	
	
	/* custom signals for custom treeview. for speed */
	public signal void rows_changed(LinkedList<TreePath> paths, LinkedList<TreeIter?> iters);
	public signal void rows_deleted (LinkedList<TreePath> paths);
	public signal void rows_inserted (LinkedList<TreePath> paths, LinkedList<TreeIter?> iters);
	
	/** Initialize data storage, columns, etc. **/
	public RadioTreeModel(LibraryManager lm, LinkedList<string> column_types) {
		this.lm = lm;
		_columns = column_types;
		_playing = Icons.MEDIA_PLAY_SYMBOLIC.get_gicon ();

		rows = new Sequence<int>();
	
		sort_column_id = -2;
		sort_direction = SortType.ASCENDING;
		column_sorts = new HashMap<int, CompareFuncHolder>();
	
		stamp = (int)GLib.Random.next_int();
	}

	/** Initializes and sets value to that at column. **/
	public override void get_value_impl (TreeIter iter, int column, out Value val) {
		val = Value(get_column_type(column));
		if(iter.stamp != this.stamp || column < 0 || column >= _columns.size || removing_medias)
			return;
		
		if(!((SequenceIter<ValueArray>)iter.user_data).is_end()) {
			Media s = lm.media_from_id(rows.get(((SequenceIter<int>)iter.user_data)));
			if(s == null)
				return;
			
			if(column == 0)
				val = (int)s.rowid;
			else if(column == 1) {
				if(lm.media_info.media != null && lm.media_info.media.rowid == s.rowid && is_current)
					val = _playing;
				else if(s.unique_status_image != null)
					val = s.unique_status_image;
				else
					val = Value(typeof(GLib.Icon));
			}
			else if(column == 2)
				val = s.album_artist;
			else if(column == 3)
				val = s.genre;
			else if(column == 4)
				val = (int)s.rating;
			else if(column == 5)
				val = (int)s.pulseProgress;
		}
	}

	/** Custom function to use built in sort in GLib.Sequence to our advantage **/
	public override int sequence_iter_compare_func (SequenceIter<int> a, SequenceIter<int> b) {
		int rv;
		
		if(sort_column_id < 0)
			return 0;
		
		Media a_media = lm.media_from_id(rows.get(a));
		Media b_media = lm.media_from_id(rows.get(b));
		
		if(_columns.get(sort_column_id) == "Station") {
			if(a_media.album_artist.down() == b_media.album_artist.down()) {
				rv = advanced_string_compare(b_media.uri, a_media.uri);
			}
			else
				rv = advanced_string_compare(a_media.album_artist.down(), b_media.album_artist.down());
		}
		else if(_columns.get(sort_column_id) == "Genre") {
			if(a_media.genre.down() == b_media.genre.down()) {
				if(a_media.album_artist.down() == b_media.album_artist.down()) {
					rv = advanced_string_compare(b_media.uri, a_media.uri);
				}
				else {
					rv = advanced_string_compare(a_media.album_artist.down(), b_media.album_artist.down());
				}
			}
			else
				rv = advanced_string_compare(a_media.genre.down(), b_media.genre.down());
		}
		
		else if(_columns.get(sort_column_id) == "Rating") {
			rv = (int)(a_media.rating - b_media.rating);
		}
		else {
			rv = 1;
		}
		
		if(sort_direction == SortType.DESCENDING)
			rv = (rv > 0) ? -1 : 1;
		
		return rv;
	}
	
	private int advanced_string_compare(string a, string b) {
		if(a == "" && b != "")
			return 1;
		else if(a != "" && b == "")
			return -1;
		
		return (a > b) ? 1 : -1;
	}
}
