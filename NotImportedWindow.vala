using Gee;
using Gtk;

public class BeatBox.NotImportedWindow : Window{
	LinkedList<string> _files;
	
	ScrolledWindow filesScroll;
	TreeView filesView;
	ListStore filesModel;
	CheckButton moveToRecycle;
	Button deleteAll;
	Button deleteSelected;
	Button ignore;
	
	public NotImportedWindow(LinkedList<string> files) {
		if(files.size == 0)
			return;
		
		_files = files;
		
		this.set_title("Not Imported Files");
		
		// set the size based on saved gconf settings
		set_size_request(600, 400);
		allow_shrink = true;
		
		Label info = new Label("The following files could not be imported because they are corrupt.");
		filesScroll = new ScrolledWindow(null, null);
		filesView = new TreeView();
		filesModel = new ListStore(2, typeof(bool), typeof(string));
		filesView.set_model(filesModel);
		moveToRecycle = new CheckButton.with_label("Recycle");
		deleteAll = new Button.with_label("Delete all");
		deleteSelected = new Button.with_label("Delete checked");
		ignore = new Button.with_label("Ignore files");
		
		info.set_line_wrap(false);
		
		var toggle = new CellRendererToggle ();
        toggle.toggled.connect ((toggle, path) => {
            var tree_path = new TreePath.from_string (path);
            TreeIter iter;
            filesModel.get_iter (out iter, tree_path);
            filesModel.set (iter, 0, !toggle.active);
        });

        var column = new TreeViewColumn ();
        column.title = "Delete";
        column.pack_start (toggle, false);
        column.add_attribute (toggle, "active", 0);
        filesView.append_column (column);
		
		filesView.insert_column_with_attributes(-1, "File Location", new CellRendererText(), "text", 1, null);
		
		foreach(string file in files) {
			TreeIter item;
			filesModel.append(out item);
			
			filesModel.set(item, 0, false, 1, file);
		}
		
		HBox buttons = new HBox(false, 10);
		Label filler = new Label("");
		
		filesScroll.add(filesView);
		filesScroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		
		buttons.pack_start(moveToRecycle, false, false, 5);
		buttons.pack_start(deleteAll, false, false, 0);
		buttons.pack_start(deleteSelected, false, false, 0);
		buttons.pack_start(filler, false, true, 0);
		buttons.pack_end(ignore, false, false, 5);
		
		VBox vbox = new VBox(false, 0);
		vbox.pack_start(info, false, true, 0);
		vbox.pack_start(filesScroll, true, true, 0);
		vbox.pack_start(buttons, false, true, 5);
		
		moveToRecycle.toggled.connect(moveToRecycleToggle);
		deleteAll.clicked.connect(deleteAllClick);
		deleteSelected.clicked.connect(deleteSelectedClick);
		ignore.clicked.connect(ignoreClick);
		
		add(vbox);
		show_all();
	}
	
	public bool selectAll(TreeModel model, TreePath path, TreeIter iter) {
		filesModel.set(iter, 0, true);
		
		return false;
	}
	
	public bool deleteSelectedItems(TreeModel model, TreePath path, TreeIter iter) {
		bool selected;
		string location;
		filesModel.get(iter, 0, out selected);
		filesModel.get(iter, 1, out location);
		
		if(selected) {
			if(moveToRecycle.get_active()) {
				try {
					var file = File.new_for_path(location);
					file.trash();
				}
				catch(GLib.Error err) {
					stdout.printf("Could not move file %s to recycle: %s\n", location, err.message);
				}
			}
			else {
				try {
					var file = File.new_for_path (location);
					file.delete();
				}
				catch(GLib.Error err) {
					stdout.printf("Could not delete file %s: %s\n", location, err.message);
				}
			}
		}
		
		return false;
	}
	
	public virtual void moveToRecycleToggle() {
		if(moveToRecycle.active) {
			deleteAll.set_label("Recycle all");
			deleteSelected.set_label("Recycle selected");
		}
		else {
			deleteAll.set_label("Delete all");
			deleteSelected.set_label("Delete selected");
		}
	}
	
	public virtual void deleteAllClick() {
		//select every item and then call deleteSelectedClick()
		filesModel.foreach(selectAll);
		deleteSelectedClick();
	}
	
	public virtual void deleteSelectedClick() {
		filesModel.foreach(deleteSelectedItems);
		this.destroy();
	}
	
	public virtual void ignoreClick() {
		this.destroy();
	}
}
