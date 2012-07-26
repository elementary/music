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

public class Noise.ArtistInfo : Object {
    
    public string name { get; set; default=_("Unknown Artist"); }
    public string mbid { get; set; default=""; } //music brainz id
    
    public int listeners { get; set; default=0; }
    public int playcount { get; set; default=0; }
    
    public string published { get; set; default=""; }
    public string summary { get; set; default=""; }
    public string content { get; set; default=""; }
    
    public string image_uri { get; set; default=""; }
    
    public ArtistInfo() {
        
    }
    
    public ArtistInfo.with_name(string artist) {
        this.name = name;
    }
    
    public ArtistInfo.with_name_and_mbid(string name, string mbid) {
        this.name = name;
        this.mbid = mbid;
    }
    
    public string get_image_uri_from_pixbuf (Gdk.Pixbuf image) {
        string path = (GLib.Path.build_path ("/", Environment.get_user_cache_dir (), "noise", "album-art") +"/" + name+"-"+ mbid +".png");
        try {
            image.save (path, "png");
            return path;
        }
        catch (GLib.Error err) {
            warning ("Could not generate image: %s", err.message);
        }
        return "";
    }
    
}
