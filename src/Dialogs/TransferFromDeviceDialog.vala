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

/* Merely a place holder for multiple pieces of information regarding
 * the current media playing. Mostly here because of dependence. */

using Gee;
using Gtk;

public class BeatBox.TransferFromDeviceDialog : Window {
	LibraryManager lm;
	LinkedList<int> medias;
	Device d;
	
	//for padding around notebook mostly
	private VBox content;
	private HBox padding;
	
	CheckButton transferAll;
	ScrolledWindow mediasScroll;
	TreeView mediasView;
	ListStore mediasModel;
	Button transfer;
	
	Gtk.Menu viewMenu;
	Gtk.MenuItem selectItem;
	Gtk.MenuItem selectAlbum;
	Gtk.MenuItem selectArtist;
	
	LinkedList<int> to_transfer;
	
	public TransferFromDeviceDialog(LibraryWindow lw, Device d, LinkedList<int> medias) {
		this.lm = lw.lm;
		this.medias = medias;
		this.d = d;
		
		to_transfer = new LinkedList<int>();
		
		this.set_title("Import from Device");
		
		// set the size based on saved gconf settings
		//this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(lw);
		this.destroy_with_parent = true;
		
		set_default_size(550, -1);
		resizable = false;
		
		content = new VBox(false, 10);
		padding = new HBox(false, 20);
		
		// initialize controls
		Image warning = new Image.from_stock(Gtk.Stock.DIALOG_QUESTION, Gtk.IconSize.DIALOG);
		Label title = new Label("Import medias from " + d.getDisplayName());
		Label info = new Label("The following files were found on " + d.getDisplayName() + ", but are not in your library. Check all files you would like to import.");
		transferAll = new CheckButton.with_label("Import all medias");
		mediasScroll = new ScrolledWindow(null, null);
		mediasView = new TreeView();
		mediasModel = new ListStore(5, typeof(bool), typeof(int), typeof(string), typeof(string), typeof(string));
		mediasView.set_model(mediasModel);
		transfer = new Button.with_label("Import");
		Button cancel = new Button.with_label("Don't Import");
		
		// pretty up labels
		title.xalign = 0.0f;
		title.set_markup("<span weight=\"bold\" size=\"larger\">Import " + ((medias.size > 1) ? (medias.size.to_string() + " medias") : (lm.media_from_id(medias.get(0)).title)) + " from " + d.getDisplayName() + "</span>");
		info.xalign = 0.0f;
		info.set_line_wrap(true);
		
		/* add cellrenderers to columns and columns to treeview */
		var toggle = new CellRendererToggle ();
        toggle.toggled.connect ((toggle, path) => {
            var tree_path = new TreePath.from_string (path);
            TreeIter iter;
            mediasModel.get_iter (out iter, tree_path);
            mediasModel.set (iter, 0, !toggle.active);
            
            transfer.set_sensitive(false);
            mediasModel.foreach(updateTransferSensetivity);
        });

        var column = new TreeViewColumn ();
        column.title = "";
        column.pack_start (toggle, false);
        column.add_attribute (toggle, "active", 0);
        mediasView.append_column(column);
		
		mediasView.insert_column_with_attributes(-1, "id", new CellRendererText(), "text", 1, null);
		mediasView.insert_column_with_attributes(-1, "Title", new CellRendererText(), "text", 2, null);
		mediasView.insert_column_with_attributes(-1, "Artist", new CellRendererText(), "text", 3, null);
		mediasView.insert_column_with_attributes(-1, "Album", new CellRendererText(), "text", 4, null);
		mediasView.headers_visible = true;
		
		for(int i = 0; i < 5; ++i) {
			mediasView.get_column(i).sizing = Gtk.TreeViewColumnSizing.FIXED;
			mediasView.get_column(i).resizable = true;
			mediasView.get_column(i).reorderable = false;
			mediasView.get_column(i).clickable = false;
		}
		
		mediasView.get_column(1).visible = false;
		
		mediasView.get_column(0).fixed_width = 25;
		mediasView.get_column(1).fixed_width = 10;
		mediasView.get_column(2).fixed_width = 300;
		mediasView.get_column(3).fixed_width = 125;
		mediasView.get_column(4).fixed_width = 125;
		
		//view.get_selection().set_mode(SelectionMode.MULTIPLE);
		
		/* fill the treeview */
		var medias_sorted = new LinkedList<Media>();
        foreach(int i in medias)
			medias_sorted.add(lm.media_from_id(i));
		medias_sorted.sort((CompareFunc)mediaCompareFunc);
		
		foreach(var s in medias_sorted) {
			TreeIter item;
			mediasModel.append(out item);
			
			mediasModel.set(item, 0, false, 1, s.rowid, 2, s.title, 3, s.artist, 4, s.album);
		}
		
		mediasScroll.add(mediasView);
		mediasScroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		
		transfer.set_sensitive(false);
		
		/* set up controls layout */
		HBox information = new HBox(false, 0);
		VBox information_text = new VBox(false, 0);
		information.pack_start(warning, false, false, 10);
		information_text.pack_start(title, false, true, 10);
		information_text.pack_start(info, false, true, 0);
		information.pack_start(information_text, true, true, 10);
		
		VBox listBox = new VBox(false, 0);
		listBox.pack_start(mediasScroll, true, true, 5);
		
		Expander exp = new Expander("Select individual medias to import:");
		exp.add(listBox);
		exp.expanded = false;
		
		HButtonBox bottomButtons = new HButtonBox();
		bottomButtons.set_layout(ButtonBoxStyle.END);
		bottomButtons.pack_end(cancel, false, false, 10);
		bottomButtons.pack_end(transfer, false, false, 0);
		bottomButtons.set_spacing(10);
		
		content.pack_start(information, false, true, 0);
		content.pack_start(wrap_alignment(transferAll, 5, 0, 0, 75), false, true, 0);
		content.pack_start(wrap_alignment(exp, 0, 0, 0, 75), true, true, 0);
		content.pack_start(bottomButtons, false, true, 10);
		
		padding.pack_start(content, true, true, 10);
		
		viewMenu = new Gtk.Menu();
		selectItem = new Gtk.MenuItem.with_label("Check Item");
		selectAlbum = new Gtk.MenuItem.with_label("Check Album");
		selectArtist = new Gtk.MenuItem.with_label("Check Artist");
		
		transfer.clicked.connect(transferClick);
		transferAll.toggled.connect(transferAllToggled);
		//mediasView.button_press_event.connect(mediasViewClick);
		cancel.clicked.connect( () => { this.destroy(); });
		exp.activate.connect( () => {
			if(exp.get_expanded()) {
				resizable = true;
				set_size_request(550, 180);
				resize(475, 180);
				resizable = false;
			}
			else
				set_size_request(550, 500);
		});
		
		add(padding);
		show_all();
	}
	
