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

public class Noise.TreeViewSetup : Object {
	// FIXME: Should be dynamic
	public static const int MUSIC_COLUMN_COUNT = 17;

	public static string COLUMN_BLANK { get; private set; default = " "; }
	public static string COLUMN_BITRATE { get; private set; default = _("Bitrate"); }
	public static string COLUMN_ID { get; private set; default = _("ID"); }
	public static string COLUMN_EPISODE { get; private set; default = _("Episode"); }
	public static string COLUMN_NAME { get; private set; default = _("Name"); }
	public static string COLUMN_LENGTH { get; private set; default = _("Length"); }
	public static string COLUMN_TITLE { get; private set; default = _("Title"); }
	public static string COLUMN_ALBUM { get; private set; default = _("Album"); }
	public static string COLUMN_ARTIST { get; private set; default = _("Artist"); }
	public static string COLUMN_GENRE { get; private set; default = _("Genre"); }
	public static string COLUMN_YEAR { get; private set; default = _("Year"); }
	public static string COLUMN_PODCAST { get; private set; default = _("Podcast"); }
	public static string COLUMN_DATE { get; private set; default = _("Date"); }
	public static string COLUMN_CATEGORY { get; private set; default = _("Category"); }
	public static string COLUMN_COMMENT { get; private set; default = _("Comment"); }
	public static string COLUMN_RATING { get; private set; default = _("Rating"); }
	public static string COLUMN_STATION { get; private set; default = _("Station"); }
	public static string COLUMN_DATE_ADDED { get; private set; default = _("Date Added"); }
	public static string COLUMN_LAST_PLAYED { get; private set; default = _("Last Played"); }
	public static string COLUMN_BPM { get; private set; default = _("BPM"); }
	public static string COLUMN_PLAYS { get; private set; default = _("Plays"); }
	public static string COLUMN_SKIPS { get; private set; default = _("Skips"); }
	public static string COLUMN_TRACK { get; private set; default = _("Track"); }
	public static string COLUMN_NUM { get; private set; default = _("#"); }

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
	
	private void create_default_columns () {
		_columns = new GLib.List<TreeViewColumn>();
		
		/* initial column state */
		if(hint == ViewWrapper.Hint.ALBUM_LIST) { // same as normal music list, but most are hidden
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_ID, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_BLANK, 
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_NUM, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_TRACK, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_TITLE, 
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_LENGTH, 
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_ARTIST, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_ALBUM, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_GENRE, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_YEAR, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_BITRATE, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_RATING, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_PLAYS, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_SKIPS, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_DATE_ADDED, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_LAST_PLAYED, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_BPM, 
											"visible", false));
		}
		else {
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_ID, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_BLANK, 
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_NUM, 
											"visible", (hint == ViewWrapper.Hint.QUEUE || hint == ViewWrapper.Hint.HISTORY || hint == ViewWrapper.Hint.PLAYLIST)));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_TRACK, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_TITLE, 
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_LENGTH, 
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_ARTIST, 
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_ALBUM, 
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_GENRE, 
											"visible", true));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_YEAR, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_BITRATE, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_RATING, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_PLAYS, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_SKIPS, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_DATE_ADDED, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_LAST_PLAYED, 
											"visible", false));
			_columns.append((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
											"title", COLUMN_BPM, 
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

/*				
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
*/

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
		
		bool valid_setup = true;
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
/*
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
*/
			}
			else {
				tvc = new Gtk.TreeViewColumn.with_attributes(pieces_of_column[0], new Gtk.CellRendererPixbuf(), "pixbuf", index, null);
			}
			
			tvc.set_sort_indicator(false);

            int visible_val = int.parse (pieces_of_column[1]);
            if (visible_val != 1 && visible_val != 0) {
                valid_setup = false;
                break;
            }

			tvc.visible = (visible_val == 1);

            tvc.sizing = Gtk.TreeViewColumnSizing.FIXED;
			_columns.append(tvc);
		}

		if (!valid_setup) {
			warning("Invalid treeview setup found. Creating a new one!\n");
			create_default_columns ();
		}
	}
	
	public bool is_valid_setup() {
		bool rv = true;

		if(_columns.length() != MUSIC_COLUMN_COUNT) {
			rv = false;
		}

		if(!rv) {
			warning("Invalid treeview setup found. Creating a new one");
			create_default_columns ();
			return false;
		}
		
		return true;
	}
	
	public string columns_to_string() {
		string rv = "";

		foreach(TreeViewColumn tvc in _columns) {
			rv += tvc.title + "<v_sep>" + ( (tvc.visible) ? "1" : "0" ) + "<c_sep>";
		}
		
		return rv;
	}

}
