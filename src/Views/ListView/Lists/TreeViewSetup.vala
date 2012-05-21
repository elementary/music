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
using Gtk;

public class BeatBox.TreeViewSetup : GLib.Object {
	// FIXME: Should be dynamic
	public static const int MUSIC_COLUMN_COUNT = 18;
	public static const int PODCAST_COLUMN_COUNT = 12;
	public static const int RADIO_COLUMN_COUNT = 6;

	public static string COLUMN_BLANK = " ";
	public static string COLUMN_BITRATE = _("Bitrate");
	public static string COLUMN_ID = _("ID");
	public static string COLUMN_EPISODE = _("Episode");
	public static string COLUMN_NAME = _("Name");
	public static string COLUMN_LENGTH = _("Length");
	public static string COLUMN_TITLE = _("Title");
	public static string COLUMN_ALBUM = _("Album");
	public static string COLUMN_ARTIST = _("Artist");
	public static string COLUMN_GENRE = _("Genre");
	public static string COLUMN_YEAR = _("Year");
	public static string COLUMN_PODCAST = _("Podcast");
	public static string COLUMN_DATE = _("Date");
	public static string COLUMN_CATEGORY = _("Category");
	public static string COLUMN_COMMENT = _("Comment");
	public static string COLUMN_RATING = _("Rating");
	public static string COLUMN_PULSER = _("Pulser");
	public static string COLUMN_STATION = _("Station");
	public static string COLUMN_DATE_ADDED = _("Date Added");
	public static string COLUMN_LAST_PLAYED = _("Last Played");
	public static string COLUMN_BPM = _("BPM");
	public static string COLUMN_PLAYS = _("Plays");
	public static string COLUMN_SKIPS = _("Skips");
	public static string COLUMN_TRACK = _("Track");
	public static string COLUMN_NUM = _("#");

	private ViewWrapper.Hint hint;
	public int sort_column_id; // Index of sort column
	public Gtk.SortType sort_direction; // ASCENDING, DESCENDING
	private GLib.List<TreeViewColumn> _columns;

	public bool column_headers_visible { get { return hint != ViewWrapper.Hint.ALBUM_LIST; } }

	public TreeViewSetup(int sort_col, SortType sort_dir, ViewWrapper.Hint hint) {
		this.hint = hint;
		sort_column_id = sort_col;
		sort_direction = sort_dir;
		
		create_default_columns ();
	}
	
	public ViewWrapper.Hint get_hint() {
		return hint;
	}
	
	public void set_hint(ViewWrapper.Hint hint) {
		this.hint = hint;
		if(!is_valid_setup())
			create_default_columns ();
	}
	
