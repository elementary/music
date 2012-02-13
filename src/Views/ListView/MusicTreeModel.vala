/*-
 * Copyright (c) 2011-2012		Scott Ringwelski <sgringwe@mtu.edu>
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

public class BeatBox.CompareFuncHolder : GLib.Object {
	public unowned TreeIterCompareFunc sort_func;

	public CompareFuncHolder(TreeIterCompareFunc func) {
		sort_func = func;
	}
}

public class BeatBox.MusicTreeModel : BaseTreeModel {
	LibraryManager lm;
	GLib.Icon _playing;
	GLib.Icon _completed;
	GLib.Icon _saved_locally;
	GLib.Icon _new_podcast;
	ViewWrapper.Hint hint;

	/* custom signals for custom treeview. for speed */
	public signal void rows_changed(LinkedList<TreePath> paths, LinkedList<TreeIter?> iters);
	public signal void rows_deleted (LinkedList<TreePath> paths);
	public signal void rows_inserted (LinkedList<TreePath> paths, LinkedList<TreeIter?> iters);

	/** Initialize data storage, columns, etc. **/
	public MusicTreeModel(LibraryManager lm, LinkedList<string> column_types, ViewWrapper.Hint hint) {
		this.lm = lm;
		_columns = column_types;

		_playing = Icons.MEDIA_PLAY_SYMBOLIC.get_gicon ();
		_completed = Icons.PROCESS_COMPLETED_ICON.get_gicon ();
		_saved_locally = new GLib.ThemedIcon.with_default_fallbacks (Gtk.Stock.SAVE);
		_new_podcast = Icons.NEW_PODCAST_ICON.get_gicon ();

		this.hint = hint;

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
				val = s.rowid;
			else if(column == 1) {
				if(lm.media_info.media != null && lm.media_info.media.rowid == s.rowid && is_current && _playing != null)
					val = _playing;
				else if(hint == ViewWrapper.Hint.CDROM && !s.isTemporary)
					val = _completed;
				else if(s.unique_status_image != null)
					val = s.unique_status_image;
				else if(s.mediatype == 1 && s.last_played == 0)
					val = _new_podcast;
				else if(s.mediatype == 1 && !s.uri.has_prefix("http://"))
					val = _saved_locally;
				else
					val = Value(typeof(GLib.Icon));
			}
			else if(column == 2)
				val = ((SequenceIter<int>)iter.user_data).get_position() + 1;
			else if(column == 3)
				val = (int)s.track;
			else if(column == 4)
				val = s.title;
			else if(column == 5)
				val = (int)s.length;
			else if(column == 6)
				val = s.artist;
			else if(column == 7)
				val = s.album;
			else if(column == 8)
				val = s.genre;
			else if(column == 9)
				val = (int)s.year;
			else if(column == 10)
				val = (int)s.bitrate;
			else if(column == 11)
				val = (int)s.rating;
			else if(column == 12)
				val = (int)s.play_count;
			else if(column == 13)
				val = (int)s.skip_count;
			else if(column == 14)
				val = (int)s.date_added;
			else if(column == 15)
				val = (int)s.last_played;
			else if(column == 16)
				val = (int)s.bpm;
			else if(column == 17)
				val = (int)s.pulseProgress;
		}
	}

	/** Custom function to use built in sort in GLib.Sequence to our advantage **/
	public override int sequence_iter_compare_func(SequenceIter<int> a, SequenceIter<int> b) {
		int rv;

		if(sort_column_id < 0)
			return 0;

		Media a_media = lm.media_from_id(rows.get(a));
		Media b_media = lm.media_from_id(rows.get(b));

		if(a_media == null || b_media == null)
			return 1;

		if(_columns.get(sort_column_id) == "Artist") {
			if(a_media.album_artist.down() == b_media.album_artist.down()) {
				if(a_media.album.down() == b_media.album.down()) {
					if(a_media.album_number == b_media.album_number)
						rv = (int)((sort_direction == SortType.ASCENDING) ? (int)(a_media.track - b_media.track) : (int)(b_media.track - a_media.track));
					else
						rv = (int)((int)a_media.album_number - (int)b_media.album_number);
				}
				else
					rv = advancedStringCompare(a_media.album.down(), b_media.album.down());
			}
			else
				rv = advancedStringCompare(a_media.album_artist.down(), b_media.album_artist.down());
		}
		else if(_columns.get(sort_column_id) == "Album") {
			if(a_media.album.down() == b_media.album.down()) {
				if(a_media.album_number == b_media.album_number)
					rv = (int)((sort_direction == SortType.ASCENDING) ? (int)(a_media.track - b_media.track) : (int)(b_media.track - a_media.track));
				else
					rv = (int)((int)a_media.album_number - (int)b_media.album_number);

			}
			else {
				if(a_media.album == "")
					rv = 1;
				else
					rv = advancedStringCompare(a_media.album.down(), b_media.album.down());
			}
		}
		else if(_columns.get(sort_column_id) == "#") {
			rv = a.get_position() - b.get_position();
		}
		else if(_columns.get(sort_column_id) == "Track") {
			rv = (int)(a_media.track - b_media.track);
		}
		else if(_columns.get(sort_column_id) == "Title") {
			rv = advancedStringCompare(a_media.title.down(), b_media.title.down());
		}
		else if(_columns.get(sort_column_id) == "Length") {
			rv = (int)(a_media.length - b_media.length);
		}
		else if(_columns.get(sort_column_id) == "Genre") {
			rv = advancedStringCompare(a_media.genre.down(), b_media.genre.down());
		}
		else if(_columns.get(sort_column_id) == "Year") {
			rv = (int)(a_media.year - b_media.year);
		}
		else if(_columns.get(sort_column_id) == "Bitrate") {
			rv = (int)(a_media.bitrate - b_media.bitrate);
		}
		else if(_columns.get(sort_column_id) == "Rating") {
			rv = (int)(a_media.rating - b_media.rating);
		}
		else if(_columns.get(sort_column_id) == "Last Played") {
			rv = (int)(a_media.last_played - b_media.last_played);
		}
		else if(_columns.get(sort_column_id) == "Date Added") {
			rv = (int)(a_media.date_added - b_media.date_added);
		}
		else if(_columns.get(sort_column_id) == "Plays") {
			rv = (int)(a_media.play_count - b_media.play_count);
		}
		else if(_columns.get(sort_column_id) == "Skips") {
			rv = (int)(a_media.skip_count - b_media.skip_count);
		}
		else if(_columns.get(sort_column_id) == "BPM") {
			rv = (int)(a_media.bpm - b_media.bpm);
		}
		else {
			rv = 1;
		}

		if(sort_direction == SortType.DESCENDING)
			rv = (rv > 0) ? -1 : 1;

		return rv;
	}

	private int advancedStringCompare(string a, string b) {
		if(a == "" && b != "")
			return 1;
		else if(a != "" && b == "")
			return -1;

		return (a > b) ? 1 : -1;
	}
}
