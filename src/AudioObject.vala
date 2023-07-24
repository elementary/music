/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.AudioObject : Object {
    public string uri { get; set; }
    public Gdk.Texture texture { get; set; }
    public string artist { get; set; }
    public string title { get; set; }
    public int64 duration { get; set; default = 0; }

    public AudioObject.from_file (File file) {
        uri = file.get_uri ();

        string? basename = file.get_basename ();

        if (basename != null) {
            title = basename;
        } else {
            title = uri;
        }
    }
}
