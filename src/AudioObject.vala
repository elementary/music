/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.AudioObject : Object {
    public int64 playback_duration { get; construct; }
    public string artist { get; construct; }
    public string title { get; construct; }

    public AudioObject (string artist, string title, int64 playback_duration) {
        Object (
            artist: artist,
            title: title,
            playback_duration: playback_duration
        );
    }
}
