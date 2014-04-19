/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player and Granite Library
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 * Granite Library:      http://www.launchpad.net/granite
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
 * 
 * NOTES: The iters returned are child model iters. To work with any function
 * except for add, you need to to use convertToFilter(child iter);
 */

using Gtk;

namespace Granite.Widgets {
	
	public class ExpanderRenderer : CellRenderer {
		public bool expanded;
		public static int EXPANDER_SIZE = 8;
		
		public ExpanderRenderer() {
			expanded = false;
		}
		
		public override void get_size(Widget widget, Gdk.Rectangle? cell_area, out int x_offset, out int y_offset, out int width, out int height) {
			x_offset = 0;
			y_offset = 4;
			width = 8;
			height = 8;
		}
		
		public override void render(Cairo.Context context, Widget widget, Gdk.Rectangle background_area, Gdk.Rectangle cell_area, Gtk.CellRendererState flags) {
			if(expanded)
				widget.get_style_context().set_state(StateFlags.ACTIVE);
			else
				widget.get_style_context().set_state(StateFlags.NORMAL);
			
			// this is for vala 0.14
			widget.get_style_context().render_expander(context,
                                cell_area.x + 8 / 2, cell_area.y + 8 / 2, 8.0, 8.0);//expanded ? ExpanderStyle.EXPANDED : ExpanderStyle.COLLAPSED);
			
			// this is for newer vala versions
			//widget.get_style_context().render_expander(context, cell_area.x + 8 / 2,
			//                                           cell_area.y + 8 / 2, 8.0, 8.0);
			                         //expanded ? ExpanderStyle.EXPANDED : ExpanderStyle.COLLAPSED);
		}
	}
	
	public enum SideBarColumn {
		COLUMN_OBJECT,
		COLUMN_WIDGET,
		COLUMN_VISIBLE,
		COLUMN_PIXBUF,
		COLUMN_TEXT,
		COLUMN_CLICKABLE
	}
	
	public class SideBar : Gtk.TreeView {
		public TreeStore tree;
		public TreeModelFilter filter;
		
		CellRendererText spacer;
		CellRendererText secondary_spacer;
		CellRendererPixbuf pix_cell;
		CellRendererText text_cell;
		CellRendererPixbuf clickable_cell;
		ExpanderRenderer expander_cell;
		
		TreeIter? selectedIter;
		
		public bool autoExpanded;
		
		public signal void clickable_clicked(TreeIter iter);
		public signal void true_selection_change(TreeIter selected);
		
