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

	public SimilarViewWrapper(LibraryWindow lw, TreeViewSetup tvs, int id) {
		base(lw, tvs, id);
		
		fetched = false;
		lm.media_played.connect(on_media_played);
		lm.lfm.similar_retrieved.connect(similar_retrieved);
	}
	
	void on_media_played(Media new_media) {
		fetched = false;

		if (!list_view.get_is_current_list()) {
			base_media = new_media;
			set_media (new LinkedList<Media>());
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
		
		var to_add = new LinkedList<Media>();
		foreach (Media m in list_view.get_media ()) {
			to_add.add (m);
		}
		p.add_media (to_add);
		
		lm.add_playlist(p);
		lw.addSideListItem(p);
	}
	
	public new void set_media (Collection<int> new_media) {
		if(!list_view.get_is_current_list()) {
			in_update.lock ();
			
			/** We don't want to populate with songs if there are not
			enough for it to be valid. Only populate to set 0 songs or
			to populate with at least REQUIRED_MEDIAS songs. **/
			if(!fetched || new_media.size >= REQUIRED_MEDIAS) {
				var to_set = new Gee.LinkedList<Media> ();
				foreach (var id in new_media) {
					to_set.add (lm.media_from_id (id));
				}
				
				list_view.set_media (to_set);
			}
			
			update_statusbar_info ();
			update_library_window_widgets ();
			in_update.unlock ();
			
			if(base_media != null) {
				if(!fetched && has_embedded_alert) { // still fetching similar media
					embedded_alert.set_alert (_("Fetching similar songs"), _("Finding songs similar to %s by %s").printf ("<b>" + String.escape (base_media.title) + "</b>", "<b>" + String.escape (base_media.artist) + "</b>"), null, false);
					// Show the alert box
					set_active_view (ViewType.ALERT);

					return;
				}
				else {
					if(new_media.size < REQUIRED_MEDIAS) { // say we could not find similar media
						if (has_embedded_alert) {
							embedded_alert.set_alert (_("No similar songs found"), _("%s could not find songs similar to %s by %s. Make sure all song info is correct and you are connected to the Internet. Some songs may not have matches.").printf (String.escape (lw.app.get_name ()), "<b>" + String.escape (base_media.title) + "</b>", "<b>" + String.escape (base_media.artist) + "</b>"), null, true, Granite.AlertLevel.INFO);
							// Show the error box
							set_active_view (ViewType.ALERT);
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

