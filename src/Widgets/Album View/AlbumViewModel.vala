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

using Gtk;
using Gee;
using GLib;

public class BeatBox.AlbumViewModelObject : GLib.Object {
	public string artist;
	public string album;
	public Gdk.Pixbuf? art;
	
	public AlbumViewModelObject(Gdk.Pixbuf? pix, string artistt, string albumm) {
		art = pix;
		artist = artistt;
		album = albumm;
	}
}

public class BeatBox.AlbumViewModel : GLib.Object, TreeModel {
	LibraryManager lm;
	int stamp; // all iters must match this
	Gdk.Pixbuf defaultImage;
	
    /* data storage variables */
    Sequence<AlbumViewModelObject> rows;
    private LinkedList<string> _columns;
    
    /* custom signals for custom treeview. for speed */
    public signal void rows_changed(LinkedList<TreePath> paths, LinkedList<TreeIter?> iters);
    public signal void rows_deleted (LinkedList<TreePath> paths);
	public signal void rows_inserted (LinkedList<TreePath> paths, LinkedList<TreeIter?> iters);
	
	/** Initialize data storage, columns, etc. **/
	public AlbumViewModel(LibraryManager lm, Gdk.Pixbuf defaultImage) {
		this.lm = lm;
		this.defaultImage = defaultImage;

#if VALA_0_14
		rows = new Sequence<AlbumViewModelObject>();
#else
		rows = new Sequence<AlbumViewModelObject>(null);
#endif
       
       stamp = (int)GLib.Random.next_int();
	}
	
	/** Returns Type of column at index_ **/
	public Type get_column_type (int col) {
		if(col == 0)
			return typeof(Gdk.Pixbuf);
		else
			return typeof(string);
	}

	/** Returns a set of flags supported by this interface **/
	public TreeModelFlags get_flags () {
		return TreeModelFlags.LIST_ONLY;
	}

	/** Sets iter to a valid iterator pointing to path **/
	public bool get_iter (out TreeIter iter, TreePath path) {
		int path_index = path.get_indices()[0];
		
		if(rows.get_length() == 0 || path_index < 0 || path_index >= rows.get_length())
			return false;
		
        var seq_iter = rows.get_iter_at_pos(path_index);
        if(seq_iter == null)
			return false;
        
		iter.stamp = this.stamp;
		iter.user_data = seq_iter;
        
		return true;
	}
	
	/** Returns the number of columns supported by tree_model. **/
	public int get_n_columns () {
		return 2;
	}

