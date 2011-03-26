using Gee;
using Gtk;

public class BeatBox.NotImportedWindow : Window{
	LinkedList<string> _files;
	
	//for padding around notebook mostly
	private VBox content;
	private HBox padding;
	
	CheckButton trashAll;
	ScrolledWindow filesScroll;
	TreeView filesView;
	ListStore filesModel;
	Button moveToTrash;
	
	public NotImportedWindow(LibraryWindow lw, LinkedList<string> files) {
		_files = files;
		
		this.set_title("Not Imported Files");
		
		// set the size based on saved gconf settings
		this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(lw);
		this.destroy_with_parent = true;
		
		set_default_size(475, -1);
		allow_shrink = false;
		
		content = new VBox(false, 10);
		padding = new HBox(false, 20);
		
		// initialize controls
		Image warning = new Image.from_stock(Gtk.Stock.DIALOG_ERROR, Gtk.IconSize.DIALOG);
		Label title = new Label("Unable to import " + files.size.to_string() + "songs");
		Label info = new Label("BeatBox was unable to import " + files.size.to_string() + " songs. The files may be damaged.");
		trashAll = new CheckButton.with_label("Move all corrupted files to trash");
		filesScroll = new ScrolledWindow(null, null);
		filesView = new TreeView();
		filesModel = new ListStore(2, typeof(bool), typeof(string));
		filesView.set_model(filesModel);
		moveToTrash = new Button.with_label("Move to Trash");
		Button okButton = new Button.with_label("Ignore");
		
		// pretty up labels
		title.xalign = 0.0f;
		title.set_markup("<span weight=\"bold\" size=\"larger\">Unable to import " + files.size.to_string() + " songs</span>");
		info.xalign = 0.0f;
		info.set_line_wrap(false);
		
		/* add cellrenderers to columns and columns to treeview */
		var toggle = new CellRendererToggle ();
        toggle.toggled.connect ((toggle, path) => {
            var tree_path = new TreePath.from_string (path);
            TreeIter iter;
            filesModel.get_iter (out iter, tree_path);
            filesModel.set (iter, 0, !toggle.active);
            
            moveToTrash.set_sensitive(false);
            filesModel.foreach(updateMoveToTrashSensetivity);
        });

        var column = new TreeViewColumn ();
        column.title = "del";
        column.pack_start (toggle, false);
        column.add_attribute (toggle, "active", 0);
        filesView.append_column (column);
		
		filesView.insert_column_with_attributes(-1, "File Location", new CellRendererText(), "text", 1, null);
		filesView.headers_visible = false;
		
		/* fill the treeview */
		foreach(string file in files) {
			TreeIter item;
			filesModel.append(out item);
			
			filesModel.set(item, 0, false, 1, file);
		}
		
		filesScroll.add(filesView);
		filesScroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		
		moveToTrash.set_sensitive(false);
		
		/* set up controls layout */
		HBox information = new HBox(false, 0);
		VBox information_text = new VBox(false, 0);
		information.pack_start(warning, false, false, 10);
		information_text.pack_start(title, false, true, 10);
		information_text.pack_start(info, false, true, 0);
		information.pack_start(information_text, true, true, 10);
		
		VBox listBox = new VBox(false, 0);
		listBox.pack_start(filesScroll, true, true, 5);
		
		Expander exp = new Expander("Select individual files to move to trash:");
		exp.add(listBox);
		exp.expanded = false;
		
		HButtonBox bottomButtons = new HButtonBox();
		bottomButtons.set_layout(ButtonBoxStyle.END);
		bottomButtons.pack_end(moveToTrash, false, false, 0);
		bottomButtons.pack_end(okButton, false, false, 10);
		bottomButtons.set_spacing(10);
		bottomButtons.child_ipad_x = 10;
		
		content.pack_start(information, false, true, 0);
		content.pack_start(wrap_alignment(trashAll, 5, 0, 0, 75), false, true, 0);
		content.pack_start(wrap_alignment(exp, 0, 0, 0, 75), true, true, 0);
		content.pack_start(bottomButtons, false, true, 10);
		
		padding.pack_start(content, true, true, 10);
		
		moveToTrash.clicked.connect(moveToTrashClick);
		trashAll.toggled.connect(trashAllToggled);
		okButton.clicked.connect( () => { this.destroy(); });
		exp.activate.connect( () => {
			if(exp.get_expanded()) {
				allow_shrink = true;
				set_size_request(475, 180);
				resize(475, 180);
				allow_shrink = false;
			}
			else
				set_size_request(475, 350);
		});
		
		add(padding);
		show_all();
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
	
	public bool updateMoveToTrashSensetivity(TreeModel model, TreePath path, TreeIter iter) {
		bool sel = false;
		model.get(iter, 0, out sel);
		
		if(sel) {
			moveToTrash.set_sensitive(true);
			return true;
		}
		
		return false;
	}
	
	public bool selectAll(TreeModel model, TreePath path, TreeIter iter) {
		filesModel.set(iter, 0, true);
		
		return false;
	}
	
	public bool unselectAll(TreeModel model, TreePath path, TreeIter iter) {
		filesModel.set(iter, 0, false);
		
		return false;
	}
	
	public virtual void trashAllToggled() {
		if(trashAll.active) {
			filesModel.foreach(selectAll);
			filesView.set_sensitive(false);
			moveToTrash.set_sensitive(true);
		}
		else {
			filesModel.foreach(unselectAll);
			filesView.set_sensitive(true);
			moveToTrash.set_sensitive(false);
		}
	}
	
	public bool deleteSelectedItems(TreeModel model, TreePath path, TreeIter iter) {
		bool selected;
		string location;
		filesModel.get(iter, 0, out selected);
		filesModel.get(iter, 1, out location);
		
		if(selected) {
			try {
				var file = File.new_for_path(location);
				file.trash();
			}
			catch(GLib.Error err) {
				stdout.printf("Could not move file %s to recycle: %s\n", location, err.message);
			}
			/*else {
				try {
					var file = File.new_for_path (location);
					file.delete();
				}
				catch(GLib.Error err) {
					stdout.printf("Could not delete file %s: %s\n", location, err.message);
				}
			}*/
		}
		
		return false;
	}
	
	public virtual void moveToTrashClick() {
		filesModel.foreach(deleteSelectedItems);
		this.destroy();
	}
	
	public virtual void ignoreClick() {
		this.destroy();
	}
}
