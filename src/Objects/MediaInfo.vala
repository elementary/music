/*-
 * Copyright (c) 2012       Corentin Noël <tintou@mailoo.org>
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

/* Merely a place holder for multiple pieces of information regarding
 * the current media playing. Mostly here because of dependence. */

public class Noise.MediaInfo : GLib.Object {
	public Noise.Media? media;
	public Noise.ArtistInfo? artist;
	public Noise.TrackInfo? track;
	public Noise.AlbumInfo? album;
	
	public MediaInfo () {
		//don't initialize media because we check for null throughout the program
		artist = new Noise.ArtistInfo ();
		track = new Noise.TrackInfo ();
		album = new Noise.AlbumInfo ();
	}
	
	public void update (Noise.ArtistInfo? art, Noise.TrackInfo? tra, Noise.AlbumInfo? alb, Noise.Media? s) {
		media = s;
		artist = art;
		track = tra;
		album = alb;
	}
}