		public SideBar() {
			tree = new TreeStore(6, typeof(GLib.Object), typeof(Widget), typeof(bool), typeof(Gdk.Pixbuf), typeof(string), typeof(Gdk.Pixbuf));
			filter = new TreeModelFilter(tree, null);
			set_model(filter);
			
			TreeViewColumn col = new TreeViewColumn();
			col.title = "object";
			this.insert_column(col, 0);
			
			col = new TreeViewColumn();
			col.title = "widget";
			this.insert_column(col, 1);
			
			col = new TreeViewColumn();
			col.title = "visible";
			this.insert_column(col, 2);
			
			col = new TreeViewColumn();
			col.title = "display";
			col.expand = true;
			this.insert_column(col, 3);
			
			// add spacer
			spacer = new CellRendererText();
			col.pack_start(spacer, false);
			col.set_cell_data_func(spacer, spacerDataFunc);
			spacer.xpad = 8;
			
			// secondary spacer
			secondary_spacer = new CellRendererText();
			col.pack_start(secondary_spacer, false);
			col.set_cell_data_func(secondary_spacer, secondarySpacerDataFunc);
			secondary_spacer.xpad = 8;
			
			// add pixbuf
			pix_cell = new CellRendererPixbuf();
			col.pack_start(pix_cell, false);
			col.set_cell_data_func(pix_cell, pixCellDataFunc);
			col.set_attributes(pix_cell, "pixbuf", SideBarColumn.COLUMN_PIXBUF);
			
			// add text
			text_cell = new CellRendererText();
			col.pack_start(text_cell, true);
			col.set_cell_data_func(text_cell, textCellDataFunc);
			col.set_attributes(text_cell, "markup", SideBarColumn.COLUMN_TEXT);
			text_cell.ellipsize = Pango.EllipsizeMode.END;
			text_cell.xalign = 0.0f;
			text_cell.xpad = 3;
			
			// add clickable icon
			clickable_cell = new CellRendererPixbuf();
			col.pack_start(clickable_cell, false);
			col.set_cell_data_func(clickable_cell, clickableCellDataFunc);
			col.set_attributes(clickable_cell, "pixbuf", SideBarColumn.COLUMN_CLICKABLE);
			clickable_cell.mode = CellRendererMode.ACTIVATABLE;
			clickable_cell.xpad = 2;
			clickable_cell.xalign = 1.0f;
			clickable_cell.stock_size = 16;
			
			// add expander
			expander_cell = new ExpanderRenderer();
			col.pack_start(expander_cell, false);
			col.set_cell_data_func(expander_cell, expanderCellDataFunc);
			
			this.set_headers_visible(false);
			//this.set_expander_column(get_column(3));
			this.set_show_expanders(false);
			filter.set_visible_column(SideBarColumn.COLUMN_VISIBLE);
			this.set_grid_lines(TreeViewGridLines.NONE);
			this.name = "SidebarContent";
		
			// Setup theming
			this.get_style_context().add_class (STYLE_CLASS_SIDEBAR);
			
			this.get_selection().changed.connect(selectionChange);
			this.button_press_event.connect(sideBarClick);
		}
		
		public void spacerDataFunc(CellLayout layout, CellRenderer renderer, TreeModel model, TreeIter iter) {
			TreePath path = model.get_path(iter);
			int depth = path.get_depth();
			
			renderer.visible = (depth > 1);
			renderer.xpad = (depth > 1) ? 8 : 0;
		}
		
		public void secondarySpacerDataFunc(CellLayout layout, CellRenderer renderer, TreeModel model, TreeIter iter) {
			TreePath path = model.get_path(iter);
			int depth = path.get_depth();
			
			renderer.visible = (depth > 2);
			renderer.xpad = (depth > 1) ? 8 : 0;
		}
		
		public void pixCellDataFunc(CellLayout layout, CellRenderer renderer, TreeModel model, TreeIter iter) {
			TreePath path = model.get_path(iter);
			
			if(path.get_depth() == 1) {
				renderer.visible = false;
			}
			else {
				renderer.visible = true;
			}
		}
		
		public void textCellDataFunc(CellLayout layout, CellRenderer renderer, TreeModel model, TreeIter iter) {
			TreePath path = model.get_path(iter);
			int depth = path.get_depth();
			string text = "";
			model.get(iter, SideBarColumn.COLUMN_TEXT, out text);
			
			if(depth == 1) {
				((CellRendererText)renderer).markup = "<b>" + text + "</b>";
			}
			else {
				((CellRendererText)renderer).markup = text;
			}
		}
		
		public void clickableCellDataFunc(CellLayout layout, CellRenderer renderer, TreeModel model, TreeIter iter) {
			TreePath path = model.get_path(iter);
			
			if(path.get_depth() == 1) {
				renderer.visible = false;
			}
			else {
				renderer.visible = true;
			}
		}
		
		public void expanderCellDataFunc(CellLayout layout, CellRenderer renderer, TreeModel model, TreeIter iter) {
			TreePath path = model.get_path(iter);
			
			renderer.visible = (path.get_depth() == 1);
			((ExpanderRenderer)renderer).expanded = is_row_expanded(path);
		}
		
