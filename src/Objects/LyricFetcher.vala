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

public class Noise.LyricFetcher : Object {

    public async string fetch_lyrics_async (Media m) {
        var source = new LyricsManiaFetcher ();
        return source.fetch_lyrics (m.title, m.album_artist, m.artist);
    }

}


/**
 * LYRIC SOURCES
 */

private class LyricsManiaFetcher : Object {
    private const string URL_FORMAT = "http://www.lyricsmania.com/%s_lyrics_%s.html";

    public string fetch_lyrics (string title, string album_artist, string artist) {
        var url = parse_url (artist, title);
        File page = File.new_for_uri (url);

        uint8[] uintcontent;
        string etag_out;
        bool load_successful = false;

        try {
            page.load_contents (null, out uintcontent, out etag_out);
            load_successful = true;
        } catch (Error err) {
            load_successful = false;
        }

        // Try again using album artist
        if (!load_successful && album_artist.length > 0) {
            try {
                url = parse_url (album_artist, title);
                page = File.new_for_uri (url);
                page.load_contents (null, out uintcontent, out etag_out);
                load_successful = true;
            } catch (Error err) {
                load_successful = false;
            }
        }

        return load_successful ? parse_lyrics (uintcontent) : "";
    }

    private string parse_url (string artist, string title) {
        return URL_FORMAT.printf (fix_string (title), fix_string (artist));
    }

    private string fix_string (string? str) {
        if (str == null)
            return "";

        var fixed_string = new StringBuilder ();
        unichar c;

        for (int i = 0; str.get_next_char (ref i, out c);) {
            c = c.tolower ();
            if ( ('a' <= c && c <= 'z') || ('0' <= c && c <= '9'))
                fixed_string.append_unichar (c);
            else if (' ' == c)
                fixed_string.append_unichar ('_');
            else if ('/' == c)
                fixed_string.append_unichar ('_');
            else if ('!' == c)
                fixed_string.append_unichar (c);
            else if (',' == c)
                fixed_string.append_unichar (c);
            else if ('à' == c)
                fixed_string.append_unichar ('a');
            else if ('ï' == c)
                fixed_string.append_unichar ('i');
            else if ('î' == c)
                fixed_string.append_unichar ('i');
            else if ('é' == c)
                fixed_string.append_unichar ('e');
            else if ('è' == c)
                fixed_string.append_unichar ('e');
            else if ('ê' == c)
                fixed_string.append_unichar ('e');
            else if ('ë' == c)
                fixed_string.append_unichar ('e');
            else if ('ù' == c)
                fixed_string.append_unichar ('u');
            else if ('ô' == c)
                fixed_string.append_unichar ('o');
            else if ('ö' == c)
                fixed_string.append_unichar ('o');
            else if ('-' == c)
                fixed_string.append_unichar (c);
        }
        return fixed_string.str;
    }

    private string parse_lyrics (uint8[] uintcontent) {
        string content = (string) uintcontent;
        string lyrics = "";
        var rv = new StringBuilder ();

        const string START_STRING = "</strong>\n									";
        const string END_STRING = "</div> <!-- lyrics-body -->";

        var start = content.index_of (START_STRING, 0) + START_STRING.length;
        var end = content.index_of (END_STRING, start);

        if (start != -1 && end != -1 && end > start)
            lyrics = content.substring (start, end - start);

        try {
            lyrics = new Regex ("<.*?>").replace (lyrics, -1, 0, "");
        } catch (RegexError err) {
            warning ("Could not parse lyrics: %s", err.message);
            return "";
        }
        
        if (!Noise.String.is_empty (lyrics.replace("\n", "").replace(" ", ""), true))
            lyrics = lyrics + "\n\n" + _("Lyrics fetched from www.lyricsmania.com");

        rv.append (lyrics);
        rv.append ("\n");

        return rv.str;
    }
}
