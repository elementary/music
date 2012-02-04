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

/*using Gtk;

public class BeatBox.DeviceBar : Gtk.HBox {
	LibraryManager lm;
	LibraryWindow lw;
	Device d;
	
	Gtk.Button transfer;
	Gtk.Button sync;
	Granite.Widgets.StaticNotebook tabs;
	
	public signal void option_changed(int option);
	public signal void sync_requested();
	
	public DeviceBar(LibraryManager lm, Device d) {
		this.d = d;
		
		buildUI();
	}
	
	void buildUI() {
		transfer = new Button.with_label("Transfer");
		sync = new Button.with_label("Sync");
		tabs = new Granite.Widgets.StaticNotebook();
		//playlist_list = new ListStore(2, typeof(int), typeof(string));
		
		transfer.set_size_request(100, 20);
		sync.set_size_request(100, 20);
		tabs.halign = Align.CENTER;
		
		tabs.append_page( createDummy(), new Label("General"));
		tabs.append_page( createDummy(), new Label("Music"));
		tabs.append_page( createDummy(), new Label("Podcasts"));
		
		pack_start(wrap_alignment(transfer, 5, 0, 5, 6), false, false, 0);
		pack_end(wrap_alignment(sync, 5, 6, 5, 0), false, false, 0);
		pack_start(tabs, true, false, 8);
		
		tabs.page_changed.connect( (index) => { option_changed(index); });
		sync.clicked.connect(syncClick);
	}
	
	Layout createDummy() {
		Layout rv = new Layout(null, null);
		rv.height = 0;
		rv.width = 0;
		
		return rv;
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
	
	void syncClick() {
		sync_requested();
	}
	
	public int currentPage() {
		return tabs.page;
	}
}*/
