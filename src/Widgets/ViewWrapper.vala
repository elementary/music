using Gtk;
using Gee;

public class BeatBox.ViewWrapper : VPaned {
	public LibraryManager lm;
	public LibraryWindow lw;
	MillerColumn miller;
	public MusicTreeView list;
	FilterView filterView;
	
	ViewType currentView;
	
	bool isCurrentView;
	bool isCurrent;
	
	public enum ViewType {
		LIST,
		FILTER_VIEW,
		MILLER
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
		
		miller = new MillerColumn(lm, lw, linkedSongs);
		filterView = new FilterView(lm, lw, linkedSongs);
		
		VBox bottom = new VBox(false, 0);
		
		bottom.pack_start(list, true, true, 0);
		bottom.pack_start(filterView, true, true, 0);
		
		pack1(miller, false, true);
		pack2(bottom, true, true);
		
		setView(ViewType.LIST);
		
		filterView.itemClicked.connect(filterViewItemClicked);
		lw.viewSelector.notify["selected"].connect( () => {
			switch(lw.viewSelector.selected) {
				case 0:
					setView(ViewWrapper.ViewType.FILTER_VIEW);
					break;
				case 1:
					setView(ViewWrapper.ViewType.LIST);
					break;
				case 2:
					setView(ViewWrapper.ViewType.MILLER);
					break;
			}
		});
	}
	
	public void setView(ViewType type) {
		if(type == ViewType.LIST || type == ViewType.MILLER) {
			list.show();
			filterView.hide();
			
			miller.set_visible(type == ViewType.MILLER);
		}
		else {
			list.hide();
			filterView.show();
			miller.hide();
		}
		
		currentView = type;
	}
	
	public ViewType getView() {
		return currentView;
	}
	
	public void populateViews(Collection<int> songs, bool isSearch) {
		list.populateView(songs, isSearch);
		
		var linkedSongs = new LinkedList<Song>();
		foreach(int id in songs)
			linkedSongs.add(lm.song_from_id(id));
		
		filterView.generateHTML(linkedSongs);
	}
	
	public virtual void filterViewItemClicked(string artist, string album) {
		setView(ViewType.LIST); // oooor miller??
	}
}
