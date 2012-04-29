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
	public BeatBox.Icon PLAYLIST;
	public BeatBox.Icon SMART_PLAYLIST;

	public BeatBox.Icon LASTFM_LOVE;
	public BeatBox.Icon LASTFM_BAN;

	public BeatBox.Icon STARRED;
	public BeatBox.Icon NOT_STARRED;

	// SYMBOLIC ICONS
	public BeatBox.Icon PANE_HIDE_SYMBOLIC;
	public BeatBox.Icon PANE_SHOW_SYMBOLIC;

	public BeatBox.Icon EQ_SYMBOLIC;

	public BeatBox.Icon NOW_PLAYING_SYMBOLIC;

	public BeatBox.Icon STARRED_SYMBOLIC;
	public BeatBox.Icon NOT_STARRED_SYMBOLIC;

	public BeatBox.Icon PROCESS_COMPLETED;
	public BeatBox.Icon PROCESS_ERROR;
	public BeatBox.Icon PROCESS_STOP;

	public BeatBox.Icon SHUFFLE_ON;
	public BeatBox.Icon SHUFFLE_OFF;
	public BeatBox.Icon REPEAT_ON;
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

	/**
	 * @param pixbuf original image
	 * @param stretch whether to strech the image inside the square or keep the original dimensions
	 * @return original pixbuf + drop shadow
	 **/
	public Gdk.Pixbuf get_pixbuf_shadow (Gdk.Pixbuf pixbuf, bool stretch = true)
	{
		const int SURFACE_SIZE = ALBUM_VIEW_IMAGE_SIZE;
		const int SHADOW_SIZE = 15;

		int S_WIDTH = (stretch)? SURFACE_SIZE: pixbuf.width;
		int S_HEIGHT = (stretch)? SURFACE_SIZE : pixbuf.height;

		var buffer_surface = new Granite.Drawing.BufferSurface (S_WIDTH, S_HEIGHT);

		// paint shadow
		buffer_surface.context.rectangle (0, 0, S_WIDTH, S_HEIGHT);

		if (stretch)
			Gdk.cairo_set_source_pixbuf (buffer_surface.context, DEFAULT_ALBUM_SHADOW_PIXBUF.scale_simple (S_WIDTH, S_HEIGHT, Gdk.InterpType.BILINEAR), 0, 0);
		else
			Gdk.cairo_set_source_pixbuf (buffer_surface.context, DEFAULT_ALBUM_SHADOW_PIXBUF, 0, 0);

		buffer_surface.context.paint();

		S_WIDTH -= 2 * SHADOW_SIZE;
		S_HEIGHT -= 2 * SHADOW_SIZE;

		// paint original pixbuf
		var source_pixbuf = pixbuf;
		if (pixbuf.width != S_WIDTH || pixbuf.height != S_HEIGHT)
			source_pixbuf = pixbuf.scale_simple (S_WIDTH, S_HEIGHT, Gdk.InterpType.BILINEAR);

		Gdk.cairo_set_source_pixbuf (buffer_surface.context, source_pixbuf,
		                            SHADOW_SIZE, SHADOW_SIZE - 2); // 2px vertical offset
		buffer_surface.context.paint();

		return buffer_surface.load_to_pixbuf();
	}

	/**
	 * @param surface_size size of the new pixbuf. Set a value of 0 to use the pixbuf's default size.
	 **/
	public Gdk.Pixbuf render_pixbuf_shadow (Gdk.Pixbuf pixbuf, int surface_size = ALBUM_VIEW_IMAGE_SIZE,
	                                         int shadow_size = 5, double alpha = 0.75)
	{
		int S_WIDTH = (surface_size > 0)? surface_size : pixbuf.width;
		int S_HEIGHT = (surface_size > 0)? surface_size : pixbuf.height;

		var buffer_surface = new Granite.Drawing.BufferSurface (S_WIDTH, S_HEIGHT);

		S_WIDTH -= 2 * shadow_size;
		S_HEIGHT -= 2 * shadow_size;

		buffer_surface.context.rectangle (shadow_size, shadow_size, S_WIDTH, S_HEIGHT);
		buffer_surface.context.set_source_rgba (0, 0, 0, alpha);
		buffer_surface.context.fill();

		buffer_surface.fast_blur(2, 3);

		Gdk.cairo_set_source_pixbuf (buffer_surface.context, pixbuf.scale_simple (S_WIDTH, S_HEIGHT,
		                             Gdk.InterpType.BILINEAR), shadow_size, shadow_size);
		buffer_surface.context.paint();

		return buffer_surface.load_to_pixbuf();
	}


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
		PLAYLIST = new BeatBox.Icon ("playlist", 16, Type.MIMETYPE, null, true);
		SMART_PLAYLIST = new BeatBox.Icon ("playlist-automatic", 16, Type.MIMETYPE, null, true);
		LASTFM_LOVE = new BeatBox.Icon ("lastfm-love", 16, Type.ACTION, null, true);
		LASTFM_BAN = new BeatBox.Icon ("lastfm-ban", 16, Type.ACTION, null, true);
		STARRED = new BeatBox.Icon ("starred", 16, Type.STATUS, null, true);
		NOT_STARRED = new BeatBox.Icon ("non-starred", 16, Type.STATUS, null, true);

		// SYMBOLIC ICONS (16 x 16)
		PANE_SHOW_SYMBOLIC = new BeatBox.Icon ("pane-show-symbolic", 16, Type.ACTION, null, true);
		PANE_HIDE_SYMBOLIC = new BeatBox.Icon ("pane-hide-symbolic", 16, Type.ACTION, null, true);
		EQ_SYMBOLIC = new BeatBox.Icon ("media-eq-symbolic", 16, Type.ACTION, null, true);

		REPEAT_OFF = new BeatBox.Icon ("media-playlist-no-repeat-symbolic", 16, Type.STATUS, null, true);
		SHUFFLE_OFF = new BeatBox.Icon ("media-playlist-no-shuffle-symbolic", 16, Type.STATUS, null, true);

		NOW_PLAYING_SYMBOLIC = new BeatBox.Icon ("audio-volume-high-symbolic");
		STARRED_SYMBOLIC = new BeatBox.Icon ("starred-symbolic");
		NOT_STARRED_SYMBOLIC = new BeatBox.Icon ("non-starred-symbolic");
		PROCESS_COMPLETED = new BeatBox.Icon ("process-completed-symbolic");
		PROCESS_ERROR = new BeatBox.Icon ("process-error-symbolic");
		PROCESS_STOP = new BeatBox.Icon ("process-stop-symbolic");
		SHUFFLE_ON = new BeatBox.Icon ("media-playlist-shuffle-symbolic");
		REPEAT_ON = new BeatBox.Icon ("media-playlist-repeat-symbolic");
		VIEW_COLUMN = new BeatBox.Icon ("view-list-column-symbolic");
		VIEW_DETAILS =new BeatBox.Icon ("view-list-details-symbolic");
		VIEW_ICONS = new BeatBox.Icon ("view-list-icons-symbolic");
		VIEW_VIDEO = new BeatBox.Icon ("view-list-video-symbolic");

		// Render Pixbufs ...

		DEFAULT_ALBUM_ART_PIXBUF = DEFAULT_ALBUM_ART.render (null);

		// 168x168
		var shadow_icon = new BeatBox.Icon ("albumart-shadow", 168, Type.OTHER, FileType.PNG, true);
		DEFAULT_ALBUM_SHADOW_PIXBUF = shadow_icon.render (null);
	}
}

