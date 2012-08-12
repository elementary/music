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
 * and Noise. This permission is above and beyond the permissions granted
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

namespace Icons {

    private bool is_initted = false;

    /**
     * Size of the cover art used in the album view
     **/
    public const int ALBUM_VIEW_IMAGE_SIZE = 168;

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
    public Noise.Icon DEFAULT_ALBUM_ART;
    public Noise.Icon MUSIC_FOLDER;

    // 22 x 22
    public Noise.Icon HISTORY;

    // 16 x 16
    public Noise.Icon NOISE;
    public Noise.Icon MUSIC;
    public Noise.Icon AUDIO_CD;
    public Noise.Icon AUDIO_DEVICE;
    public Noise.Icon NETWORK_DEVICE;
    public Noise.Icon PLAYLIST;
    public Noise.Icon SMART_PLAYLIST;


    public Noise.Icon STARRED;
    public Noise.Icon NOT_STARRED;

    // SYMBOLIC ICONS
    public Noise.Icon PANE_HIDE_SYMBOLIC;
    public Noise.Icon PANE_SHOW_SYMBOLIC;

    public Noise.Icon EQ_SYMBOLIC;

    public Noise.Icon EJECT_SYMBOLIC;

    public Noise.Icon NOW_PLAYING_SYMBOLIC;

    public Noise.Icon STARRED_SYMBOLIC;
    public Noise.Icon NOT_STARRED_SYMBOLIC;

    public Noise.Icon PROCESS_COMPLETED;
    public Noise.Icon PROCESS_ERROR;
    public Noise.Icon PROCESS_STOP;

    public Noise.Icon SHUFFLE_ON;
    public Noise.Icon SHUFFLE_OFF;
    public Noise.Icon REPEAT_ON;
    public Noise.Icon REPEAT_ONE;
    public Noise.Icon REPEAT_OFF;

    public Noise.Icon VIEW_COLUMN;
    public Noise.Icon VIEW_DETAILS;
    public Noise.Icon VIEW_ICONS;
    public Noise.Icon VIEW_VIDEO;


    public Gdk.Pixbuf? render_icon (string icon_name, Gtk.IconSize size, Gtk.StyleContext? context = null) {
        var icon = new Noise.Icon (icon_name);
        return icon.render (size, context);
    }

    public Gtk.Image? render_image (string icon_name, Gtk.IconSize size) {
        var icon = new Noise.Icon (icon_name);
        return icon.render_image (size);
    }

    /**
     * Loads icon information and renders [preloaded] pixbufs
     **/
    public void init () {
        assert (!is_initted);
        is_initted = true;

        // 128 x 128
        DEFAULT_ALBUM_ART = new Noise.Icon ("albumart", 138, Noise.Icon.Category.MIMETYPE, null, true);
        MUSIC_FOLDER = new Noise.Icon ("folder-music", 128, Noise.Icon.Category.MIMETYPE, null, true);

        // 22 x 22
        HISTORY = new Noise.Icon ("document-open-recent");

        // 16 x 16
        NOISE = new Noise.Icon ("noise", 16, Noise.Icon.Category.APP, null, true);
        MUSIC = new Noise.Icon ("library-music", 16, Noise.Icon.Category.MIMETYPE, null, true);
        AUDIO_CD = new Noise.Icon ("media-cdrom-audio", 16, Noise.Icon.Category.MIMETYPE, null, true);
        AUDIO_DEVICE = new Noise.Icon ("multimedia-player", 16, Noise.Icon.Category.MIMETYPE, null, true);
        NETWORK_DEVICE = new Noise.Icon ("monitor", 16, Noise.Icon.Category.MIMETYPE, null, true);
        PLAYLIST = new Noise.Icon ("playlist", 16, Noise.Icon.Category.MIMETYPE, null, true);
        SMART_PLAYLIST = new Noise.Icon ("playlist-automatic", 16, Noise.Icon.Category.MIMETYPE, null, true);
        STARRED = new Noise.Icon ("starred", 16, Noise.Icon.Category.STATUS, null, true);
        NOT_STARRED = new Noise.Icon ("non-starred", 16, Noise.Icon.Category.STATUS, null, true);

        // SYMBOLIC ICONS (16 x 16)
        PANE_SHOW_SYMBOLIC = new Noise.Icon ("pane-show-symbolic", 16, Noise.Icon.Category.ACTION, null, true);
        PANE_HIDE_SYMBOLIC = new Noise.Icon ("pane-hide-symbolic", 16, Noise.Icon.Category.ACTION, null, true);
        EQ_SYMBOLIC = new Noise.Icon ("media-eq-symbolic", 16, Noise.Icon.Category.ACTION, null, true);

        REPEAT_OFF = new Noise.Icon ("media-playlist-no-repeat-symbolic", 16, Noise.Icon.Category.STATUS, null, true);
        SHUFFLE_OFF = new Noise.Icon ("media-playlist-no-shuffle-symbolic", 16, Noise.Icon.Category.STATUS, null, true);

        NOW_PLAYING_SYMBOLIC = new Noise.Icon ("audio-volume-high-symbolic");

        EJECT_SYMBOLIC = new Noise.Icon ("media-eject-symbolic");
        STARRED_SYMBOLIC = new Noise.Icon ("starred-symbolic");
        NOT_STARRED_SYMBOLIC = new Noise.Icon ("non-starred-symbolic");
        PROCESS_COMPLETED = new Noise.Icon ("process-completed-symbolic");
        PROCESS_ERROR = new Noise.Icon ("process-error-symbolic");
        PROCESS_STOP = new Noise.Icon ("process-stop-symbolic");
        SHUFFLE_ON = new Noise.Icon ("media-playlist-shuffle-symbolic");
        REPEAT_ON = new Noise.Icon ("media-playlist-repeat-symbolic");
        REPEAT_ONE = new Noise.Icon ("media-playlist-repeat-one-symbolic");
        VIEW_COLUMN = new Noise.Icon ("view-column-symbolic");
        VIEW_DETAILS = new Noise.Icon ("view-list-symbolic");
        VIEW_ICONS = new Noise.Icon ("view-grid-symbolic");
        VIEW_VIDEO = new Noise.Icon ("view-video-symbolic");

        // Render Pixbufs ...

        // 168x168
        var shadow_icon = new Noise.Icon ("albumart-shadow", 168, Noise.Icon.Category.OTHER, Noise.Icon.FileType.PNG, true);
        DEFAULT_ALBUM_SHADOW_PIXBUF = shadow_icon.render (null);
    }

    public bool get_is_initted () {
        return is_initted;
    }
}
