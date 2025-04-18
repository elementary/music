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
            save_art_file.begin ((obj, res) => {
                try {
                    save_art_file.end (res);
                } catch (Error e) {
                    critical (e.message);
                }
            });
        });
    }

    private async void save_art_file () throws Error requires (texture != null) {
        var path = Path.build_path (
            Path.DIR_SEPARATOR_S,
            Environment.get_user_cache_dir (),
            GLib.Application.get_default ().application_id,
            "art"
        );

        DirUtils.create_with_parents (path, 0755);

        //FIXME: make a hash that re-uses art instead of one per file
        var file = File.new_for_path (Path.build_path (
            Path.DIR_SEPARATOR_S,
            path,
            Checksum.compute_for_string (SHA256, uri)
        ));

        var ostream = yield file.create_async (NONE);
        yield ostream.write_bytes_async (texture.save_to_png_bytes ());

        art_url = file.get_uri ();
    }
}