	public static int mediaCompareFunc(Media a, Media b) {
		if(a.artist == b.artist) {
			if(a.album == b.album)
				return (int)a.track - (int)b.track;
			else
				return (a.album > b.album) ? 1 : -1;
			
		}
		else
			return (a.artist > b.artist) ? 1 : -1;
	}
	
	public static Gtk.Alignment wrap_alignment (Gtk.Widget widget, int top, int right, int bottom, int left) {
		var alignment = new Gtk.Alignment(0.0f, 0.0f, 1.0f, 1.0f);
		alignment.top_padding = top;
		alignment.right_padding = right;
		alignment.bottom_padding = bottom;
		alignment.left_padding = left;
		
		alignment.add(widget);
		return alignment;
	}
	
	public bool updateTransferSensetivity(TreeModel model, TreePath path, TreeIter iter) {
		bool sel = false;
		model.get(iter, 0, out sel);
		
		if(sel) {
			transfer.set_sensitive(true);
			return true;
		}
		
		return false;
	}
	
	public bool selectAll(TreeModel model, TreePath path, TreeIter iter) {
		mediasModel.set(iter, 0, true);
		
		return false;
	}
	
	public bool unselectAll(TreeModel model, TreePath path, TreeIter iter) {
		mediasModel.set(iter, 0, false);
		
		return false;
	}
	
	public virtual void transferAllToggled() {
		if(transferAll.active) {
			mediasModel.foreach(selectAll);
			mediasView.set_sensitive(false);
			transfer.set_sensitive(true);
		}
		else {
			mediasModel.foreach(unselectAll);
			mediasView.set_sensitive(true);
			transfer.set_sensitive(false);
		}
	}
	
	public bool createTransferList(TreeModel model, TreePath path, TreeIter iter) {
		int id = 0;
		bool selected = false;
		mediasModel.get(iter, 0, out selected, 1, out id);
		
		if(id != 0 && selected) {
			to_transfer.add(id);
		}
		
		return false;
	}
	
	public virtual void transferClick() {
		to_transfer.clear();
		mediasModel.foreach(createTransferList);
		
		if(lm.doing_file_operations()) {
			lm.lw.doAlert("Cannot Import", "BeatBox is already doing file operations. Please wait until those finish to import from " + d.getDisplayName());
		}
		else {
			d.transfer_to_library(to_transfer);
			this.destroy();
		}
	}
	
	public virtual void cancelClick() {
		this.destroy();
	}
}
