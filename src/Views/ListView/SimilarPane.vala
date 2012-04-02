/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
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

// FIXME: currently broken.


using Gtk;
using Gee;

public class BeatBox.SimilarPane : MusicTreeView {

	public Media _base;
	public Media _next;

	// this is updated EVERY media play. does not necessarily represent what is showing
	public LinkedList<int> _have { get; private set; }
	
	public signal void playlist_saved(Playlist p);
	
	public SimilarPane(ViewWrapper view_wrapper) {
		var lm = view_wrapper.lm;
		base(view_wrapper, lm.similar_setup.sort_column, lm.similar_setup.sort_direction, ViewWrapper.Hint.SIMILAR, -1);
		
		_have = new LinkedList<int>();
		
		//lm.media_played.connect(mediaPlayed);
	}
	
	public void updateMedias(Media la, LinkedList<int> have) {
		_next = la;
		_have = have;
		
		if(!is_current_view) {
			updateDisplay();
		}
	}
	
	public void updateDisplay() {
		bool do_transfer = false;
		if (is_current_view)
			do_transfer = true;

		set_show_next(_have);
		populate_view();
		
		_base = _next;
		
		if(do_transfer)
			transferPlaybackClicked();
	}
	
	public virtual void refreshClicked() {
		updateDisplay();
	}
	
	public virtual void transferPlaybackClicked() {
		//set the similar medias to current, hide button, set current_index
		set_as_current_list(0, true);
	}
	
	public virtual void savePlaylist() {
		Playlist p = new Playlist();

		p.name = _("Similar to %s").printf (_base.title);

		lm.add_playlist(p);
		lw.addSideListItem(p);
		
		p.addMedia(get_medias());
		
		lw.sideTree.sideListSelectionChange();
	}
}



// ORIGINAL

/*


public class BeatBox.SimilarPane : MusicTreeView {
	//BeatBox.LibraryManager lm;
	//BeatBox.LibraryWindow lw;
	public Media _base;
	public Media _next;
	
	public LinkedList<int> _have; // this is updated EVERY media play. does not necessarily represent what is showing
	
	public signal void playlist_saved(Playlist p);
	
	public SimilarPane(BeatBox.LibraryManager lm, BeatBox.LibraryWindow lw) {
		base(lm, lw, lm.similar_setup.sort_column, lm.similar_setup.sort_direction, ViewWrapper.Hint.SIMILAR, -1);
		
		_have = new LinkedList<int>();
		
		//similars = new MusicTreeView(lm, lw, lm.similar_setup.sort_column, lm.similar_setup.sort_direction, ViewWrapper.Hint.SIMILAR, -1);
		
		// set up white error label
		// not included ----
		errorBox = new EventBox();
		errorBox.add(errorLabel);
		
		Gdk.Color c = Gdk.Color();
		Gdk.Color.parse("#FFFFFF", out c);
		errorBox.modify_bg(StateType.NORMAL, c);
		
		errorLabel.xalign = 0.5f;
		errorLabel.justify = Justification.CENTER;
		errorLabel.set_markup("<span weight=\"bold\" size=\"larger\">Similar Media View</span>\nIn this view, BeatBox will automatically find medias similar to the one you are playing.\nYou can then start playing those medias, or save them for later.");
		// END non included----
		
		// set up toolbar
		
		//pack_start(errorBox, true, true, 0);
		//pack_start(similars, true, true, 0);
		
		show_all();
		
		
		lm.media_played.connect(mediaPlayed);
	}
	
	public void initializeView() {
		//errorBox.show();
	}
	
	public void mediaPlayed(int id, int old) {

	}
	
	public void updateMedias(Media la, LinkedList<int> have) {
		_next = la;
		_have = have;
		
		if(!get_is_current()) {
			updateDisplay();
		}
	}
	
	public void updateDisplay() {
		bool do_transfer = false;
		if(get_is_current())
			do_transfer = true;
		
		if(_have.size < 10) {
			//errorLabel.set_markup("<span weight=\"bold\" size=\"larger\">No Similar Medias</span>\nBeatBox could not find medias similar to " + _next.title.replace("&", "&amp;") + " by " + _next.artist.replace("&", "&amp;") + ".\nYou could have incorrect data, no internet connection, or non-mainstream music.");
			//errorBox.show();
		}
		else {
			//errorBox.hide();
		}
		
		set_show_next(_have);
		populate_view();
		
		_base = _next;
		
		if(do_transfer)
			transferPlaybackClicked();
		
		//if(lm.media_info.media != null)
			//similars.updateMedia(lm.media_info.media.rowid);
	}
	
	public virtual void refreshClicked() {
		updateDisplay();
	}
	
	public virtual void transferPlaybackClicked() {
		//set the similar medias to current, hide button, set current_index
		set_as_current_list(0, true);
		
		//transferPlayback.hide();
	}
	
	public virtual void savePlaylist() {
		Playlist p = new Playlist();
		
		p.name = "Similar to " + _base.title;
		
		foreach(int id in get_medias()) {
			p.addMedia(id);
		}
		
		lm.add_playlist(p);
		lw.addSideListItem(p);
		lw.sideTree.sideListSelectionChange();
	}
}

*/
