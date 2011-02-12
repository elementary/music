using Gtk;
using Gee;

public class BeatBox.SimilarPane : HPaned {
	BeatBox.LibraryManager _lm;
	BeatBox.LibraryWindow _lw;
	Song _base;
	
	Collection<int> _have; // this is updated EVERY song play. does not necessarily represent what is showing
	Collection<Song> _shouldHave; //^
	
	VBox left;
	Toolbar toolbar;
	ToolButton refresh;
	ToolButton save;
	MusicTreeView similars;
	SimilarSongsView ssv;
	
	public signal void playlist_saved(Playlist p);
	
	public SimilarPane(BeatBox.LibraryManager lm, BeatBox.LibraryWindow lw) {
		_lm = lm;
		_lw = lw;
		
		left = new VBox(false, 0);
		toolbar = new Toolbar();
		refresh = new ToolButton.from_stock(Gtk.Stock.REFRESH);
		save = new ToolButton.from_stock(Gtk.Stock.SAVE);
		similars = new MusicTreeView(lm, lw, -1);
		ssv = new SimilarSongsView(_lm, _lw);
		
		similars.set_hint("similar");
		
		toolbar.insert(refresh, 0);
		toolbar.insert(save, 1);
		
		left.pack_start(toolbar, false, false, 0);
		left.pack_end(similars, true, true, 0);
		
		add1(left);
		add2(ssv);
		child2_resize = 1;
		
		Allocation all;
		get_allocation(out all);
		set_position(700);
		
		show_all();
		
		refresh.clicked.connect(refreshClicked);
		save.clicked.connect(saveClicked);
	}
	
	public void updateSongs(Song bas, Collection<int> have, Collection<Song> shouldHave) {
		_base = bas;
		_have = have;
		_shouldHave = shouldHave;
		
		if(!(_lm.current_songs().size == similars.get_songs().size && _lm.current_songs().contains_all(similars.get_songs()))) {
			similars.populateView(_have, false);
			ssv.populateView(shouldHave);
		}
	}
	
	public virtual void refreshClicked() {
		similars.populateView(_have, false);
		ssv.populateView(_shouldHave);
	}
	
	public virtual void saveClicked() {
		Playlist p = new Playlist();
		p.name = "Similar to " + _base.title;
		
		foreach(int id in similars.get_songs()) {
			p.addSong(_lm.song_from_id(id));
		}
		
		_lm.add_playlist(p);
		_lw.addSideListItem(p);
	}
}
