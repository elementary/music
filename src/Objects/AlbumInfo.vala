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

public class Noise.AlbumInfo : Object {
    
    public string name { get; set; default=_("Unknown Album"); }
    public string artist { get; set; default=_("Unknown Artist"); }
    public string mbid { get; set; default=""; }
    public GLib.Date releasedate;
    public string summary { get; set; default=""; }
    
    public int listeners { get; set; default=0; }
    public int playcount { get; set; default=0; }
    
    public string image_uri { get; set; default=""; }
    
    public AlbumInfo () {
        
    }
    
    public string get_image_uri_from_pixbuf (Gdk.Pixbuf image) {
        string path = (GLib.Path.build_path ("/", Environment.get_user_cache_dir (), "noise", "album-art") +"/"+ artist+"-"+ name+".png");
        try {
            image.save (path, "png");
            return path;
        }
        catch (GLib.Error err) {
            warning ("Could not generate image: %s", err.message);
        }
        return "";
    }
    
    public string get_releasedate_as_string () {
        return (("%d/%d/%d").printf ((int)releasedate.get_day (), (int)releasedate.get_month (), (int)releasedate.get_year ()));
    }
    
    public void set_releasedate_from_string (string date_string) {
        string[] date_cut = date_string.split("-");
        date_cut.resize(3);
        releasedate.set_dmy ((GLib.DateDay)(int).parse (date_cut[0]),(int).parse (date_cut[1]),(GLib.DateYear)(int).parse (date_cut[2]));
    }
}