	/** Returns a newly-created Gtk.TreePath referenced by iter. **/
#if VALA_0_14
	public TreePath? get_path (TreeIter iter) {
#else
	public TreePath get_path (TreeIter iter) {
#endif
		return new TreePath.from_string(((SequenceIter)iter.user_data).get_position().to_string());
	}

	/** Initializes and sets value to that at column. **/
	public void get_value (TreeIter iter, int column, out Value val) {
		if(iter.stamp != this.stamp || column < 0 || column >= 2)
			return;
		
		if(!((SequenceIter<AlbumViewModelObject>)iter.user_data).is_end()) {
			if(column == 0)
				val = rows.get(((SequenceIter<AlbumViewModelObject>)iter.user_data)).art;
			else
				val = rows.get(((SequenceIter<AlbumViewModelObject>)iter.user_data)).album + "\n" + rows.get(((SequenceIter<AlbumViewModelObject>)iter.user_data)).artist;
		}
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
		if(iter == null)
			return rows.get_length();
		
		return 0;
	}

	/** Sets iter to point to the node following it at the current level. **/
	public bool iter_next (ref TreeIter iter) {
		if(iter.stamp != this.stamp)
			return false;
		
		iter.user_data = ((SequenceIter)iter.user_data).next();
		
		if(((SequenceIter)iter.user_data).is_end())
			return false;
		
		return true;
	}

	/** Sets iter to be the child of parent, using the given index. **/
	public bool iter_nth_child (out TreeIter iter, TreeIter? parent, int n) {
		if(n < 0 || n >= rows.get_length() || parent != null)
			return false;
		
		iter.stamp = this.stamp;
		iter.user_data = rows.get_iter_at_pos(n);
		
		return true;
	}

	/** Sets iter to be the parent of child. **/
	public bool iter_parent (out TreeIter iter, TreeIter child) {
		
		return false;
	}

	/** Lets the tree ref the node. **/
	public void ref_node (TreeIter iter) {}

	/** Lets the tree unref the node. **/
	public void unref_node (TreeIter iter) {}
    
    public TreeIter? getIterFromAlbumArtist(string album, string artist) {
    /** Some actual functions to use this model **/
		SequenceIter s_iter = rows.get_begin_iter();
		
		for(int index = 0; index < rows.get_length(); ++index) {
			s_iter = rows.get_iter_at_pos(index);
			
			if(artist == rows.get(s_iter).artist && album == rows.get(s_iter).album) {
				TreeIter iter = TreeIter();
				iter.stamp = this.stamp;
				iter.user_data = s_iter;
				
				return iter;
			}
		}
		
		return null;
	}
    
    /** simply adds iter to the model **/
    public void append(out TreeIter iter) {
		SequenceIter<AlbumViewModelObject> added = rows.append(new AlbumViewModelObject(defaultImage, "", ""));
		iter.stamp = this.stamp;
		iter.user_data = added;
	}
	
	/** convenience method to insert songs into the model. No iters returned. **/
    public void appendAlbums(Collection<AlbumViewModelObject> albums, bool emit) {
		foreach(var album in albums) {
			SequenceIter<AlbumViewModelObject> added = rows.append(album);
			
			if(emit) {
				TreePath path = new TreePath.from_string(added.get_position().to_string());
			
				TreeIter iter = TreeIter();
				iter.stamp = this.stamp;
				iter.user_data = added;
				
				row_inserted(path, iter);
			}
		}
	}
	
	/** @artistOld the old artist name
	 * @albumOld the old album name
	 * @album the new album object to use
	*/
	public void updateAlbum(string artistOld, string albumOld, AlbumViewModelObject album) {
		SequenceIter s_iter = rows.get_begin_iter();
		
		for(int index = 0; index < rows.get_length(); ++index) {
			s_iter = rows.get_iter_at_pos(index);
			
			if(rows.get(s_iter).artist == artistOld && rows.get(s_iter).album == albumOld) {
				rows.set(s_iter, album);
				
				TreePath path = new TreePath.from_string(s_iter.get_position().to_string());
				
				TreeIter iter = TreeIter();
				iter.stamp = this.stamp;
				iter.user_data = s_iter;
				
				row_changed(path, iter);
				
				return;
			}
		}
	}
	
	public new void set(TreeIter iter, ...) {
		if(iter.stamp != this.stamp)
			return;
		
		var args = va_list(); // now call args.arg() to poll
		
		while(true) {
			int col = args.arg();
			if(col < 0 || col >= 1)
				return;
			else if(col == 0) {
				stdout.printf("set oh hi3\n");
				Gdk.Pixbuf val = args.arg();
				rows.get(((SequenceIter<AlbumViewModelObject>)iter.user_data)).art = val;
			}
			else {
				stdout.printf("set oh hi4\n");
				string val = args.arg();
				rows.get(((SequenceIter<AlbumViewModelObject>)iter.user_data)).album = val.split("\n")[0];
				rows.get(((SequenceIter<AlbumViewModelObject>)iter.user_data)).artist = val.split("\n")[1];
			}
		}
	}
	
	public void remove(TreeIter iter) {
		if(iter.stamp != this.stamp)
			return;
			
		var path = new TreePath.from_string(((SequenceIter)iter.user_data).get_position().to_string());
		rows.remove((SequenceIter<AlbumViewModelObject>)iter.user_data);
		row_deleted(path);
	}
	
	/*public void removeSongs(Collection<int> rowids) {
		SequenceIter s_iter = rows.get_begin_iter();
		
		for(int index = 0; index < rows.get_length(); ++index) {
			s_iter = rows.get_iter_at_pos(index);
			
			if(rowids.contains(rows.get(s_iter).values[0].get_int())) {
				int rowid = rows.get(s_iter).values[0].get_int();
				TreePath path = new TreePath.from_string(s_iter.get_position().to_string());
					
				rows.remove(s_iter);
					
				row_deleted(path);
				rowids.remove(rowid);
				--index;
			}
			
			if(rowids.size <= 0)
				return;
		}
	}*/
	
	/*public LinkedList<Song> getOrderedSongs() {
		var rv = new LinkedList<Song>();
		SequenceIter s_iter = rows.get_begin_iter();
		
		for(int index = 0; index < rows.get_length(); ++index) {
			s_iter = rows.get_iter_at_pos(index);
			
			if(id == rows.get(s_iter).values[0].get_int()) {
				rows.get(s_iter).values[_columns.index_of(" ")] = Value(typeof(Gdk.Pixbuf));;
				
				TreePath path = new TreePath.from_string(s_iter.get_position().to_string());
				
				TreeIter iter = TreeIter();
				iter.stamp = this.stamp;
				iter.user_data = s_iter;
				
				row_changed(path, iter);
				return;
			}
		}
	}*/
}
