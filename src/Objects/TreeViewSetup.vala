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

/* Merely a place holder for multiple pieces of information regarding
 * the current media playing. Mostly here because of dependence. */

using Gee;
using Gtk;

public class BeatBox.TreeViewSetup : GLib.Object {
	public static const int MUSIC_COLUMN_COUNT = 18;
	public static const int PODCAST_COLUMN_COUNT = 11;
	public static const int RADIO_COLUMN_COUNT = 6;
	
	public ViewWrapper.Hint hint;
	private string _sort_column; // Artist, Album
	private Gtk.SortType _sort_direction; // ASCENDING, DESCENDING
	private LinkedList<TreeViewColumn> _columns;
	
	public TreeViewSetup(string sort_col, SortType sort_dir, ViewWrapper.Hint hint) {
		this.hint = hint;
		_sort_column = sort_col;
		_sort_direction = sort_dir;
		
		_columns = new LinkedList<TreeViewColumn>();
		
		/* initial column state */
		if(hint == ViewWrapper.Hint.PODCAST || hint == ViewWrapper.Hint.DEVICE_PODCAST) {
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "id", 
											"fixed_width", 10,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", " ", 
											"fixed_width", 24,
											"visible", true));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Episode", 
											"fixed_width", 70,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Name", 
											"fixed_width", 220,
											"visible", true));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Length", 
											"fixed_width", 75,
											"visible", true));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Artist", 
											"fixed_width", 110,
											"visible", true));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Date", 
											"fixed_width", 70,
											"visible", true));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Category", 
											"fixed_width", 100,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Comment", 
											"fixed_width", 70,
											"visible", true));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Rating", 
											"fixed_width", 90,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Pulser", 
											"fixed_width", 40,
											"visible", false));
		}
		else if(hint == ViewWrapper.Hint.AUDIOBOOK || hint == ViewWrapper.Hint.DEVICE_AUDIOBOOK) {
			
		}
		else if(hint == ViewWrapper.Hint.STATION) {
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "id", 
											"fixed_width", 10,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", " ", 
											"fixed_width", 24,
											"visible", true));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Station", 
											"fixed_width", 300,
											"visible", true));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Genre", 
											"fixed_width", 100,
											"visible", true));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Rating", 
											"fixed_width", 90,
											"visible", true));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Pulser", 
											"fixed_width", 40,
											"visible", false));
		}
		else if(hint == ViewWrapper.Hint.ALBUM_LIST) { // same as normal music list, but most are hidden
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "id", 
											"fixed_width", 10,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", " ", 
											"fixed_width", 24,
											"visible", true));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "#", 
											"fixed_width", 40,
											"visible", (hint == ViewWrapper.Hint.QUEUE || hint == ViewWrapper.Hint.HISTORY || hint == ViewWrapper.Hint.PLAYLIST)));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Track", 
											"fixed_width", 60,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Title", 
											"fixed_width", 220,
											"visible", true));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Length", 
											"fixed_width", 75,
											"visible", true));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Artist", 
											"fixed_width", 110,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Album", 
											"fixed_width", 200,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Genre", 
											"fixed_width", 70,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Year", 
											"fixed_width", 50,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Bitrate", 
											"fixed_width", 70,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Rating", 
											"fixed_width", 90,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Plays", 
											"fixed_width", 40,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Skips", 
											"fixed_width", 40,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Date Added", 
											"fixed_width", 130,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Last Played", 
											"fixed_width", 130,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "BPM", 
											"fixed_width", 40,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Pulser", 
											"fixed_width", 40,
											"visible", false));
		}
		else {
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "id", 
											"fixed_width", 10,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", " ", 
											"fixed_width", 24,
											"visible", true));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "#", 
											"fixed_width", 40,
											"visible", (hint == ViewWrapper.Hint.QUEUE || hint == ViewWrapper.Hint.HISTORY || hint == ViewWrapper.Hint.PLAYLIST)));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Track", 
											"fixed_width", 60,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Title", 
											"fixed_width", 220,
											"visible", true));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Length", 
											"fixed_width", 75,
											"visible", true));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Artist", 
											"fixed_width", 110,
											"visible", true));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Album", 
											"fixed_width", 200,
											"visible", true));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Genre", 
											"fixed_width", 70,
											"visible", true));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Year", 
											"fixed_width", 50,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Bitrate", 
											"fixed_width", 70,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Rating", 
											"fixed_width", 90,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Plays", 
											"fixed_width", 40,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Skips", 
											"fixed_width", 40,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Date Added", 
											"fixed_width", 130,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Last Played", 
											"fixed_width", 130,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "BPM", 
											"fixed_width", 40,
											"visible", false));
			_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", "Pulser", 
											"fixed_width", 40,
											"visible", false));
		}
		
		
		for(int index = 0; index < _columns.size; ++index) {
			if(_columns.get(index).title != " " && _columns.get(index).title != "Rating") {
				CellRendererText crtext = new CellRendererText();
				_columns.get(index).pack_start(crtext, true);
				_columns.get(index).set_attributes(crtext, "text", index);
			}
			else if(_columns.get(index).title == " ") {
				CellRendererPixbuf crpix = new CellRendererPixbuf();
				_columns.get(index).pack_start(crpix, true);
				_columns.get(index).set_attributes(crpix, "pixbuf", index);
				CellRendererSpinner crspin = new CellRendererSpinner();
				_columns.get(index).pack_start(crspin, true);
				
				if(hint == ViewWrapper.Hint.PODCAST || hint == ViewWrapper.Hint.DEVICE_PODCAST) {
					_columns.get(index).add_attribute(crspin, "pulse", 10);
				}
				else if(hint == ViewWrapper.Hint.STATION) {
					_columns.get(index).add_attribute(crspin, "pulse", 5);
				}
				else if(hint == ViewWrapper.Hint.AUDIOBOOK || hint == ViewWrapper.Hint.DEVICE_AUDIOBOOK) {
					_columns.get(index).add_attribute(crspin, "pulse", 10);
				}
				else {
					_columns.get(index).add_attribute(crspin, "pulse", 17);
				}
				
				crspin.active = true;
				
			}
			else {
				CellRendererPixbuf crpix = new CellRendererPixbuf();
				_columns.get(index).pack_start(crpix, true);
				_columns.get(index).set_attributes(crpix, "pixbuf", index);
			}
				
			
			_columns.get(index).resizable = true;
			_columns.get(index).reorderable = true;
			_columns.get(index).clickable = true;
			_columns.get(index).sort_column_id = index;
			_columns.get(index).set_sort_indicator(false);
			_columns.get(index).sizing = Gtk.TreeViewColumnSizing.FIXED;
		}
	}
	
	public string sort_column {
		get { return _sort_column; }
		set { _sort_column = value; }
	}
	
	public SortType sort_direction {
		get { return _sort_direction; }
		set { _sort_direction = value; }
	}
	
	public string sort_direction_to_string() {
		if(_sort_direction == SortType.ASCENDING)
			return "ASCENDING";
		else
			return "DESCENDING";
	}
	
	public void set_sort_direction_from_string(string dir) {
		if(dir == "ASCENDING")
			_sort_direction = SortType.ASCENDING;
		else
			_sort_direction = SortType.DESCENDING;
	}
	
	public LinkedList<TreeViewColumn> get_columns() {
		return _columns;
	}
	
	public void set_columns(LinkedList<TreeViewColumn> cols) {
		_columns = cols;
	}
	
	public void import_columns(string cols) {
		string[] col_strings = cols.split("<column_seperator>", 0);
		
		/*if(col_strings.length - 1 == COLUMN_COUNT) { // the '-1' because col_strings has blank column at end
			_columns.clear();
		}
		else {
			stdout.printf("Unsuccessful column data import. Falling back to default.\n");
			return;
		}*/
		_columns.clear();
		
		int index;
		for(index = 0; index < col_strings.length - 1; ++index) { /* the '-1' because col_strings has blank column at end */
			string[] pieces_of_column = col_strings[index].split("<value_seperator>", 0);
			
			TreeViewColumn tvc;
			if(pieces_of_column[0] != " " && pieces_of_column[0] != "Rating")
				tvc = new Gtk.TreeViewColumn.with_attributes(pieces_of_column[0], new Gtk.CellRendererText(), "text", index, null);
			else if(pieces_of_column[0] == " ") {
				tvc = new Gtk.TreeViewColumn.with_attributes(pieces_of_column[0], new Gtk.CellRendererPixbuf(), "pixbuf", index, null);
				
				var crSpin = new CellRendererSpinner();
				crSpin.active = true;
				tvc.pack_start(crSpin, true);
				
				if(hint == ViewWrapper.Hint.PODCAST || hint == ViewWrapper.Hint.DEVICE_PODCAST) {
					tvc.add_attribute(crSpin, "pulse", 10);
				}
				else if(hint == ViewWrapper.Hint.STATION) {
					tvc.add_attribute(crSpin, "pulse", 5);
				}
				else if(hint == ViewWrapper.Hint.AUDIOBOOK || hint == ViewWrapper.Hint.DEVICE_AUDIOBOOK) {
					tvc.add_attribute(crSpin, "pulse", 10);
				}
				else {
					tvc.add_attribute(crSpin, "pulse", 17);
				}
			}
			else {
				tvc = new Gtk.TreeViewColumn.with_attributes(pieces_of_column[0], new Gtk.CellRendererPixbuf(), "pixbuf", index, null);
			}
			
			tvc.resizable = true;
			tvc.reorderable = true;
			tvc.clickable = true;
			tvc.sort_column_id = index;
			tvc.set_sort_indicator(false);
			tvc.sizing = Gtk.TreeViewColumnSizing.FIXED;
			
			tvc.fixed_width = int.parse(pieces_of_column[1]);
			tvc.visible = (int.parse(pieces_of_column[2]) == 1);
			
			_columns.add(tvc);
		}
	}
	
	public string columns_to_string() {
		string rv = "";
		
		foreach(TreeViewColumn tvc in _columns) {
			rv += tvc.title + "<value_seperator>" + ((tvc.width >= 10) ? tvc.width.to_string() : tvc.fixed_width.to_string()) + "<value_seperator>" + ( (tvc.visible) ? "1" : "0" ) + "<column_seperator>";
		}
		
		return rv;
	}
	
	public GPod.PlaylistSortOrder get_gpod_sortorder() {
		if(sort_column == "#")
			return GPod.PlaylistSortOrder.MANUAL;
		else if(sort_column == "Track" || sort_column == "Episode")
			return GPod.PlaylistSortOrder.TRACK_NR;
		else if(sort_column == "Title" || sort_column == "Name")
			return GPod.PlaylistSortOrder.TITLE;
		else if(sort_column == "Length")
			return GPod.PlaylistSortOrder.TIME;
		else if(sort_column == "Artist")
			return GPod.PlaylistSortOrder.ARTIST;
		else if(sort_column == "Album")
			return GPod.PlaylistSortOrder.ALBUM;
		else if(sort_column == "Genre")
			return GPod.PlaylistSortOrder.GENRE;
		else if(sort_column == "Bitrate")
			return GPod.PlaylistSortOrder.BITRATE;
		else if(sort_column == "Year")
			return GPod.PlaylistSortOrder.YEAR;
		else if(sort_column == "Date")
			return GPod.PlaylistSortOrder.RELEASE_DATE;
		else if(sort_column == "Date Added")
			return GPod.PlaylistSortOrder.TIME_ADDED;
		else if(sort_column == "Plays")
			return GPod.PlaylistSortOrder.PLAYCOUNT;
		else if(sort_column == "Last Played")
			return GPod.PlaylistSortOrder.TIME_PLAYED;
		else if(sort_column == "BPM")
			return GPod.PlaylistSortOrder.BPM;
		else if(sort_column == "Rating")
			return GPod.PlaylistSortOrder.RATING;
		else if(sort_column == "Comments")
			return GPod.PlaylistSortOrder.DESCRIPTION;
		else
			return GPod.PlaylistSortOrder.MANUAL;
	}
}
