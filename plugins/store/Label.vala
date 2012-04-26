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

public class Store.Label : GLib.Object {
	public int labelID;
	public string name;
	
	public Label(int id) {
		labelID = id;
		name = "";
	}
}

public class Store.Tag : GLib.Object {
	public string tagID;
	public string text;
	public string url;
	
	public Tag(string id) {
		tagID = id;
	}
	
	public Tag.with_values(string id, string text, string url) {
		this.tagID = id;
		this.text = text;
		this.url = url;
	}
}
