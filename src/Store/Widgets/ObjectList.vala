using Gtk;

public class Store.ObjectList : ScrolledWindow {
	Store.StoreView parent;
	string title;
	
	TreeView view;
	ListStore store;
	
	public ObjectList(Store.StoreView view, string title) {
		parent = view;
		this.title = title;
		
		buildUI();
	}
	
	public void buildUI() {
		view = new TreeView();
		store = new ListStore(3, typeof(GLib.Object), typeof(string), typeof(string));
		view.set_model(store);
		
		// setup the columns
		TreeViewColumn col = new TreeViewColumn();
		col.title = "object";
		col.visible = false;
		view.insert_column(col, 0);
		
		TreeViewColumn c = new TreeViewColumn();
		c.title = "helpertext";
		c.visible = false;
		view.insert_column(c, 1);
		
		var cell = new CellRendererText();
		cell.ellipsize = Pango.EllipsizeMode.END;
		view.insert_column_with_attributes(-1, title, cell, "text", 2, null);
		
		view.set_headers_visible(false);
		
		view.button_press_event.connect(listClick);
		view.row_activated.connect(listDoubleClick);
		
		add(view);
		
		set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
		
		show_all();
	}
	
	public void addItem(GLib.Object obj) {
		TreeIter iter;
		store.append(out iter);
		
		if(obj is Store.Tag) {
			Store.Tag tag = (Store.Tag)obj;
			store.set(iter, 0, tag, 1, tag.tagID, 2, tag.text);
			stdout.printf("blah\n");
		}
		else if(obj is Store.Artist) {
			Store.Artist artist = (Store.Artist)obj;
			store.set(iter, 0, artist, 1, artist.artistID.to_string(), 2, artist.name);
			stdout.printf("blah2\n");
		}
		else {
			Store.Release release = (Store.Release)obj;
			store.set(iter, 0, release, 1, release.releaseID.to_string(), 2, release.title);
		}
	}
	
	public virtual bool listClick(Gdk.EventButton event) {
		
		return false;
	}
	
	public virtual void listDoubleClick(TreePath path, TreeViewColumn column) {
		TreeIter iter;
		
		if(!store.get_iter(out iter, path))
			return;
		
		GLib.Object o;
		store.get(iter, 0, out o);
		
		if(o is Store.Tag) {
			stdout.printf("opening tag page for %s\n", ((Store.Tag)o).tagID);
		}
		else if(o is Store.Artist) {
			Artist art = (Store.Artist)o;
			var newView = new ArtistView(parent, parent.store, art);
			parent.setView(newView);
			newView.populate();
		}
		else if(o is Store.Release) {
			Release rel = (Store.Release)o;
			var newView = new AlbumView(parent, parent.store, rel);
			parent.setView(newView);
			newView.populate();
		}
	}
}
