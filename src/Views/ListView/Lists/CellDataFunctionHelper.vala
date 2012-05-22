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

using Gtk;
using Gdk;

public class BeatBox.CellDataFunctionHelper : GLib.Object {
	LibraryManager lm;
	FastView view;
	
	public CellDataFunctionHelper(LibraryManager lm, FastView view) {
		this.lm = lm;
		this.view = view;
	}

#if HAVE_SMART_ALBUM_COLUMN
	// for Smart album column
	public void smartAlbumFiller(TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		var m = view.get_object_from_index((int)iter.user_data) as Media;
		
		((SmartAlbumRenderer)cell).m = m;
		
		if(lm.get_cover_album_art(m.rowid) != null) {
			int top; int bottom; int current; int range;
			
			current = (int)iter.user_data;
			for(top = current; top >= 0; --top) {
				if(view.get_object_from_index(top).album != m.album) {
					++top;
					break;
				}
				else if(top == 0) {
					break;
				}
			}
			for(bottom = current; bottom < view.get_visible_table().size(); ++bottom) {
				if((view.get_object_from_index(bottom) as Media).album != m.album) {
					--bottom;
					break;
				}
			}
			range = (bottom - top) + 1;
			//stdout.printf("range is %d, top is %d, bottom is %d, current is %d\n", range, top, bottom, current);
			
			// We have enough space to draw art
			if(range >= 6) {
				((SmartAlbumRenderer)cell).icon = lm.get_cover_album_art(m.rowid);
				((SmartAlbumRenderer)cell).top = top;
				((SmartAlbumRenderer)cell).bottom = bottom;
				((SmartAlbumRenderer)cell).current = current;
				cell.xalign = 0.5f;
			}
			else {
				((SmartAlbumRenderer)cell).icon = null;
				cell.xalign = 0f;
			}
		}
		else {
			cell.xalign = 0f;
			((SmartAlbumRenderer)cell).icon = null;
		}
	}
#endif

	/** For spinner/unique icon on each row **/
	public void iconDataFunc(CellLayout layout, CellRenderer renderer, TreeModel model, TreeIter iter) {
		bool showIndicator = false;
		var s = view.get_object_from_index((int)iter.user_data) as Media;
		
		if(s == null)
			return;
		else
			showIndicator = s.showIndicator;

		if(renderer is CellRendererPixbuf) {
			Value? icon;
			model.get_value (iter, MusicListView.MusicColumn.ICON, out icon); // ICON column is same for all

			/* Themed icon */
			(renderer as CellRendererPixbuf).follow_state = true;
			(renderer as CellRendererPixbuf).gicon = (icon as GLib.Icon);

			renderer.visible = !showIndicator;
			renderer.width = showIndicator ? 0 : 16;
		}
		if(renderer is CellRendererSpinner) {
			if(showIndicator) {
				((CellRendererSpinner)renderer).active = true;
			}
				
			renderer.visible = showIndicator;
			renderer.width = showIndicator ? 16 : 0;
		}
	}
	
	// for Track, Year, #, Plays, Skips. Simply shows nothing if less than 1.
	public void intelligentTreeViewFiller(TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		Value val;
		tree_model.get_value(iter, tvc.sort_column_id, out val);
		
		if(val.get_int() <= 0)
			((CellRendererText)cell).markup = "";
		else
			((CellRendererText)cell).markup = String.escape (val.get_int().to_string());
	}
	
	public void stringTreeViewFiller(TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		Value val;
		tree_model.get_value(iter, tvc.sort_column_id, out val);
		
		var str = val.get_string ();
		
		if (str == null)
			return;
		
		((CellRendererText)cell).markup = String.escape (str);
	}
	
	// for Bitrate. Append 'kbps'
	public void bitrateTreeViewFiller(TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		Value val;
		tree_model.get_value(iter, tvc.sort_column_id, out val);
		
		var n = val.get_int ();
		var text_cell = cell as CellRendererText;

		if (n <= 0)
			text_cell.markup = "";
		else
			text_cell.markup = _("%i kbps").printf (n);
	}

	// turns int of seconds into pretty length mm:ss format
	public static void lengthTreeViewFiller(TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		Value val;
		tree_model.get_value(iter, tvc.sort_column_id, out val);
		
		var text_cell = cell as CellRendererText;
		
		int secs = val.get_int ();
		
		if(secs <= 0)
			text_cell.markup = "";
		else
			text_cell.markup = String.escape (TimeUtils.pretty_time_mins (secs));
	}

	// turns seconds since Jan 1, 1970 into date format
	public void dateTreeViewFiller(TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		Value val;
		tree_model.get_value(iter, tvc.sort_column_id, out val);

		int n = val.get_int ();
		var text_cell = cell as CellRendererText;

		if (n <= 0)
			text_cell.markup = "";
		else {
			var t = Time.local (n);
			var str = TimeUtils.pretty_timestamp_from_time (t);
			text_cell.markup = String.escape (str);
		}
	}
	
	public void ratingTreeViewFiller(TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		Value val;
		tree_model.get_value(iter, tvc.sort_column_id, out val);

		// now let's set the rating!
		(cell as Granite.Widgets.CellRendererRating).set_rating (val.get_int ());
	}
}

