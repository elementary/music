// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2013 Noise Developers (http://launchpad.net/noise)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Cody Garver <codygarver@gmail.com>
 *              Corentin Noël <tintou@mailoo.org>
 */

namespace Noise {

    /**
     * Supported audio types.
     *
     * We only support these even though gstreamer
     */
    public const string[] MEDIA_CONTENT_TYPES = {
        "audio/3gpp",
        "audio/aac",
        "audio/AMR",
        "audio/AMR-WB",
        "audio/ac3",
        "audio/basic",
        "audio/flac",
        "audio/mp2",
        "audio/mpeg",
        "audio/mp4",
        "audio/ogg",
        "audio/vnd.rn-realaudio",
        "audio/vorbis",
        "audio/x-aac",
        "audio/x-aiff",
        "audio/x-ape",
        "audio/x-flac",
        "audio/x-gsm",
        "audio/x-it",
        "audio/x-m4a",
        "audio/x-matroska",
        "audio/x-mod",
        "audio/x-ms-asf",
        "audio/x-ms-wma",
        "audio/x-mp3",
        "audio/x-mpeg",
        "audio/x-musepack",
        "audio/x-pn-aiff",
        "audio/x-pn-au",
        "audio/x-pn-realaudio",
        "audio/x-pn-realaudio-plugin",
        "audio/x-pn-wav",
        "audio/x-pn-windows-acm",
        "audio/x-realaudio",
        "audio/x-real-audio",
        "audio/x-sbc",
        "audio/x-speex",
        "audio/x-tta",
        "audio/x-vorbis",
        "audio/x-vorbis+ogg",
        "audio/x-wav",
        "audio/x-wavpack",
        "audio/x-xm",
        "application/ogg",
        "application/x-extension-m4a",
        "application/x-extension-mp4",
        "application/x-flac",
        "application/x-ogg"
    };

    //TODO: Support "audio/x-ms-asx" and "audio/x-ms-wax"
    public const string[] PLAYLISTS_CONTENT_TYPES = {
        "audio/x-mpegurl",
        "audio/x-scpls"
    };

    public const string MUSIC_PLAYLIST = "autosaved_music";
    public const string STRING_CANCEL = _("Cancel");
    public const string STRING_OPEN = _("Open");
    public const string STRING_SAVE = _("Save");

    public LibrariesManager libraries_manager;
}