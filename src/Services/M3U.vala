/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

namespace Music.M3U {

    // Standard specification here: https://en.wikipedia.org/wiki/M3U
    public File[] parse_playlist (File playlist) {
        debug ("Parsing playlist: " + playlist.get_basename () + "\n");
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

    public void save_playlist (MainWindow parent, ListStore queue_liststore) {
        debug ("Saving queue as playlist" + "\n");
        string content = "";

        for (var i = 0; i < queue_liststore.n_items; i++) {
            var item = (Music.AudioObject)queue_liststore.get_item (i);
            content = content + item.uri + "\n";
        }

        var save_dialog = new Gtk.FileDialog () {
            initial_name = _("New playlist.m3u")
        };

        save_dialog.save.begin (parent, null, (obj, res) => {
            try {
                var file = save_dialog.save.end (res);
                var dostream = new DataOutputStream (
                                             file.replace (
                                                           null,
                                                           false,
                                                           GLib.FileCreateFlags.REPLACE_DESTINATION
                                             )
                );

            dostream.put_string (content);

            } catch (Error err) {
                    warning ("Failed to save file: %s", err.message);
            }
        });


    }
}
