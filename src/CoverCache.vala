/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

[SingleInstance]
public class Music.CoverCache : Object {
    private HashTable<string, Gdk.Texture> loaded_covers;

    construct {
        loaded_covers = new HashTable<string, Gdk.Texture> (str_hash, str_equal);
    }

    public Gdk.Texture? get_cover (string album) {
        return loaded_covers.get (album);
    }

    public Gdk.Texture? add_cover (string album, Gdk.Pixbuf pix) {
        Gdk.Texture cover = Gdk.Texture.for_pixbuf (pix);
        loaded_covers.insert (album, cover);
        return cover;
    }
}
