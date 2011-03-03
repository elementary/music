using Gtk;
using Gee;

public class BeatBox.SimilarPane : HPaned {
	BeatBox.LibraryManager _lm;
	BeatBox.LibraryWindow _lw;
	Song _base;
	Song _next;
	
	Collection<int> _have; // this is updated EVERY song play. does not necessarily represent what is showing
	Collection<Song> _shouldHave; //^
	
	VBox left;
	Toolbar toolbar;
	ToolButton refresh;
	Label toolInfo;
	ToolButton transferPlayback;
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
		transferPlayback = new ToolButton.from_stock(Gtk.Stock.MEDIA_PLAY);
		toolInfo = new Label("");
		save = new ToolButton.from_stock(Gtk.Stock.SAVE);
		similars = new MusicTreeView(lm, lw, -1);
		ssv = new SimilarSongsView(_lm, _lw);
		
		similars.set_hint("similar");
		
		ToolItem toolInfoBin = new ToolItem();
		toolInfoBin.add(toolInfo);
		toolInfoBin.set_expand(true);
		
		refresh.set_tooltip_text("Refresh to show the most current song's similar songs");
		transferPlayback.set_tooltip_text("Transfer playback to continue playing these songs");
		save.set_tooltip_text("Save as a playlist");
		
		toolbar.insert(refresh, 0);
		toolbar.insert(transferPlayback, 1);
		toolbar.insert(toolInfoBin, 2);
		toolbar.insert(save, 3);
		
		left.pack_start(similars, true, true, 0);
		left.pack_end(toolbar, false, false, 0);
		
		add1(left);
		add2(ssv);
		child1_resize = 1;
		
		Allocation all;
		get_allocation(out all);
		set_position(all.width - 200);
		
		show_all();
		
		refresh.clicked.connect(refreshClicked);
		transferPlayback.clicked.connect(transferPlaybackClicked);
		save.clicked.connect(saveClicked);
		
		transferPlayback.hide();
	}
	
	public void updateSongs(Song la, Collection<int> have, Collection<Song> shouldHave) {
		_next = la;
		_have = have;
		_shouldHave = shouldHave;
		
		if(!(_lm.current_songs().size == similars.get_songs().size && _lm.current_songs().contains_all(similars.get_songs()))) {
			updateDisplay();
		}
		else {
			refresh.show();
			refresh.set_tooltip_text("Refresh to show songs similar to: " + _next.title + " by " + _next.artist);
			transferPlayback.hide();
		}
	}
	
	public void updateDisplay() {
		bool do_transfer = false;
		if((_lm.current_songs().size == similars.get_songs().size && _lm.current_songs().contains_all(similars.get_songs())))
			do_transfer = true;
		
		similars.populateView(_have, false);
		ssv.populateView(_shouldHave);
		
		_base = _next;
		toolInfo.set_markup("Songs similar to <b>" + _base.title + "</b> by <b>" + _base.artist + "</b>");
		refresh.hide();
		transferPlayback.show();
		save.show();
		
		if(do_transfer)
			transferPlaybackClicked();
		
		if(_lm.song_info.song != null)
			similars.updateSong(_lm.song_info.song.rowid);
	}
	
	public virtual void refreshClicked() {
		updateDisplay();
	}
	
	public virtual void transferPlaybackClicked() {
		//set the similar songs to current, hide button, set current_index
		similars.setAsCurrentList("0");
		
		transferPlayback.hide();
	}
	
	public virtual void saveClicked() {
		Playlist p = new Playlist();
		
		p.name = "Similar to " + _base.title;
		
		foreach(int id in similars.get_songs()) {
			p.addSong(_lm.song_from_id(id));
		}
		
		_lm.add_playlist(p);
		_lw.addSideListItem(p);
		
		save.hide();
	}
}
