using Gtk;
using Gee;

public class BeatBox.SimilarPane : VBox {
	BeatBox.LibraryManager _lm;
	BeatBox.LibraryWindow _lw;
	public Song _base;
	Song _next;
	
	public LinkedList<int> _have; // this is updated EVERY song play. does not necessarily represent what is showing
	
	HBox toolbar;
	ToolButton refresh;
	Label toolInfo;
	ToolButton transferPlayback;
	ToolButton save;
	MusicTreeView similars;
	EventBox errorBox;
	Label errorLabel;
	
	public signal void playlist_saved(Playlist p);
	
	public SimilarPane(BeatBox.LibraryManager lm, BeatBox.LibraryWindow lw) {
		_lm = lm;
		_lw = lw;
		
		_have = new LinkedList<int>();
		
		errorLabel = new Label("");
		toolbar = new HBox(false, 0);
		refresh = new ToolButton(null, "Update to Most Recent Song");
		transferPlayback = new ToolButton(null, "Start Playing These Songs");
		toolInfo = new Label("");
		save = new ToolButton(null, "Save as Playlist");
		similars = new MusicTreeView(lm, lw, _lm.similar_setup.sort_column, _lm.similar_setup.sort_direction, MusicTreeView.Hint.SIMILAR, -1);
		
		/* set up white error label */
		errorBox = new EventBox();
		errorBox.add(errorLabel);
		
		Gdk.Color c = Gdk.Color();
		Gdk.Color.parse("#FFFFFF", out c);
		errorBox.modify_bg(StateType.NORMAL, c);
		
		errorLabel.xalign = 0.5f;
		errorLabel.justify = Justification.CENTER;
		errorLabel.set_markup("<span weight=\"bold\" size=\"larger\">Similar Song View</span>\nIn this view, BeatBox will automatically find songs similar to the one you are playing. You can then start playing those songs, or save them for later.");
		
		/* set up toolbar */
		ToolItem toolInfoBin = new ToolItem();
		toolInfoBin.add(toolInfo);
		toolInfoBin.set_expand(true);
		
		refresh.set_tooltip_text("Refresh to show the most current song's similar songs");
		transferPlayback.set_tooltip_text("Transfer playback to continue playing these songs");
		save.set_tooltip_text("Save as a playlist");
		
		toolbar.pack_start(refresh, false, false, 0);
		toolbar.pack_start(transferPlayback, false, false, 0);
		toolbar.pack_end(save, false, false, 0);
		
		pack_start(errorBox, true, true, 0);
		pack_start(toolbar, false, false, 0);
		pack_start(similars, true, true, 0);
		
		show_all();
		
		
		_lm.song_played.connect(songPlayed);
		refresh.clicked.connect(refreshClicked);
		transferPlayback.clicked.connect(transferPlaybackClicked);
		save.clicked.connect(saveClicked);
		
		transferPlayback.hide();
	}
	
	public void initializeView() {
		errorBox.show();
		similars.hide();
		toolbar.hide();
	}
	
	public void songPlayed(int id, int old) {
		if(!(_lm.current_songs().size == similars.get_songs().size && _lm.current_songs().contains_all(similars.get_songs()))) {
			/* a new song is played. don't show list until songs have loaded */
			similars.hide();
			toolbar.hide();
			
			errorLabel.set_markup("<span weight=\"bold\" size=\"larger\">Loading similar songs</span>\nBeatBox is loading songs similar to " + _lm.song_from_id(id).title.replace("&", "&amp;") + " by " + _lm.song_from_id(id).artist.replace("&", "&amp;") + "...");
			errorBox.show();
		}
	}
	
	public void updateSongs(Song la, LinkedList<int> have) {
		_next = la;
		_have = have;
		
		if(_have.size < 10) {
			errorLabel.set_markup("<span weight=\"bold\" size=\"larger\">No Similar Songs</span>\nBeatBox could not find songs similar to " + la.title.replace("&", "&amp;") + " by " + la.artist.replace("&", "&amp;") + ".\nYou could have incorrect data, no internet connection, or non-mainstream music.");
			errorBox.show();
			similars.hide();
			toolbar.hide();
			return;
		}
		else {
			errorBox.hide();
			similars.show();
			toolbar.show();
		}
		
		if(!(_lm.current_songs().size == similars.get_songs().size && _lm.current_songs().contains_all(similars.get_songs()))) {
			updateDisplay();
		}
		else {
			refresh.show();
			refresh.set_tooltip_markup("Refresh to show songs similar to: <b>" + _next.title.replace("&", "&amp;") + "</b> by <b>" + _next.artist.replace("&", "&amp;") + "</b>");
			transferPlayback.hide();
		}
	}
	
	public void updateDisplay() {
		bool do_transfer = false;
		if((_lm.current_songs().size == similars.get_songs().size && _lm.current_songs().contains_all(similars.get_songs())))
			do_transfer = true;
		
		similars.populateView(_have, false);
		
		_base = _next;
		toolInfo.set_markup("Songs similar to <b>" + _base.title.replace("&", "&amp;") + "</b> by <b>" + _base.artist.replace("&", "&amp;") + "</b>");
		toolbar.show();
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
		similars.setAsCurrentList(null);
		
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
		
		if(refresh.visible == false && transferPlayback.visible == false)
			toolbar.hide();
	}
}
