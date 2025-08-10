/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.AudioObject : Object {
    public string uri { get; construct; }
    public Gdk.Texture? texture { get; set; default = null; }
    public string album { get; set; }
    public string artist { get; set; }
    public string title { get; set; }
    public int64 duration { get; set; default = 0; }
    public string art_url { get; set; default = ""; }

    public AudioObject (string uri) {
        Object (uri: uri);
    }

    public static bool equal_func (AudioObject a, AudioObject b) {
		return (a.uri == b.uri);
	}
}
