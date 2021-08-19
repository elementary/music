/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.AudioObject : Object {
    public File file { get; construct; }
    public Gdk.Pixbuf pixbuf { get; set; }
    public string artist { get; set; }
    public string title { get; set; }

    public AudioObject (File file) {
        Object (file: file);
    }
}