	void create_default_columns () {
		_columns = new GLib.List<TreeViewColumn>();
		
		/* initial column state */
		/*if(hint == ViewWrapper.Hint.PODCAST || hint == ViewWrapper.Hint.DEVICE_PODCAST) {
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), // 0
											"title", COLUMN_ID, 
											"fixed_width", 10,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), // 1
											"title", COLUMN_BLANK,
											"fixed_width", 24,
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), // 2
											"title", COLUMN_EPISODE, 
											"fixed_width", 70,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), // 3
											"title", COLUMN_NAME,
											"fixed_width", 220,
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), // 4
											"title", COLUMN_LENGTH, 
											"fixed_width", 75,
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), // 5
											"title", COLUMN_ARTIST, 
											"fixed_width", 110,
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), // 6
											"title", COLUMN_PODCAST, 
											"fixed_width", 110,
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), // 7
											"title", COLUMN_DATE, 
											"fixed_width", 70,
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), // 8
											"title", COLUMN_CATEGORY,
											"fixed_width", 100,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), // 9
											"title", COLUMN_COMMENT,
											"fixed_width", 70,
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), // 10
											"title", COLUMN_RATING, 
											"fixed_width", 90,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), // 11
											"title", COLUMN_PULSER,
											"fixed_width", 40,
											"visible", false));
		}
		else if(hint == ViewWrapper.Hint.AUDIOBOOK || hint == ViewWrapper.Hint.DEVICE_AUDIOBOOK) {
			
		}
		else if(hint == ViewWrapper.Hint.STATION) {
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_ID, 
											"fixed_width", 10,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_BLANK, 
											"fixed_width", 24,
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_STATION, 
											"fixed_width", 300,
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_GENRE, 
											"fixed_width", 100,
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_RATING, 
											"fixed_width", 90,
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_PULSER, 
											"fixed_width", 40,
											"visible", false));
		}
		else*/ if(hint == ViewWrapper.Hint.ALBUM_LIST) { // same as normal music list, but most are hidden
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_ID, 
											"fixed_width", 10,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_BLANK, 
											"fixed_width", 24,
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_NUM, 
											"fixed_width", 40,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_TRACK, 
											"fixed_width", 60,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_TITLE, 
											"fixed_width", 275,
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_LENGTH, 
											"fixed_width", 50,
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_ARTIST, 
											"fixed_width", 110,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_ALBUM, 
											"fixed_width", 200,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_GENRE, 
											"fixed_width", 70,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_YEAR, 
											"fixed_width", 50,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_BITRATE, 
											"fixed_width", 70,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_RATING, 
											"fixed_width", 90,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_PLAYS, 
											"fixed_width", 40,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_SKIPS, 
											"fixed_width", 40,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_DATE_ADDED, 
											"fixed_width", 130,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_LAST_PLAYED, 
											"fixed_width", 130,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_BPM, 
											"fixed_width", 40,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_PULSER, 
											"fixed_width", 40,
											"visible", false));
		}
		else {
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_ID, 
											"fixed_width", 10,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_BLANK, 
											"fixed_width", 24,
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_NUM, 
											"fixed_width", 40,
											"visible", (hint == ViewWrapper.Hint.QUEUE || hint == ViewWrapper.Hint.HISTORY || hint == ViewWrapper.Hint.PLAYLIST)));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_TRACK, 
											"fixed_width", 60,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_TITLE, 
											"fixed_width", 220,
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_LENGTH, 
											"fixed_width", 75,
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_ARTIST, 
											"fixed_width", 110,
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_ALBUM, 
											"fixed_width", 200,
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_GENRE, 
											"fixed_width", 70,
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_YEAR, 
											"fixed_width", 50,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_BITRATE, 
											"fixed_width", 70,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_RATING, 
											"fixed_width", 90,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_PLAYS, 
											"fixed_width", 40,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_SKIPS, 
											"fixed_width", 40,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_DATE_ADDED, 
											"fixed_width", 130,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_LAST_PLAYED, 
											"fixed_width", 130,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_BPM, 
											"fixed_width", 40,
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_PULSER, 
											"fixed_width", 40,
											"visible", false));
		}
		
		
		for(uint index = 0; index < _columns.length(); ++index) {
			if(_columns.nth_data(index).title != COLUMN_BLANK && _columns.nth_data(index).title != COLUMN_RATING) {
				CellRendererText crtext = new CellRendererText();
				_columns.nth_data(index).pack_start(crtext, true);
				_columns.nth_data(index).set_attributes(crtext, "text", index);
			}
			else if(_columns.nth_data(index).title == COLUMN_BLANK) {
				CellRendererPixbuf crpix = new CellRendererPixbuf();
				_columns.nth_data(index).pack_start(crpix, true);
				_columns.nth_data(index).set_attributes(crpix, "pixbuf", index);
				CellRendererSpinner crspin = new CellRendererSpinner();
				_columns.nth_data(index).pack_start(crspin, true);
				
				if(hint == ViewWrapper.Hint.PODCAST || hint == ViewWrapper.Hint.DEVICE_PODCAST) {
					_columns.nth_data(index).add_attribute(crspin, "pulse", PODCAST_COLUMN_COUNT - 1);
				}
				else if(hint == ViewWrapper.Hint.STATION) {
					_columns.nth_data(index).add_attribute(crspin, "pulse", 5);
				}
				else if(hint == ViewWrapper.Hint.AUDIOBOOK || hint == ViewWrapper.Hint.DEVICE_AUDIOBOOK) {
					_columns.nth_data(index).add_attribute(crspin, "pulse", 10);
				}
				else {
					_columns.nth_data(index).add_attribute(crspin, "pulse", 17);
				}
				
				crspin.active = true;
				
			}
			else {
				CellRendererPixbuf crpix = new CellRendererPixbuf();
				_columns.nth_data(index).pack_start(crpix, true);
				_columns.nth_data(index).set_attributes(crpix, "pixbuf", index);
			}
				
			
			_columns.nth_data(index).resizable = true;
			_columns.nth_data(index).reorderable = true;
			_columns.nth_data(index).clickable = true;
			_columns.nth_data(index).sort_column_id = (int)index;
			_columns.nth_data(index).set_sort_indicator(false);
			_columns.nth_data(index).sizing = Gtk.TreeViewColumnSizing.FIXED;
		}
	}
	
	public string sort_direction_to_string() {
		if(sort_direction == SortType.ASCENDING)
			return "ASCENDING";
		else
			return "DESCENDING";
	}
	
	public void set_sort_direction_from_string(string dir) {
		if(dir == "ASCENDING")
			sort_direction = SortType.ASCENDING;
		else
			sort_direction = SortType.DESCENDING;
	}
	
	public GLib.List<TreeViewColumn> get_columns() {
		var rv = new GLib.List<TreeViewColumn>();
		foreach(var tvc in _columns)
			rv.append(tvc);
			
		return rv;
	}
	
	public void set_columns(GLib.List<TreeViewColumn> cols) {
		_columns = new GLib.List<TreeViewColumn>();
		foreach(var tvc in cols)
			_columns.append(tvc);
	}
	
	public void import_columns(string cols) {
		string[] col_strings = cols.split("<c_sep>", 0);
		_columns = new GLib.List<TreeViewColumn>();
		
		int index;
		for(index = 0; index < col_strings.length - 1; ++index) { /* the '-1' because col_strings has blank column at end */
			string[] pieces_of_column = col_strings[index].split("<v_sep>", 0);
			
			TreeViewColumn tvc;
			if(pieces_of_column[0] != COLUMN_BLANK && pieces_of_column[0] != COLUMN_RATING)
				tvc = new Gtk.TreeViewColumn.with_attributes(pieces_of_column[0], new Gtk.CellRendererText(), "text", index, null);
			else if(pieces_of_column[0] == COLUMN_BLANK) {
				tvc = new Gtk.TreeViewColumn.with_attributes(pieces_of_column[0], new Gtk.CellRendererPixbuf(), "pixbuf", index, null);
				
				var crSpin = new CellRendererSpinner();
				crSpin.active = true;
				tvc.pack_start(crSpin, true);
				
				if(hint == ViewWrapper.Hint.PODCAST || hint == ViewWrapper.Hint.DEVICE_PODCAST) {
					tvc.add_attribute(crSpin, "pulse", PODCAST_COLUMN_COUNT - 1);
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
			
			_columns.append(tvc);
		}
		
		/*if(!is_valid_setup ()) {
			warning("Invalid treeview setup found. Creating a new one!\n");
			create_default_columns ();
		}*/
		
	}
	
	public bool is_valid_setup() {
		bool rv = true;
		if(hint == ViewWrapper.Hint.PODCAST || hint == ViewWrapper.Hint.DEVICE_PODCAST) {
			if(_columns.length() != PODCAST_COLUMN_COUNT) {
				rv = false;
			}
		}
		/*else if((hint == ViewWrapper.Hint.AUDIOBOOK || hint == ViewWrapper.Hint.DEVICE_AUDIOBOOK) && 
		_columns.length() != AUDIOBOOK_) {
			return false;
		}*/
		else if(hint == ViewWrapper.Hint.STATION) {
			if(_columns.length() != RADIO_COLUMN_COUNT) {
				rv = false;
			}
		}
		else if(_columns.length() != MUSIC_COLUMN_COUNT) {
			rv = false;
		}
		
		if(!rv) {
			warning("Invalid treeview setup found. Creating a new one!%u %d %d\n", _columns.length(), PODCAST_COLUMN_COUNT, RADIO_COLUMN_COUNT);
			create_default_columns ();
			return false;
		}
		
		return true;
	}
	
	public string columns_to_string() {
		string rv = "";
		
		foreach(TreeViewColumn tvc in _columns) {
			rv += tvc.title + "<v_sep>" + ((tvc.width >= 10) ? tvc.width.to_string() : tvc.fixed_width.to_string()) + "<v_sep>" + ( (tvc.visible) ? "1" : "0" ) + "<c_sep>";
		}
		
		return rv;
	}
	
	// TODO: FIXME from sort_column to sort_column_id
	public GPod.PlaylistSortOrder get_gpod_sortorder() {
		/*if(sort_column == "#")
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
		else*/
			return GPod.PlaylistSortOrder.MANUAL;
	}
}
