using Gtk;
using Gee;

public class BeatBox.ViewWrapper : VBox {
	public LibraryManager lm;
	public LibraryWindow lw;
	public MusicTreeView list;
	FilterView filterView;
	
	ViewType currentView;
	
	bool isCurrentView;
	bool isCurrent;
	
	public enum ViewType {
		LIST,
		FILTER_VIEW
	}
	
	public ViewWrapper(LibraryManager lmm, LibraryWindow lww, Collection<int> songs, string sort, Gtk.SortType dir, MusicTreeView.Hint the_hint, int id) {
		lm = lmm;
		lw = lww;
		
		list = new MusicTreeView(lm, lw, sort, dir, the_hint, id);
		list.populateView(songs, false);
		
		/* have to convert to linked list<song> */
		var linkedSongs = new LinkedList<int>();
		foreach(int sid in songs)
			linkedSongs.add(sid);
		
		filterView = new FilterView(lm, lw, linkedSongs);
		
		pack_start(list, true, true, 0);
		pack_start(filterView, true, true, 0);
		
		setView(ViewType.LIST);
		
		filterView.itemClicked.connect(filterViewItemClicked);
	}
	
	public void setView(ViewType type) {
		if(type == ViewType.LIST) {
			list.show();
			filterView.hide();
		}
		else {
			list.hide();
			filterView.show();
		}
		
		currentView = type;
	}
	
	public virtual void filterViewItemClicked(string artist, string album) {
		setView(ViewType.LIST);
	}
}
