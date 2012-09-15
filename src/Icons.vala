// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
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
 * and  This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

/**
 * A place to store icon information and pixbufs.
 */

namespace Noise.Icons {

    private bool is_initted = false;

    /**
     * Size of the cover art used in the album view
     **/
    public const int ALBUM_VIEW_IMAGE_SIZE = 168;
    public const int DEFAULT_ALBUM_ART_SIZE = 138;

    /**
     * RENDERED ICONS.
     * These are pre-rendered pixbufs. Any static image which otherwise would need
     * to be rendered many times should be a preloaded pixbuf. They are loaded
     * in the init() function.
     */
    public Gdk.Pixbuf DEFAULT_ALBUM_SHADOW_PIXBUF;


    /**
     * ICON INFORMATION
     * Use render() or render_image() to load these icons
    **/

    // 128 x 128
    public Icon DEFAULT_ALBUM_ART;
    public Icon MUSIC_FOLDER;

    // 22 x 22
    public Icon HISTORY;

    // 16 x 16
    public Icon NOISE;
    public Icon MUSIC;
    public Icon AUDIO_CD;
    public Icon AUDIO_DEVICE;
    public Icon NETWORK_DEVICE;
    public Icon PLAYLIST;
    public Icon SMART_PLAYLIST;


    public Icon STARRED;
    public Icon NOT_STARRED;

    // SYMBOLIC ICONS
    public Icon PANE_HIDE_SYMBOLIC;
    public Icon PANE_SHOW_SYMBOLIC;

    public Icon EQ_SYMBOLIC;

    public Icon EJECT_SYMBOLIC;

    public Icon NOW_PLAYING_SYMBOLIC;

    public Icon STARRED_SYMBOLIC;
    public Icon NOT_STARRED_SYMBOLIC;

    public Icon PROCESS_COMPLETED;
    public Icon PROCESS_ERROR;
    public Icon PROCESS_STOP;

    public Icon SHUFFLE_ON;
    public Icon SHUFFLE_OFF;
    public Icon REPEAT_ON;
    public Icon REPEAT_ONE;
    public Icon REPEAT_OFF;

    public Icon VIEW_COLUMN;
    public Icon VIEW_DETAILS;
    public Icon VIEW_ICONS;
    public Icon VIEW_VIDEO;


    public Gdk.Pixbuf? render_icon (string icon_name, Gtk.IconSize size, Gtk.StyleContext? context = null) {
        var icon = new Icon (icon_name);
        return icon.render (size, context);
    }

    public Gtk.Image? render_image (string icon_name, Gtk.IconSize size) {
        var icon = new Icon (icon_name);
        return icon.render_image (size);
    }

    /**
     * Loads icon information and renders [preloaded] pixbufs
     **/
    public void init () {
        assert (!is_initted);
        is_initted = true;

        // 128 x 128
        DEFAULT_ALBUM_ART = new Icon ("albumart");
        MUSIC_FOLDER = new Icon ("folder-music");

        // 22 x 22
        HISTORY = new Icon ("document-open-recent");

        // 16 x 16
        NOISE = new Icon ("noise");
        MUSIC = new Icon ("library-music");
        AUDIO_CD = new Icon ("media-cdrom-audio");
        AUDIO_DEVICE = new Icon ("multimedia-player");
        NETWORK_DEVICE = new Icon ("monitor");
        PLAYLIST = new Icon ("playlist");
        SMART_PLAYLIST = new Icon ("playlist-automatic");
        STARRED = new Icon ("starred");
        NOT_STARRED = new Icon ("non-starred");

        // SYMBOLIC ICONS (16 x 16)
        PANE_SHOW_SYMBOLIC = new Icon ("pane-show-symbolic");
        PANE_HIDE_SYMBOLIC = new Icon ("pane-hide-symbolic");
        EQ_SYMBOLIC = new Icon ("media-eq-symbolic");

        REPEAT_OFF = new Icon ("media-playlist-no-repeat-symbolic");
        SHUFFLE_OFF = new Icon ("media-playlist-no-shuffle-symbolic");

        NOW_PLAYING_SYMBOLIC = new Icon ("audio-volume-high-symbolic");

        EJECT_SYMBOLIC = new Icon ("media-eject-symbolic");
        STARRED_SYMBOLIC = new Icon ("starred-symbolic");
        NOT_STARRED_SYMBOLIC = new Icon ("non-starred-symbolic");
        PROCESS_COMPLETED = new Icon ("process-completed-symbolic");
        PROCESS_ERROR = new Icon ("process-error-symbolic");
        PROCESS_STOP = new Icon ("process-stop-symbolic");
        SHUFFLE_ON = new Icon ("media-playlist-shuffle-symbolic");
        REPEAT_ON = new Icon ("media-playlist-repeat-symbolic");
        REPEAT_ONE = new Icon ("media-playlist-repeat-one-symbolic");
        VIEW_COLUMN = new Icon ("view-column-symbolic");
        VIEW_DETAILS = new Icon ("view-list-symbolic");
        VIEW_ICONS = new Icon ("view-grid-symbolic");
        VIEW_VIDEO = new Icon ("view-video-symbolic");

        // Render Pixbufs ...

        // 168x168
        var shadow_icon = new Icon ("albumart-shadow");
        DEFAULT_ALBUM_SHADOW_PIXBUF = shadow_icon.render_at_size (168);
    }

    public bool get_is_initted () {
        return is_initted;
    }
}
