/*-
 * Copyright (c) 2011-2012 BeatBox developers
 *
 * Originally Written by Scott Ringwelski and Victor Eduardo for
 * BeatBox Music Player: http://www.launchpad.net/beat-box
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
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 *              Lucas Baudin <xapantu@gmail.com>
 */


/**
 * A place to store icon information and pixbufs.
 */

namespace Icons {

    public enum Type {
        MIMETYPE,
        ACTION,
        STATUS,
        APP,
        OTHER
    }

    public enum FileType {
        SVG,
        PNG
    }

    private const string MIMETYPES_FOLDER = "mimetypes";
    private const string ACTIONS_FOLDER = "actions";
    private const string STATUS_FOLDER = "status";
    private const string APPS_FOLDER = "apps";
    private const string OTHER_FOLDER = "other";

    private const string PNG_EXT = ".png";
    private const string SVG_EXT = ".svg";

    /**
     * Size of the cover art used in the album view
     **/
    public const int ALBUM_VIEW_IMAGE_SIZE = 168;

    /**
     * ICON INFORMATION
     * Use render() or render_image() to load these icons
    **/

    // 128 x 128
    public BeatBox.Icon DEFAULT_ALBUM_ART;
    public BeatBox.Icon MUSIC_FOLDER;

    // 22 x 22
    public BeatBox.Icon HISTORY;

    // 16 x 16
    public BeatBox.Icon BEATBOX;
    public BeatBox.Icon MUSIC;
    public BeatBox.Icon AUDIO_CD;
    public BeatBox.Icon AUDIO_DEVICE;
    public BeatBox.Icon NETWORK_DEVICE;
    public BeatBox.Icon PLAYLIST;
    public BeatBox.Icon SMART_PLAYLIST;


    public BeatBox.Icon STARRED;
    public BeatBox.Icon NOT_STARRED;

    // SYMBOLIC ICONS
    public BeatBox.Icon PANE_HIDE_SYMBOLIC;
    public BeatBox.Icon PANE_SHOW_SYMBOLIC;

    public BeatBox.Icon EQ_SYMBOLIC;

    public BeatBox.Icon EJECT_SYMBOLIC;

    public BeatBox.Icon NOW_PLAYING_SYMBOLIC;

    public BeatBox.Icon STARRED_SYMBOLIC;
    public BeatBox.Icon NOT_STARRED_SYMBOLIC;

    public BeatBox.Icon PROCESS_COMPLETED;
    public BeatBox.Icon PROCESS_ERROR;
    public BeatBox.Icon PROCESS_STOP;

    public BeatBox.Icon SHUFFLE_ON;
    public BeatBox.Icon SHUFFLE_OFF;
    public BeatBox.Icon REPEAT_ON;
    public BeatBox.Icon REPEAT_ONE;
    public BeatBox.Icon REPEAT_OFF;

    public BeatBox.Icon VIEW_COLUMN;
    public BeatBox.Icon VIEW_DETAILS;
    public BeatBox.Icon VIEW_ICONS;
    public BeatBox.Icon VIEW_VIDEO;

    /**
     * RENDERED ICONS.
     * These are pre-rendered pixbufs. Any static image which otherwise would need
     * to be rendered many times should be a preloaded pixbuf. They are loaded
     * in the init() function.
     */
    public Gdk.Pixbuf DEFAULT_ALBUM_ART_PIXBUF;
    public Gdk.Pixbuf DEFAULT_ALBUM_SHADOW_PIXBUF;


    public Gdk.Pixbuf? render_icon (string icon_name, Gtk.IconSize size, Gtk.StyleContext? context = null) {
        var icon = new BeatBox.Icon (icon_name);
        return icon.render (size, context);
    }

    public Gtk.Image? render_image (string icon_name, Gtk.IconSize size) {
        var icon = new BeatBox.Icon (icon_name);
        return icon.render_image (size);
    }

