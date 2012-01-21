/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
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
using Gee;
using GLib;

public class BeatBox.AlbumViewModel : GLib.Object, TreeModel, TreeSortable {
	LibraryManager lm;
	int stamp; // all iters must match this
	Gdk.Pixbuf defaultImage;
	
    /* data storage variables */
    Sequence<Media> rows;
    
    /* threaded pixbuf fetching */
    private int sort_column_id;
    private SortType sort_direction;
    private unowned TreeIterCompareFunc default_sort_func;
    private HashMap<int, CompareFuncHolder> column_sorts;
    
    public TreeIter start_visible;
    public TreeIter end_visible;
    bool removing_medias;
    
    /* custom signals for custom treeview. for speed */
    public signal void rows_changed(LinkedList<TreePath> paths, LinkedList<TreeIter?> iters);
    public signal void rows_deleted (LinkedList<TreePath> paths);
	public signal void rows_inserted (LinkedList<TreePath> paths, LinkedList<TreeIter?> iters);
	
	/** Initialize data storage, columns, etc. **/
	public AlbumViewModel(LibraryManager lm, Gdk.Pixbuf defaultImage) {
		this.lm = lm;
		this.defaultImage = lm.get_cover_shadow(defaultImage);
		removing_medias = false;

		rows = new Sequence<Media>();
		
		sort_column_id = -2;
		sort_direction = SortType.ASCENDING;
		column_sorts = new HashMap<int, CompareFuncHolder>();
       
		stamp = (int)GLib.Random.next_int();
	}
	
	/** Returns Type of column at index_ **/
	public Type get_column_type (int col) {
		if(col == 0)
			return typeof(Gdk.Pixbuf);
		else if(col == 1)
			return typeof(string);
		else
			return typeof(Media);
		
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
		return 3;
	}

	/** Returns a newly-created Gtk.TreePath referenced by iter. **/
	public TreePath? get_path (TreeIter iter) {
		return new TreePath.from_string(((SequenceIter)iter.user_data).get_position().to_string());
	}

	/** Initializes and sets value to that at column. **/
	public void get_value (TreeIter iter, int column, out Value val) {
		if(iter.stamp != this.stamp || column < 0 || column > 2)
			return;
			
		if(removing_medias) {
			val = Value(get_column_type(column));
			return;
		}
		
		if(!((SequenceIter<Media>)iter.user_data).is_end()) {
			Media s = rows.get(((SequenceIter<Media>)iter.user_data));
			
			if(column == 0) {
				if(lm.get_cover_album_art_from_key(s.album_artist, s.album) != null) {
					val = lm.get_cover_album_art_from_key(s.album_artist, s.album);
				}
				else {
					val = defaultImage;
				}
				
			}
			else if(column == 1)
				val = s.album.replace("&", "&amp;") + "\n" + "<span foreground=\"#999\">" + s.album_artist.replace("&", "&amp;") + "</span>";
			else if(column == 2) {
				val = s;
			}
		}
	}
	
	public Media get_media_representation(Gtk.TreeIter iter) {
	    return rows.get(((SequenceIter<Media>)iter.user_data));
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
    
    /** simply adds iter to the model **/
    public void append(out TreeIter iter) {
		SequenceIter<Media> added = rows.append(new Media(""));
		iter.stamp = this.stamp;
		iter.user_data = added;
	}
	
	/** convenience method to insert medias into the model. No iters returned. **/
    public void appendMedias(Collection<Media> albums, bool emit) {
		foreach(var album in albums) {
			SequenceIter<Media> added = rows.append(album);
			
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
	public void updateAlbum(string artistOld, string albumOld, Media album) {
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
			
			
		}
	}
	
	public void remove(TreeIter iter) {
		if(iter.stamp != this.stamp)
			return;
			
		var path = new TreePath.from_string(((SequenceIter)iter.user_data).get_position().to_string());
		rows.remove((SequenceIter<Media>)iter.user_data);
		row_deleted(path);
	}
	
	public void removeMedias(Collection<Media> rowids, bool emit) {
		removing_medias = true;
		SequenceIter s_iter = rows.get_begin_iter();
		
		for(int index = 0; index < rows.get_length(); ++index) {
			s_iter = rows.get_iter_at_pos(index);
			
			foreach(var m in rowids) {
				if(m.album_artist == rows.get(s_iter).album_artist && m.album == rows.get(s_iter).album) {
					TreePath path = new TreePath.from_string(s_iter.get_position().to_string());
						
					rows.remove(s_iter);
					
					if(emit)
						row_deleted(path);
					
					--index;
				}
				
				if(rowids.size <= 0) {
					removing_medias = false;
					return;
				}
			}
		}
		
		removing_medias = false;
	}
	
	/** Fills in sort_column_id and order with the current sort column and the order. **/
	public bool get_sort_column_id(out int sort_column_id, out SortType order) {
		sort_column_id = this.sort_column_id;
		order = sort_direction;
		
		return true;
	}
	
	/** Returns true if the model has a default sort function. **/
	public bool has_default_sort_func() {
		return (default_sort_func != null);
	}
	
	/** Sets the default comparison function used when sorting to be sort_func. **/
	public void set_default_sort_func(owned TreeIterCompareFunc sort_func) {
		default_sort_func = sort_func;
	}
	
	/** Sets the current sort column to be sort_column_id. **/
	public void set_sort_column_id(int sort_column_id, SortType order) {
		bool changed = (this.sort_column_id != sort_column_id || order != sort_direction);
		
		this.sort_column_id = sort_column_id;
		sort_direction = order;
		
		if(changed && sort_column_id >= 0) {
			/* do the sort for reals */
			rows.sort_iter(sequenceIterCompareFunc);
			
			sort_column_changed();
		}
	}
	
	public void resort() {
		rows.sort_iter(sequenceIterCompareFunc);
		sort_column_changed();
	}
	
	/** Sets the comparison function used when sorting to be sort_func. **/
	public void set_sort_func(int sort_column_id, owned TreeIterCompareFunc sort_func) {
		column_sorts.set(sort_column_id, new CompareFuncHolder(sort_func));
	}
	
	/** Custom function to use built in sort in GLib.Sequence to our advantage **/
	public int sequenceIterCompareFunc(SequenceIter<Media> a, SequenceIter<Media> b) {
		int rv;
		
		if(sort_column_id < 0)
			return 0;
		
		Media a_media = rows.get(a);
		Media b_media = rows.get(b);
		
		if(a_media == null || b_media == null)
			return 1;
		
		if(a_media.album.down() == b_media.album.down())
			rv = advancedStringCompare(a_media.album.down(), b_media.album.down());
		else
			rv = advancedStringCompare(a_media.album_artist.down(), b_media.album_artist.down());
		
		if(sort_direction == SortType.DESCENDING)
			rv = (rv > 0) ? -1 : 1;
		
		return rv;
	}
	
	private int advancedStringCompare(string a, string b) {
		if(a == "" && b != "")
			return 1;
		else if(a != "" && b == "")
			return -1;
		
		return (a > b) ? 1 : -1;
	}
}
