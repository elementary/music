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

public class Noise.TrackInfo : GLib.Object {
    
    public int id;
    public string name { get; set; default=_("Unknown Track"); }
    public string artist;
    public string album;
    public int duration;
    public int listeners;
    public int playcount;
    
    public string summary;
    public string content;
    
    
    public TrackInfo () {
        
    }
    
    public TrackInfo.with_info(string artist, string name) {
        this.name = name;
        this.artist = artist;
    }
    
}