    /**
     * Loads icon information and renders [preloaded] pixbufs
     **/
    public void init () {

        // 128 x 128
        DEFAULT_ALBUM_ART = new BeatBox.Icon ("albumart", 138, Type.MIMETYPE, null, true);
        MUSIC_FOLDER = new BeatBox.Icon ("folder-music", 128, Type.MIMETYPE, null, true);

        // 22 x 22
        HISTORY = new BeatBox.Icon ("document-open-recent");

        // 16 x 16
        BEATBOX = new BeatBox.Icon ("noise", 16, Type.APP, null, true);
        MUSIC = new BeatBox.Icon ("library-music", 16, Type.MIMETYPE, null, true);
        AUDIO_CD = new BeatBox.Icon ("media-cdrom-audio", 16, Type.MIMETYPE, null, true);
        AUDIO_DEVICE = new BeatBox.Icon ("multimedia-player", 16, Type.MIMETYPE, null, true);
        NETWORK_DEVICE = new BeatBox.Icon ("monitor", 16, Type.MIMETYPE, null, true);
        PLAYLIST = new BeatBox.Icon ("playlist", 16, Type.MIMETYPE, null, true);
        SMART_PLAYLIST = new BeatBox.Icon ("playlist-automatic", 16, Type.MIMETYPE, null, true);
        STARRED = new BeatBox.Icon ("starred", 16, Type.STATUS, null, true);
        NOT_STARRED = new BeatBox.Icon ("non-starred", 16, Type.STATUS, null, true);

        // SYMBOLIC ICONS (16 x 16)
        PANE_SHOW_SYMBOLIC = new BeatBox.Icon ("pane-show-symbolic", 16, Type.ACTION, null, true);
        PANE_HIDE_SYMBOLIC = new BeatBox.Icon ("pane-hide-symbolic", 16, Type.ACTION, null, true);
        EQ_SYMBOLIC = new BeatBox.Icon ("media-eq-symbolic", 16, Type.ACTION, null, true);

        REPEAT_OFF = new BeatBox.Icon ("media-playlist-no-repeat-symbolic", 16, Type.STATUS, null, true);
        SHUFFLE_OFF = new BeatBox.Icon ("media-playlist-no-shuffle-symbolic", 16, Type.STATUS, null, true);

        NOW_PLAYING_SYMBOLIC = new BeatBox.Icon ("audio-volume-high-symbolic");

        EJECT_SYMBOLIC = new BeatBox.Icon ("media-eject-symbolic");
        STARRED_SYMBOLIC = new BeatBox.Icon ("starred-symbolic");
        NOT_STARRED_SYMBOLIC = new BeatBox.Icon ("non-starred-symbolic");
        PROCESS_COMPLETED = new BeatBox.Icon ("process-completed-symbolic");
        PROCESS_ERROR = new BeatBox.Icon ("process-error-symbolic");
        PROCESS_STOP = new BeatBox.Icon ("process-stop-symbolic");
        SHUFFLE_ON = new BeatBox.Icon ("media-playlist-shuffle-symbolic");
        REPEAT_ON = new BeatBox.Icon ("media-playlist-repeat-symbolic");
        REPEAT_ONE = new BeatBox.Icon ("media-playlist-repeat-one-symbolic");
        VIEW_COLUMN = new BeatBox.Icon ("view-column-symbolic");
        VIEW_DETAILS =new BeatBox.Icon ("view-list-symbolic");
        VIEW_ICONS = new BeatBox.Icon ("view-grid-symbolic");
        VIEW_VIDEO = new BeatBox.Icon ("view-video-symbolic");

        // Render Pixbufs ...

        DEFAULT_ALBUM_ART_PIXBUF = DEFAULT_ALBUM_ART.render (null);

        // 168x168
        var shadow_icon = new BeatBox.Icon ("albumart-shadow", 168, Type.OTHER, FileType.PNG, true);
        DEFAULT_ALBUM_SHADOW_PIXBUF = shadow_icon.render (null);
    }
}

