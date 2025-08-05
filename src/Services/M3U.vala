/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

namespace Music.M3U {

    // Standard specification here: https://en.wikipedia.org/wiki/M3U
    public File[] parse_playlist (File playlist) {
        debug ("Parsing playlist: %s", playlist.get_path ());
        File[] list = {};

        try {
            FileInputStream @is = playlist.read ();
            DataInputStream dis = new DataInputStream (@is);
            string line;

            while ((line = dis.read_line ()) != null) {
                print ("%s\n", line);

                // Skip extended 
                if (line.has_prefix ("#EXT")) {
                    print ("Skipping EXTM3U: " + line + "\n");

                } else {
                    File target;

                    if (line.ascii_down ().has_prefix ("file:///")) {
                        target = File.new_for_uri (line);

                    //FIXME: URL get skipped.
                    //} else if (line.ascii_down ().has_prefix ("http")) {
                    //    print ("URL are currently unsupported:" + line + "\n");

                    } else {
                        target = File.new_for_path (line);

                    };

                    // We do not need to test yet whether files exist
                    list += target;
                }
            }

        } catch (Error e) {
            print ("Error: %s\n", e.message);
        }

        return list;

    }

    public void save_playlist (ListStore queue_liststore, File playlist) {
        debug ("Saving queue as playlist" + "\n");
        string content = "";

        for (var i = 0; i < queue_liststore.n_items; i++) {
            var item = (Music.AudioObject)queue_liststore.get_item (i);
            content = content + item.uri + "\n";
        }

        try {
            var ostream = playlist.replace (null, false, GLib.FileCreateFlags.REPLACE_DESTINATION);
            var dostream = new DataOutputStream (ostream);

            dostream.put_string (content);

        } catch (Error err) {
            warning ("Failed to save file: %s", err.message);
        }
    }
}
