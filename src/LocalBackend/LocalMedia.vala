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
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Noise.LocalMedia : Noise.Media {
    private SQLHeavy.Database database = Noise.DataBaseManager.get_default ().database;

    private uint64? _file_size = null;
    public override uint64 file_size {
        get {
            common_uint64_getter ("file_size", ref _file_size);
            return _file_size;
        }
        set {
            common_uint64_setter ("file_size", value, ref _file_size);
        }
    }

    /**
     * Metadata Fields
     */
    private string _title = null;
    public override string title {
        get {
            common_string_getter ("title", ref _title);
            return _title;
        }
        set {
            common_string_setter ("title", value, ref _title);
        }
    }

    private uint? _track = null;
    public override uint track {
        get {
            common_uint_getter ("track", ref _track);
            return _track;
        }
        set {
            common_uint_setter ("track", value, ref _track);
        }
    }
    private uint? _track_count = null;
    public override uint track_count {
        get {
            common_uint_getter ("track_count", ref _track_count);
            return _track_count;
        }
        set {
            common_uint_setter ("track_count", value, ref _track_count);
        }
    }
    private string _composer = null;
    public override string composer {
        get {
            common_string_getter ("composer", ref _composer);
            return _composer;
        }
        set {
            common_string_setter ("composer", value, ref _composer);
        }
    }
    private string _artist = null;
    public override string artist {
        get {
            common_string_getter ("artist", ref _artist);
            return _artist;
        }
        set {
            common_string_setter ("artist", value, ref _artist);
        }
    }
    private string _album_artist = null;
    public override string album_artist {
        get {
            common_string_getter ("album_artist", ref _album_artist);
            return _album_artist;
        }
        set {
            common_string_setter ("album_artist", value, ref _album_artist);
        }
    }
    private string _album = null;
    public override string album {
        get {
            common_string_getter ("album", ref _album);
            return _album;
        }
        set {
            common_string_setter ("album", value, ref _album);
        }
    }
    private uint? _album_number = null;
    public override uint album_number {
        get {
            common_uint_getter ("album_number", ref _album_number);
            return _album_number;
        }
        set {
            common_uint_setter ("album_number", value, ref _album_number);
        }
    }
    private uint? _album_count = null;
    public override uint album_count {
        get {
            common_uint_getter ("album_count", ref _album_count);
            return _album_count;
        }
        set {
            common_uint_setter ("album_count", value, ref _album_count);
        }
    }
    public override unowned Album album_info { get; set; default = null; }
    private string _grouping = null;
    public override string grouping {
        get {
            common_string_getter ("grouping", ref _grouping);
            return _grouping;
        }
        set {
            common_string_setter ("grouping", value, ref _grouping);
        }
    }
    private string _genre = null;
    public override string genre {
        get {
            common_string_getter ("genre", ref _genre);
            return _genre;
        }
        set {
            common_string_setter ("genre", value, ref _genre);
        }
    }
    private string _comment = null;
    public override string comment {
        get {
            common_string_getter ("comment", ref _comment);
            return _comment;
        }
        set {
            common_string_setter ("comment", value, ref _comment);
        }
    }
    private string _lyrics = null;
    public override string lyrics {
        get {
            common_string_getter ("lyrics", ref _lyrics);
            return _lyrics;
        }
        set {
            common_string_setter ("lyrics", value, ref _lyrics);
        }
    }
    public uint? _year = null;
    public override uint year {
        get {
            common_uint_getter ("year", ref _year);
            return _year;
        }
        set {
            common_uint_setter ("year", value, ref _year);
        }
    }
    public uint? _bitrate = null;
    public override uint bitrate {
        get {
            common_uint_getter ("bitrate", ref _bitrate);
            return _bitrate;
        }
        set {
            common_uint_setter ("bitrate", value, ref _bitrate);
        }
    }
    public uint? _samplerate = null;
    public override uint samplerate {
        get {
            common_uint_getter ("samplerate", ref _samplerate);
            return _samplerate;
        }
        set {
            common_uint_setter ("samplerate", value, ref _samplerate);
        }
    }

    public uint? _length = null;
    public override uint length {
        get {
            common_uint_getter ("length", ref _length);
            return _length;
        }
        set {
            common_uint_setter ("length", value, ref _length);
        }
    }

    public override uint rating {
        get {
            common_uint_getter ("rating", ref _rating);
            return _rating;
        }
        set {
            common_uint_setter ("rating", value.clamp (0, 5), ref _rating);
        }
    }

    /**
     * Internal stats
     */
    public uint? _play_count = null;
    public override uint play_count {
        get {
            common_uint_getter ("playcount", ref _play_count);
            return _play_count;
        }
        set {
            common_uint_setter ("playcount", value, ref _play_count);
        }
    }
    public uint? _skip_count = null;
    public override uint skip_count {
        get {
            common_uint_getter ("skipcount", ref _skip_count);
            return _skip_count;
        }
        set {
            common_uint_setter ("skipcount", value, ref _skip_count);
        }
    }
    public uint? _date_added = null;
    public override uint date_added {
        get {
            common_uint_getter ("dateadded", ref _date_added);
            return _date_added;
        }
        set {
            common_uint_setter ("dateadded", value, ref _date_added);
        }
    }
    public uint? _last_played = null;
    public override uint last_played {
        get {
            common_uint_getter ("lastplayed", ref _last_played);
            return _last_played;
        }
        set {
            common_uint_setter ("lastplayed", value, ref _last_played);
        }
    }
    public uint? _last_modified = null;
    public override uint last_modified {
        get {
            common_uint_getter ("lastmodified", ref _last_modified);
            return _last_modified;
        }
        set {
            common_uint_setter ("lastmodified", value, ref _last_modified);
        }
    }

    public override int resume_pos { get; set; default = 0; }

    public LocalMedia (int rowid) {
        base ("");
        this.rowid = rowid;
        var query = query_field ("uri");
        if (query != null) {
            this.uri = query.dup_string ();
        }
    }

    /*
     * Common function for getters and setters
     */
    private uint64 common_uint64_getter (string field, ref uint64? temp) {
        if (temp != null)
            return temp;

        var query = query_field (field);
        if (query != null) {
            temp = (uint64)query.get_int64 ();
            return temp;
        } else
            return 0;
    }

    private void common_uint64_setter (string field, uint64 value, ref uint64? temp) {
        temp = value;
        var val = GLib.Value (typeof (uint64));
        val.set_uint64 (value);
        set_field.begin (field, val);
    }

    private uint common_uint_getter (string field, ref uint? temp) {
        if (temp != null)
            return temp;

        var query = query_field (field);
        if (query != null) {
            temp = (uint)query.get_int64 ();
            return temp;
        } else
            return 0;
    }

    private void common_uint_setter (string field, uint value, ref uint? temp) {
        temp = value;
        var val = GLib.Value (typeof (uint));
        val.set_uint (value);
        set_field.begin (field, val);
    }

    private string common_string_getter (string field, ref string? temp) {
        if (temp != null)
            return temp;

        var query = query_field (field);
        if (query != null) {
            temp = query.dup_string ();
            return _composer;
        } else
            return UNKNOWN;
    }

    private void common_string_setter (string field, string value, ref string? temp) {
        temp = value;
        var val = GLib.Value (typeof (string));
        val.set_string (value);
        set_field.begin (field, val);
    }

    /*
     * These functions allows the LocalMedia to interact with the database.
     */

    private GLib.Value? query_field (string field) {
        assert (database != null);
        try {
            var query = new SQLHeavy.Query (database, "SELECT `%s` FROM `media` WHERE rowid=:rowid".printf (field));
            query.set_int (":rowid", rowid);
            var result = query.execute ();
            var val = result.fetch ();
            if (val.type () != typeof (void*))
                return val;
            else
                return null;
        } catch (SQLHeavy.Error err) {
            warning ("Could not query field %s: %s", field, err.message);
            return null;
        }
    }

    private async void set_field (string field, GLib.Value value) {
        assert (database != null);
        try {
            var query = new SQLHeavy.Query (database, "UPDATE `media` SET %s=:value WHERE rowid=:rowid".printf (field));
            query.set_int (":rowid", rowid);
            var type = value.type ();
            if (type == typeof (string)) {
                query.set_string (":value", value.get_string ());
            } else if (type == typeof (int)) {
                query.set_int (":value", value.get_int ());
            } else if (type == typeof (uint)) {
                query.set_int (":value", (int)value.get_uint ());
            } else if (type == typeof (uint64)) {
                query.set_int64 (":value", (int64)value.get_uint64 ());
            } else if (type == typeof (bool)) {
                query.set_int (":value", value.get_boolean () ? 1 : 0);
            } else {
                return;
            }

            query.execute ();
        } catch (SQLHeavy.Error err) {
            warning ("Could not query field %s: %s", field, err.message);
        }
    }
}
