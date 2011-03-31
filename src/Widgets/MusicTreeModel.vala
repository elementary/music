using Gtk;
using Gee;
using GLib;

public class BeatBox.MusicTreeModel : GLib.Object, TreeModel {
    /* data storage variables */
    
    /* custom signals for custom treeview. for speed */
    public signal void rows_changed(LinkedList<TreePath> paths, LinkedList<TreeIter?> iters);
    public signal void rows_deleted (LinkedList<TreePath> paths);
	public signal void rows_inserted (LinkedList<TreePath> paths, LinkedList<TreeIter?> iters);
	
	/** Initialize data storage, columns, etc. **/
	public MusicTreeModel() {
		
	}
	
	/** calls func on each node in model in a depth-first fashion **/
	public void foreach (TreeModelForeachFunc func) {
		
	}

	/** Sets params of each id-value pair of the value of that iter **/
	public void get (TreeIter iter, ...) {
	
	}

	/** Returns Type of column at index_ **/
	public Type get_column_type (int index_) {
		
		return typeof(GLib.Object);
	}

	/** Returns a set of flags supported by this interface **/
	public TreeModelFlags get_flags () {
		return TreeModelFlags.LIST_ONLY;
	}

	/** Sets iter to a valid iterator pointing to path **/
	public bool get_iter (out TreeIter iter, TreePath path) {
		
		return false;
	}

	/** Initializes iter with the first iterator in the tree (the one at the path "0") and returns true. **/
	public bool get_iter_first (out TreeIter iter) {
		
		return false;
	}

	/** Sets iter to a valid iterator pointing to path_string, if it exists. **/
	public bool get_iter_from_string (out TreeIter iter, string path_string) {
		
		return false;
	}

	/** Returns the number of columns supported by tree_model. **/
	public int get_n_columns () {
		
		return 0;
	}

	/** Returns a newly-created Gtk.TreePath referenced by iter. **/
	public TreePath get_path (TreeIter iter) {
		
		return new TreePath();
	}

	/** Generates a string representation of the iter. **/
	public string get_string_from_iter (TreeIter iter) {
		
		return "";
	}

	/**   **/
	public void get_valist (TreeIter iter, void* var_args) {
	
	}

	/** Initializes and sets value to that at column. **/
	public void get_value (TreeIter iter, int column, out Value value) {
	
	}

	/** Sets iter to point to the first child of parent. **/
	public bool iter_children (out TreeIter iter, TreeIter? parent) {
		
		return false;
	}

	/** Returns true if iter has children, false otherwise. **/
	public bool iter_has_child (TreeIter iter) {
		
		return false;
	}

	/** Returns the number of children that iter has. **/
	public int iter_n_children (TreeIter? iter) {
		
		return 0;
	}

	/** Sets iter to point to the node following it at the current level. **/
	public bool iter_next (ref TreeIter iter) {
		
		return false;
	}

	/** Sets iter to be the child of parent, using the given index. **/
	public bool iter_nth_child (out TreeIter iter, TreeIter? parent, int n) {
		
		return false;
	}

	/** Sets iter to be the parent of child. **/
	public bool iter_parent (out TreeIter iter, TreeIter child) {
		
		return false;
	}

	/** Lets the tree ref the node. **/
	public void ref_node (TreeIter iter) {
		
	}

	/** Lets the tree unref the node. **/
	public void unref_node (TreeIter iter) {
		
	}

}
