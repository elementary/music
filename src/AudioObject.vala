/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.AudioObject : Object {
    public string uri { get; construct; }
    public Gdk.Texture? texture { get; set; default = null; }
    public string artist { get; set; }
    public string title { get; set; }
    public int64 duration { get; set; default = 0; }
    public string art_url { get; private set; default = ""; }

    public AudioObject (string uri) {
        Object (uri: uri);
    }

    construct {
        notify["texture"].connect (() => {
            save_art_file.begin ();
        });
    }

    private async void save_art_file () throws Error requires (texture != null) {
        FileIOStream iostream;
        var file = yield File.new_tmp_async ("io.elementary.music-XXXXXX.png", GLib.Priority.DEFAULT, null, out iostream);

        var bytes = texture.save_to_png_bytes ();

        var ostream = iostream.output_stream;
        yield ostream.write_bytes_async (bytes);

        art_url = file.get_uri ();
    }
}
