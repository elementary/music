// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2013 Noise Developers (http://launchpad.net/noise)
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
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */
public class Noise.Media : Object {

    /// Used for unknown titles, artists, or album names.
    protected static string UNKNOWN = _("Unknown");

    public int rowid { get; set; }

    public virtual string uri {
        owned get { return file.get_uri (); }
        set {file = File.new_for_uri (value);}
    }

    public virtual uint64 file_size { get; set; default = 0; }
    public virtual bool file_exists { get { return this.file.query_exists (); } }

    public virtual File file { get; set; }

    public virtual bool isPreview { get; set; default = false; }
    public virtual bool isTemporary { get; set; default = false; }
    
    // TODO: evaluate if there's real need for these fields
    public virtual bool location_unknown { get; set; default = false; }
    public virtual bool has_embedded { get; set; default = false; }

    // XXX: these don't really belong here. It seems they only help to
    //      ease client-side stuff, and will be removed in the future
    public virtual GLib.Icon unique_status_image { get; set; }
    public virtual bool showIndicator { get; set; default = false; }

    /**
     * Metadata Fields
     */
    public virtual string title { get; set; default = ""; }
    public virtual uint track { get; set; default = 0; }
    public virtual uint track_count { get; set; default = 0; }
    public virtual string composer { get; set; default = ""; }
    public virtual string artist { get; set; default = ""; }
    public virtual string album_artist { get; set; default = ""; }
    public virtual string album { get; set; default = ""; }
    public virtual uint album_number { get; set; default = 1; }
    public virtual uint album_count { get; set; default = 1; }
    public virtual unowned Album album_info { get; set; default = null; }
    public virtual string grouping { get; set; default = ""; }
    public virtual string genre { get; set; default = ""; }
    public virtual string comment { get; set; default = ""; }
    public virtual string lyrics { get; set; default = ""; }
    public virtual uint year { get; set; default = 0; }
    public virtual uint bitrate { get; set; default = 0; }
    public virtual uint bpm { get; set; default = 0; }
    public virtual uint samplerate { get; set; default = 0; }

    public virtual uint length { get; set; default = 0; } // duration in miliseconds

    protected uint _rating;
    public virtual uint rating {
        get { return _rating; }
        set { _rating = value.clamp (0, 5); }
    }

    /**
     * Internal stats
     */
    public virtual uint play_count { get; set; default = 0; }
    public virtual uint skip_count { get; set; default = 0; }
    public virtual uint date_added { get; set; default = 0; }
    public virtual uint last_played { get; set; default = 0; }
    public virtual uint last_modified { get; set; default = 0; }

    public virtual int resume_pos { get; set; default = 0; }

    public inline string get_display_filename () {
        string? filename = String.locale_to_utf8 (file.get_basename () ?? UNKNOWN);
        return is_valid_string_field (filename) ? filename : UNKNOWN;
    }

    public inline string get_display_location () {
        if (isTemporary)
            return "";

        string? filename = String.locale_to_utf8 (file.get_path ());

        if (is_valid_string_field (filename))
            return "%s:/%s".printf (file.get_uri_scheme (), filename);

        return UNKNOWN;
    }

    public inline string get_display_title () {
        string title = this.title;
        return is_valid_string_field (title) ? title : get_display_filename ();
    }

    public inline string get_display_composer () {
        return get_simple_display_text (composer);
    }

    public inline string get_display_artist () {
        return get_simple_display_text (artist);
    }

    public inline string get_display_album_artist (bool use_artist_fallback = true) {
        string album_artist = this.album_artist;

        if (is_valid_string_field (album_artist))
            return album_artist;

        if (use_artist_fallback)
           return get_display_artist ();

        return UNKNOWN;
    }

    public inline string get_display_album () {
        return get_simple_display_text (album);
    }

    public inline string get_display_genre () {
        return get_simple_display_text (genre);
    }

    public static inline bool is_valid_string_field (string? text) {
        return !String.is_empty (text, true);
    }

    public string get_album_hashkey () {
        if (is_valid_string_field (album_artist))
            return "%s|%s".printf (album, album_artist);
        else
            return "%s|%s".printf (album, artist);
    }
    /**
     * It's called simple because it simply checks if the string is empty,
     * and returns UNKNOWN if it is.
     */
    internal static inline string get_simple_display_text (string? text) {
        return is_valid_string_field (text) ? text : UNKNOWN;
    }

    public string get_title_markup () {

        // We don't use the get_display_* for the artist and albums because
        // there's no point in showing "unknown" there. If the info is not available,
        // just skip it.
         string markup;
        if (!is_valid_string_field (artist) && is_valid_string_field (album))
            /// Please keep $NAME and $ALBUM, they will be replaced by their values
            markup = _("$NAME on $ALBUM").replace ("$ALBUM", "<b>" + String.escape (album) + "</b>").replace ("$NAME", "<b>" + String.escape (get_display_title ()) + "</b>");
        else if (is_valid_string_field (artist) && !is_valid_string_field (album))
            /// Please keep $NAME and $ARTIST, they will be replaced by their values
            markup = _("$NAME by $ARTIST").replace ("$ARTIST", "<b>" + String.escape (artist) + "</b>").replace ("$NAME", "<b>" + String.escape (get_display_title ()) + "</b>");
        else if (!is_valid_string_field (artist) && !is_valid_string_field (album))
            /// Please keep $NAME and $ARTIST, they will be replaced by their values
            markup = "<b>" + String.escape (get_display_title ()) + "</b>";
        else
            /// Please keep $NAME, $ARTIST and $ALBUM, they will be replaced by their values
            markup = _("$NAME by $ARTIST on $ALBUM").replace ("$ARTIST", "<b>" + String.escape (artist) + "</b>").replace ("$NAME", "<b>" + String.escape (get_display_title ()) + "</b>").replace ("$ALBUM", "<b>" + String.escape (album) + "</b>");

        return markup;
    }

    public Media (string uri) {
        this.uri = uri;
    }

    public Media.from_file (File file) {
        this.file = file;
    }

    public Media copy () {
        Media rv = new Media (uri);

        rv.file_size = file_size;
        rv.track = track;
        rv.track_count = track_count;
        rv.album_number = album_number;
        rv.album_count = album_count;
        rv.title = title;
        rv.artist = artist;
        rv.composer = composer;
        rv.album_artist = album_artist;
        rv.album = album;
        rv.genre = genre;
        rv.grouping = grouping;
        rv.comment = comment;
        rv.year = year;
        rv.bitrate = bitrate;
        rv.length = length;
        rv.samplerate = samplerate;
        rv.bpm = bpm;
        rv.rating = rating;
        rv.play_count = play_count;
        rv.skip_count = skip_count;
        rv.date_added = date_added;
        rv.last_played = last_played;
        rv.lyrics = lyrics; 
        rv.isPreview = isPreview;
        rv.isTemporary = isTemporary;
        rv.last_modified = last_modified;
        rv.showIndicator = showIndicator;
        rv.unique_status_image = unique_status_image;
        rv.location_unknown = location_unknown;

        return rv;
    }
}
