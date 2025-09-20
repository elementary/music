/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

namespace Music.M3U {
    public bool is_playlist (File suspicious_file) {
        bool if_playlist = false;
        try {
            var info = suspicious_file.query_info (GLib.FileAttribute.STANDARD_CONTENT_TYPE, FileQueryInfoFlags.NONE);
            var mimetype = info.get_content_type () ?? "";
            if_playlist = mimetype == "audio/x-mpegurl";

        } catch (Error e) {
            warning (e.message);
        }

        return if_playlist;
    }

    // Standard specification here: https://en.wikipedia.org/wiki/M3U
    public File[]? parse_playlist (File playlist) throws Error {
        debug ("Parsing playlist: %s", playlist.get_path ());
        File[] list = {};

        FileInputStream @is = playlist.read ();
        DataInputStream dis = new DataInputStream (@is);
        string line;

        while ((line = dis.read_line ()) != null) {
            // Skip extended
            if (line.has_prefix ("#EXT")) {
                debug ("Skipping EXTM3U: " + line);
                continue;
            }

            // Skip URL
            if (line.ascii_down ().has_prefix ("http")) {
                debug ("Skipping URL: " + line);
                continue;
            }

            File target;

            if (line.ascii_down ().has_prefix ("file:///")) {
                target = File.new_for_uri (line);
            } else {
                target = File.new_for_path (line);
            }

            // The caller is responsible for testing whether files exist and
            // are valid using PlaybackManager.queue_files() instead of here
            list += target;
        }

        return list;
    }

    public void save_playlist (ListStore queue_liststore, File playlist) throws Error {
        debug ("Saving queue as playlist");
        string content = "";

        for (var i = 0; i < queue_liststore.n_items; i++) {
            var item = (Music.AudioObject)queue_liststore.get_item (i);
            content = content + item.uri + "\n";
        }

        var ostream = playlist.replace (null, false, GLib.FileCreateFlags.REPLACE_DESTINATION);
        var dostream = new DataOutputStream (ostream);
        dostream.put_string (content);
    }
}
