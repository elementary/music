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

using Gee;

public class BeatBox.SimilarViewWrapper : ViewWrapper {
	public static const int REQUIRED_MEDIAS = 10;
	Media base_media;
	bool fetched;
	public new bool have_media { get { return media_count >= REQUIRED_MEDIAS; } }
	
	public SimilarViewWrapper(LibraryWindow lw, Collection<int> the_medias, TreeViewSetup tvs, int id) {
		base(lw, the_medias, tvs, id);
		
		fetched = false;
		lm.media_played.connect(media_played);
		lm.lfm.similar_retrieved.connect(similar_retrieved);
	}
	
	void media_played(int id, int old) {
		fetched = false;
		
		if(!list_view.get_is_current_list()) {
			base_media = lm.media_from_id(id);
			set_media(new LinkedList<int>());
		}
	}
	
	void similar_retrieved(LinkedList<int> similar_internal, LinkedList<Media> similar_external) {
		fetched = true;
		set_media (similar_internal);
	}
	
	public void savePlaylist() {
		if(base_media == null) {
			stdout.printf("User tried to save similar playlist, but there is no base media\n");
			return;
		}
		
		Playlist p = new Playlist();

		p.name = _("Similar to %s").printf (base_media.title);
		
		var to_add = new LinkedList<int>();
		foreach(Media m in list_view.get_table().get_values()) {
			to_add.add(m.rowid);
		}
		p.addMedias(to_add);
		
		lm.add_playlist(p);
		lw.addSideListItem(p);
		lw.sideTree.sideListSelectionChange();
	}
	
	public new void set_media (Collection<int> new_media) {
		if(!list_view.get_is_current_list()) {
			in_update.lock ();
			
			/** We don't want to populate with songs if there are not
			enough for it to be valid. Only populate to set 0 songs or
			to populate with at least REQUIRED_MEDIAS songs. **/
			if(!fetched || new_media.size >= REQUIRED_MEDIAS) {
				var medias = new HashTable<int, Media>(null, null);
				foreach(int i in new_media) {
					medias.set((int)medias.size(), lm.media_from_id(i));
				}
				
				list_view.set_table(medias);
			}
			
			set_statusbar_info ();
			update_library_window_widgets ();
			in_update.unlock ();
			
			if(base_media != null) {
				if(!fetched) { // still fetching similar media
					error_box.show_icon = false;
					error_box.setWarning("<span weight=\"bold\" size=\"larger\">" + _("Fetching similar songs") + "\n</span>\n" + _("BeatBox is finding songs similar to" + " <b>" + base_media.title.replace("&", "&amp;") + "</b> by <b>" + base_media.artist.replace("&", "&amp;") + "</b>.\n"));
					set_active_view (ViewType.ERROR);

					return;
				}
				else {
					if(new_media.size < REQUIRED_MEDIAS) { // say we could not find similar media
						if (have_error_box) {
							error_box.show_icon = true;
							error_box.setWarning("<span weight=\"bold\" size=\"larger\">" + _("No similar songs found") + "\n</span>\n" + _("BeatBox could not find songs similar to" + " <b>" + base_media.title.replace("&", "&amp;") + "</b> by <b>" + base_media.artist.replace("&", "&amp;") + "</b>.\n") + _("Make sure all song info is correct and you are connected to the Internet.\nSome songs may not have matches."));
							// Show the error box
							set_active_view (ViewType.ERROR);
						}

						return;
					}
					else {
						set_active_view (ViewType.LIST);
					}
				}
			}
		}
	}
}