		/* Convenient add/remove/edit methods */
		public TreeIter addItem(TreeIter? parent, GLib.Object? o, Widget? w, Gdk.Pixbuf? pixbuf, string text, Gdk.Pixbuf? clickable) {
			TreeIter iter;
			
			tree.append(out iter, parent);
			tree.set(iter, 0, o, 1, w, 2, true, 3, pixbuf, 4, text, 5, clickable);
			
			if(parent != null) {
				tree.set(parent, 2, true);
			}
			else {
				tree.set(iter, 2, false);
			}
			
			expand_all();
			return iter;
		}
		
		public bool removeItem(TreeIter iter) {
			TreeIter parent;
			if(tree.iter_parent(out parent, iter)) {
				if(tree.iter_n_children(parent) > 1)
					tree.set(parent, 2, true);
				else
					tree.set(parent, 2, false);
			}
			
			Widget w;
			tree.get(iter, SideBarColumn.COLUMN_WIDGET, out w);
			w.destroy();
			
			// destroy child row widgets as well
			TreeIter current;
			if(tree.iter_children(out current, iter)) {
				do {
					tree.get(current, SideBarColumn.COLUMN_WIDGET, out w);
					w.destroy();
				}
				while(tree.iter_next(ref current));
			}
            return tree.remove (ref iter);
		}
		
		// input MUST be a child iter
		public void setVisibility(TreeIter it, bool val) {
			bool was = false;
			tree.get(it, SideBarColumn.COLUMN_VISIBLE, out was);
			tree.set(it, SideBarColumn.COLUMN_VISIBLE, val);
			
			if(val && !was) {
				warning ("error happening sidebar.vala...");
				expand_row(filter.get_path(convertToFilter(it)), true);
				warning ("error finished");
			}
		}
		
		public void setName(TreeIter it, string name) {
			TreeIter iter = convertToChild(it);
			
			tree.set(iter, SideBarColumn.COLUMN_TEXT, name);
		}
		
		// parent should be filter iter
		public bool setNameFromObject(TreeIter parent, GLib.Object o, string name) {
			TreeIter realParent = convertToChild(parent);
			TreeIter pivot;
			tree.iter_children(out pivot, realParent);
			
			do {
				GLib.Object tempO;
				tree.get(pivot, 0, out tempO);
				
				if(tempO == o) {
					tree.set(pivot, SideBarColumn.COLUMN_TEXT, name);
					return true;
				}
				else if(!tree.iter_next(ref pivot)) {
					return false;
				}
				
			} while(true);
		}
		
		public TreeIter? getSelectedIter() {
			TreeModel mod;
			TreeIter sel;
			
			if(this.get_selection().get_selected(out mod, out sel)) {
				return sel;
			}
			
			return null;
		}
		
		public void setSelectedIter(TreeIter iter) {
			this.get_selection().changed.disconnect(selectionChange);
			get_selection().unselect_all();
			
			get_selection().select_iter(iter);
			this.get_selection().changed.connect(selectionChange);
			selectedIter = iter;
		}
		
		public bool expandItem(TreeIter iter, bool expanded) {
			if (filter.iter_n_children (convertToFilter (iter)) < 1)
				return false;

			TreePath? path = filter.get_path (convertToFilter (iter));

			if (path == null || path.get_depth () > 1)
				return false;

			if (expanded)
				return expand_row (path, false);

			return collapse_row (path);
		}

		public bool item_expanded (Gtk.TreeIter? iter) {
			if (iter != null)
				return is_row_expanded (filter.get_path (convertToFilter (iter)));

			return false;
		}

		public GLib.Object? getObject(TreeIter iter) {
			GLib.Object o;
			filter.get(iter, SideBarColumn.COLUMN_OBJECT, out o);
			return o;
		}
		
		public Widget? getWidget(TreeIter iter) {
			Widget w;
			tree.get(iter, SideBarColumn.COLUMN_WIDGET, out w);
			return w;
		}
		
