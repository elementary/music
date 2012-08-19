/*-
 * Copyright (c) 2011-2012 Noise developers
 *
 * Originally Written by Scott Ringwelski and Victor Eduardo for
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
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 *              Lucas Baudin <xapantu@gmail.com>
 */


/**
 * A place to store icon information and pixbufs.
 */

namespace LastFM.Icons {

	public Noise.Icon LASTFM_LOVE;
	public Noise.Icon LASTFM_BAN;

	/**
	 * Loads icon information and renders [preloaded] pixbufs
	 **/
	public void init () {
		LASTFM_LOVE = new Noise.Icon ("lastfm-love", 16, Noise.Icon.Category.ACTION, null, true);
		LASTFM_BAN = new Noise.Icon ("lastfm-ban", 16, Noise.Icon.Category.ACTION, null, true);
	}
}

