/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 elementary, Inc. (https://elementary.io)
 */

public class Music.PlaylistObject : Object {
    public File playlist_file { get; construct; }
    private File[] uri_list = {};

    public PlaylistObject () {}


    public PlaylistObject.with_file (File playlist) {
        Object(playlist_file: playlist);
    }

    construct {
        load_playlist (playlist_file);
    }

    public static bool is_playlist (File playlist) {
        FileInfo info;

        try {
            info = playlist.query_info (GLib.FileAttribute.STANDARD_CONTENT_TYPE, GLib.FileQueryInfoFlags.NONE);
        } catch (Error e) {
            warning (e.message);

            return false;
        }

        var mimetype = info.get_content_type ();
        if (mimetype == null) {
            warning ("Failed to get content type");

            return false;
        }

        return mimetype == "audio/x-mpegurl";
    }

    public File[]? get_uri_list () {
        return uri_list;
    }

    private void load_playlist (File playlist) {
        FileInputStream fis = playlist.read ();
        DataInputStream dis = new DataInputStream (fis);
        string current_line;

        while ((current_line = dis.read_line ()) != null) {
            if (current_line.ascii_down ().has_prefix ("file:///")) {
                uri_list += File.new_for_uri (current_line);
            }
            else if (FileUtils.test (current_line, FileTest.IS_DIR)) {
                uri_list += File.new_for_path (current_line);
            }
            else {
                debug ("Unknown line: " + current_line);
            }
        }
    }

    public void save_playlist (ListStore queue) {
        FileOutputStream fos = playlist_file.replace (null, false, GLib.FileCreateFlags.REPLACE_DESTINATION);
        DataOutputStream dos = new DataOutputStream (fos);

        for (uint i = 0; i < queue.n_items; i++) {
            AudioObject track = (AudioObject)queue.get_item (i);
            dos.put_string (track.uri);
            dos.put_string ("\n");
        }
    }
}
