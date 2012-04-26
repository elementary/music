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
using Gdk;

public class Store.ReleaseRotator : HBox {
	Store.StoreView storeView;
	LinkedList<Store.Release> releases;
	int index;
	bool cancelOld;
	
	private Gtk.Image albumArt;
	private Gtk.Label albumName;
	private Gtk.Label albumArtist;
	private Gtk.Label releaseDate;
	
	public ReleaseRotator(Store.StoreView view) {
		storeView = view;
		releases = new LinkedList<Store.Release>();
		index = 0;
		cancelOld = false;
		
		buildUI();
		switchReleases();
	}
	
	public void setReleases(LinkedList<Store.Release> rels) {
		this.releases = rels;
		cancelOld = true;
		switchReleases();
	}
	
	public void buildUI() {
		VBox topInfo = new VBox(false, 0);
		albumArt = new Gtk.Image();
		albumName = new Gtk.Label("");
		albumArtist = new Gtk.Label("");
		releaseDate = new Gtk.Label("");
		
		albumName.xalign = 0.0f;
		albumArtist.xalign = 0.0f;
		releaseDate.xalign = 0.0f;
		
		albumName.ellipsize = Pango.EllipsizeMode.END;
		albumArtist.ellipsize = Pango.EllipsizeMode.END;
		releaseDate.ellipsize = Pango.EllipsizeMode.END;
		
		topInfo.pack_start(wrap_alignment(albumName, 0, 0, 10, 0), false, true, 0);
		topInfo.pack_start(wrap_alignment(albumArtist, 0, 0, 10, 0), false, true, 0);
		topInfo.pack_start(wrap_alignment(releaseDate, 0, 0, 10, 0), false, true, 0);
		
		HBox tags = new HBox(false, 0);
		Color blue, lightblue, white;
		Color.parse("#366C9F", out blue);
		Color.parse("#E8EEF5", out lightblue);
		Color.parse("#ffffff", out white);
		
		/*tags.pack_start(wrap_alignment(new TagLabel("Rock", blue, lightblue, white), 0, 5, 10, 5), false, false, 0);
		tags.pack_start(wrap_alignment(new TagLabel("2000's", blue, lightblue, white), 0, 5, 10, 5), false, false, 0);
		tags.pack_start(wrap_alignment(new TagLabel("Pop", blue, lightblue, white), 0, 5, 10, 5), false, false, 0);
		tags.pack_start(wrap_alignment(new TagLabel("Indie", blue, lightblue, white), 0, 5, 10, 5), false, false, 0);*/
		
		topInfo.pack_start(wrap_alignment(tags, 0, 0, 10, 0), false, false, 0);
		
		pack_start(wrap_alignment(albumArt, 0, 10, 0, 0), false, true, 0);
		pack_start(topInfo, true, true, 0);
		
		show_all();
	}
	
	public static Gtk.Alignment wrap_alignment (Gtk.Widget widget, int top, int right, int bottom, int left) {
		var alignment = new Gtk.Alignment(0.0f, 0.0f, 1.0f, 1.0f);
		alignment.top_padding = top;
		alignment.right_padding = right;
		alignment.bottom_padding = bottom;
		alignment.left_padding = left;
		
		alignment.add(widget);
		return alignment;
	}
	
	public bool switchReleases() {
		if(releases.size == 0) {
			Timeout.add(5000, switchReleases);
			return false;
		}
		if(cancelOld) {
			cancelOld = false;
			return false;
		}
		
		if(index + 1 >= releases.size)
			index = 0;
		else
			++index;
		
		Release release = releases.get(index);
		albumName.set_markup("<span weight=\"bold\" font=\"40\">" + release.title.replace("&", "&amp;") + "</span>");
		albumArtist.set_markup("<span font=\"24\">" + release.artist.name.replace("&", "&amp;") + "</span>");
		releaseDate.set_markup("<span font=\"14\">Released " + release.releaseDate.substring(0, 10).replace("-", "/") + "</span>");
		
		if(release.image == null)
			release.image = Store.store.getPixbuf(release.imagePath, 200, 200);
		
		if(release.image != null) {
			albumArt.set_from_pixbuf(release.image);
		}
		
		Timeout.add(5000, switchReleases);
		
		return false;
	}
}