		public Widget? getSelectedWidget() {
			TreeModel m;
			TreeIter iter;
			
			if(!this.get_selection().get_selected(out m, out iter)) { // user has nothing selected, reselect last selected
				//if(iter == null)
					return null;
			}
			
			Widget w;
			m.get(iter, SideBarColumn.COLUMN_WIDGET, out w);
			return w;
		}
		
		public Object? getSelectedObject() {
			TreeModel m;
			TreeIter iter;
			
			if(!this.get_selection().get_selected(out m, out iter)) { // user has nothing selected, reselect last selected
				//if(iter == null)
					return null;
			}
			
			Object o;
			m.get(iter, SideBarColumn.COLUMN_OBJECT, out o);
			return o;
		}
		
		/* stops user from selecting the root nodes */
		public void selectionChange() {
			TreeModel model;
			TreeIter pending;
			
			if(!this.get_selection().get_selected(out model, out pending)) { // user has nothing selected, reselect last selected
				if(selectedIter != null) {
					this.get_selection().select_iter(selectedIter);
				}
				
				return;
			}
			
			TreePath path = model.get_path(pending);
			
			if(path.get_depth() == 1) {
				this.get_selection().unselect_all();
				if(selectedIter != null)
					this.get_selection().select_iter(selectedIter);
			}
			else if(pending != selectedIter) {
				selectedIter = pending;
				true_selection_change(selectedIter);
			}
		}
		
		/* click event functions */
		private bool sideBarClick(Gdk.EventButton event) {
			if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 1) {
				// select one based on mouse position
				TreeIter iter;
				TreePath path;
				TreeViewColumn column;
				int cell_x;
				int cell_y;
				
				this.get_path_at_pos((int)event.x, (int)event.y, out path, out column, out cell_x, out cell_y);
				
				if(!filter.get_iter(out iter, path))
					return false;
				
				if(overClickable(iter, column, (int)cell_x, (int)cell_y)) {
					clickable_clicked(iter);
				}
				else if(overExpander(iter, column, (int)cell_x, (int)cell_y)) {
					if(is_row_expanded(path))
						this.collapse_row(path);
					else
						this.expand_row(path, true);
				}
			}
			
			return false;
		}
		
		private bool overClickable(TreeIter iter, TreeViewColumn col, int x, int y) {
			Gdk.Pixbuf pix;
			filter.get(iter, 5, out pix);
			
			if(pix == null)
				return false;
			
			int cell_x;
			int cell_width;
			col.cell_get_position(clickable_cell, out cell_x, out cell_width);
			
			if(x > cell_x && x < cell_x + cell_width)
				return true;
			
			return false;
		}
		
		private bool overExpander(TreeIter iter, TreeViewColumn col, int x, int y) {
			if(filter.get_path(iter).get_depth() != 1)
				return false;
			else
				return true;
			
			/* for some reason, the pixbuf SOMETIMES takes space, somtimes doesn't so cope for that *
			int pixbuf_start;
			int pixbuf_width;
			col.cell_get_position(pix_cell, out pixbuf_start, out pixbuf_width);
			int text_start;
			int text_width;
			col.cell_get_position(text_cell, out text_start, out text_width);
			int click_start;
			int click_width;
			col.cell_get_position(clickable_cell, out click_start, out click_width);
			int total = text_start + text_width + click_width - pixbuf_start;
			
			if(x > total)
				return true;
			
			return false;*/
		}
		
		/* Helpers for child->filter, filter->child */
		public TreeIter? convertToFilter(TreeIter? child) {
			if(child == null)
				return null;
			
			TreeIter rv;
			
			if(filter.convert_child_iter_to_iter(out rv, child)) {
				return rv;
			}
			
			return null;
		}
		
		public TreeIter? convertToChild(TreeIter? filt) {
			if(filt == null)
				return null;
			
			TreeIter rv;
			filter.convert_iter_to_child_iter(out rv, filt);
			
			return rv;
		}
		
	}
	
}