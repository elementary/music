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

		foreach(int id in get_medias()) {
			p.addMedia(id);
		}
		
		lm.add_playlist(p);
		lw.addSideListItem(p);
		lw.sideTree.sideListSelectionChange();
	}
}
