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

public class BeatBox.SimilarPane : MusicTreeView {
	//BeatBox.LibraryManager lm;
	//BeatBox.LibraryWindow lw;
	public Song _base;
	public Song _next;
	
	public LinkedList<int> _have; // this is updated EVERY song play. does not necessarily represent what is showing
	
	public signal void playlist_saved(Playlist p);
	
	public SimilarPane(BeatBox.LibraryManager lm, BeatBox.LibraryWindow lw) {
		base(lm, lw, lm.similar_setup.sort_column, lm.similar_setup.sort_direction, MusicTreeView.Hint.SIMILAR, -1);
		
		_have = new LinkedList<int>();
		
		//similars = new MusicTreeView(lm, lw, lm.similar_setup.sort_column, lm.similar_setup.sort_direction, MusicTreeView.Hint.SIMILAR, -1);
		
		/* set up white error label */
		/*errorBox = new EventBox();
		errorBox.add(errorLabel);
		
		Gdk.Color c = Gdk.Color();
		Gdk.Color.parse("#FFFFFF", out c);
		errorBox.modify_bg(StateType.NORMAL, c);
		
		errorLabel.xalign = 0.5f;
		errorLabel.justify = Justification.CENTER;
		errorLabel.set_markup("<span weight=\"bold\" size=\"larger\">Similar Song View</span>\nIn this view, BeatBox will automatically find songs similar to the one you are playing.\nYou can then start playing those songs, or save them for later.");
		*/
		/* set up toolbar */
		
		//pack_start(errorBox, true, true, 0);
		//pack_start(similars, true, true, 0);
		
		show_all();
		
		
		lm.song_played.connect(songPlayed);
	}
	
	public void initializeView() {
		//errorBox.show();
	}
	
	public void songPlayed(int id, int old) {
		if(!(lm.current_songs().size == get_songs().size && lm.current_songs().contains_all(get_songs()))) {
			/* a new song is played. don't show list until songs have loaded */
			//similars.hide();
			
			//errorLabel.set_markup("<span weight=\"bold\" size=\"larger\">Loading similar songs</span>\nBeatBox is loading songs similar to " + lm.song_from_id(id).title.replace("&", "&amp;") + " by " + lm.song_from_id(id).artist.replace("&", "&amp;") + "...");
			//errorBox.show();
		}
	}
	
	public void updateSongs(Song la, LinkedList<int> have) {
		_next = la;
		_have = have;
		
		if(!(lm.current_songs().size == get_songs().size && lm.current_songs().contains_all(get_songs()))) {
			updateDisplay();
		}
	}
	
	public void updateDisplay() {
		bool do_transfer = false;
		if((lm.current_songs().size == get_songs().size && lm.current_songs().contains_all(get_songs())))
			do_transfer = true;
		
		if(_have.size < 10) {
			//errorLabel.set_markup("<span weight=\"bold\" size=\"larger\">No Similar Songs</span>\nBeatBox could not find songs similar to " + _next.title.replace("&", "&amp;") + " by " + _next.artist.replace("&", "&amp;") + ".\nYou could have incorrect data, no internet connection, or non-mainstream music.");
			//errorBox.show();
		}
		else {
			//errorBox.hide();
		}
		
		populateView(_have, false, false);
		
		_base = _next;
		
		if(do_transfer)
			transferPlaybackClicked();
		
		//if(lm.song_info.song != null)
			//similars.updateSong(lm.song_info.song.rowid);
	}
	
	public virtual void refreshClicked() {
		updateDisplay();
	}
	
	public virtual void transferPlaybackClicked() {
		//set the similar songs to current, hide button, set current_index
		setAsCurrentList(0);
		
		//transferPlayback.hide();
	}
	
	public virtual void savePlaylist() {
		Playlist p = new Playlist();
		
		p.name = "Similar to " + _base.title;
		
		foreach(int id in get_songs()) {
			p.addSong(lm.song_from_id(id));
		}
		
		lm.add_playlist(p);
		lw.addSideListItem(p);
		lw.sideTree.sideListSelectionChange();
	}
}
