/*-
 * Copyright (c) 2011		Scott Ringwelski <sgringwe@mtu.edu>
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
 */

namespace Icons {

	public enum IconType {
		MIMETYPE,
		ACTION,
		STATUS,
		APP
	}

	public enum IconFileType {
		SVG,
		PNG
	}

	public const string MIMETYPES_FOLDER = "mimetypes";
	public const string ACTIONS_FOLDER = "actions";
	public const string STATUS_FOLDER = "status";
	public const string APPS_FOLDER = "apps";

	public const string PNG_EXT = ".png";
	public const string SVG_EXT = ".svg";

	// 128 x 128
	public BeatBox.Icon DEFAULT_ALBUM_ART;
	public BeatBox.Icon DROP_ALBUM;
	public BeatBox.Icon MUSIC_FOLDER;

	// 22 x 22
	public BeatBox.Icon HISTORY_ICON;

	// 16 x 16
	public BeatBox.Icon BEATBOX_ICON;
	public BeatBox.Icon RADIO_ICON;
	public BeatBox.Icon MUSIC_ICON;
	public BeatBox.Icon PODCAST_ICON;
	public BeatBox.Icon AUDIOBOOK_ICON;
	public BeatBox.Icon AUDIO_CD_ICON;
	public BeatBox.Icon PLAYLIST_ICON;
	public BeatBox.Icon SMART_PLAYLIST_ICON;
	public BeatBox.Icon LASTFM_LOVE_ICON;
	public BeatBox.Icon LASTFM_BAN_ICON;
	public BeatBox.Icon STARRED_ICON;
	public BeatBox.Icon NOT_STARRED_ICON;
	public BeatBox.Icon INFO_ICON;
	public BeatBox.Icon NEW_PODCAST_ICON;

	// SYMBOLIC ICONS
	public BeatBox.Icon MEDIA_PLAY_SYMBOLIC;
	public BeatBox.Icon MEDIA_STOP_SYMBOLIC;
	public BeatBox.Icon STARRED_SYMBOLIC_ICON;
	public BeatBox.Icon NOT_STARRED_SYMBOLIC_ICON;
	public BeatBox.Icon PROCESS_COMPLETED_ICON;
	public BeatBox.Icon PROCESS_ERROR_ICON;
	public BeatBox.Icon NOW_PLAYING_ICON;
	public BeatBox.Icon PROCESS_STOP_ICON;
	public BeatBox.Icon SHUFFLE_ON_ICON;
	public BeatBox.Icon SHUFFLE_OFF_ICON;
	public BeatBox.Icon REPEAT_ON_ICON;
	public BeatBox.Icon REPEAT_ONCE_ICON;
	public BeatBox.Icon REPEAT_OFF_ICON;
	public BeatBox.Icon VIEW_COLUMN_ICON;
	public BeatBox.Icon VIEW_DETAILS_ICON;
	public BeatBox.Icon VIEW_ICONS_ICON;
	public BeatBox.Icon VIEW_VIDEO_ICON;

	/**
	 * These methods are useful for rendering non-loaded icons (Stock icons, etc.)
	 **/
	public Gdk.Pixbuf? render_icon (string icon_name, Gtk.IconSize size, Gtk.StyleContext? context = null) {
		var icon = new BeatBox.Icon (icon_name, null, null, null, false);
		return icon.render (size, context);
	}

	public Gtk.Image? render_image (string icon_name, Gtk.IconSize size) {
		var icon = new BeatBox.Icon (icon_name, null, null, null, false);
		return icon.render_image (size);
	}

	/**
	 * Loads icon information
	 **/
	public void load () {

		// 128 x 128
		DEFAULT_ALBUM_ART = new BeatBox.Icon ("media-audio", 128, IconType.MIMETYPE, IconFileType.PNG, true);
		DROP_ALBUM = new BeatBox.Icon ("drop-album", 128, IconType.MIMETYPE, null, true);
		MUSIC_FOLDER = new BeatBox.Icon ("folder-music", 128, IconType.MIMETYPE, null, true);

		HISTORY_ICON = new BeatBox.Icon ("document-open-recent", 22, IconType.ACTION, null, true);

		// 16 x 16
		BEATBOX_ICON = new BeatBox.Icon ("beatbox", 16, IconType.APP, null, true);
		RADIO_ICON = new BeatBox.Icon ("internet-radio", 16, IconType.MIMETYPE, null, true);
		MUSIC_ICON = new BeatBox.Icon ("library-music", 16, IconType.MIMETYPE, null, true);
		PODCAST_ICON = new BeatBox.Icon ("library-podcast", 16, IconType.MIMETYPE, null, true);
		AUDIOBOOK_ICON = new BeatBox.Icon ("library-audiobook", 16, IconType.MIMETYPE, null, true);
		AUDIO_CD_ICON = new BeatBox.Icon ("media-cdrom-audio", 16, IconType.MIMETYPE, null, true);
		PLAYLIST_ICON = new BeatBox.Icon ("playlist", 16, IconType.MIMETYPE, null, true);
		SMART_PLAYLIST_ICON = new BeatBox.Icon ("playlist-automatic", 16, IconType.MIMETYPE, null, true);
		LASTFM_LOVE_ICON = new BeatBox.Icon ("lastfm-love", 16, IconType.ACTION, null, true);
		LASTFM_BAN_ICON = new BeatBox.Icon ("lastfm-ban", 16, IconType.ACTION, null, true);
		STARRED_ICON = new BeatBox.Icon ("starred", 16, IconType.STATUS, null, true);
		NOT_STARRED_ICON = new BeatBox.Icon ("not-starred", 16, IconType.STATUS, null, true);
		INFO_ICON = new BeatBox.Icon ("help-info", 16, IconType.STATUS, null, true);
		NEW_PODCAST_ICON = new BeatBox.Icon ("podcast-new", 16, IconType.STATUS, null, true);

		// SYMBOLIC ICONS

		MEDIA_PLAY_SYMBOLIC = new BeatBox.Icon ("media-playback-start-symbolic", 16, IconType.ACTION, null, true);
		MEDIA_STOP_SYMBOLIC = new BeatBox.Icon ("media-playback-stop-symbolic", 16, IconType.ACTION, null, true);

		STARRED_SYMBOLIC_ICON = new BeatBox.Icon ("starred-symbolic", 16, IconType.STATUS, null, true);
		NOT_STARRED_SYMBOLIC_ICON = new BeatBox.Icon ("non-starred-symbolic", 16, IconType.STATUS, null, true);
		PROCESS_COMPLETED_ICON = new BeatBox.Icon ("process-completed-symbolic", 16, IconType.STATUS, null, true);
		PROCESS_ERROR_ICON = new BeatBox.Icon ("process-error-symbolic", 16, IconType.STATUS, null, true);
		NOW_PLAYING_ICON = new BeatBox.Icon ("audio-volume-high-symbolic", 16, IconType.STATUS, null, true);
		PROCESS_STOP_ICON = new BeatBox.Icon ("process-stop-symbolic", 16, IconType.ACTION, null, true);
		SHUFFLE_ON_ICON = new BeatBox.Icon ("media-playlist-shuffle-symbolic", 16, IconType.STATUS, null, true);
		SHUFFLE_OFF_ICON = new BeatBox.Icon ("media-playlist-no-shuffle-symbolic", 16, IconType.STATUS, null, true);
		REPEAT_ON_ICON = new BeatBox.Icon ("media-playlist-repeat-symbolic", 16, IconType.STATUS, null, true);
		REPEAT_ONCE_ICON = new BeatBox.Icon ("media-playlist-repeat-one-symbolic", 16, IconType.STATUS, null, true);
		REPEAT_OFF_ICON = new BeatBox.Icon ("media-playlist-no-repeat-symbolic", 16, IconType.STATUS, null, true);
		VIEW_COLUMN_ICON = new BeatBox.Icon ("view-list-column-symbolic", 16, IconType.ACTION, null, true);
		VIEW_DETAILS_ICON =new BeatBox.Icon ("view-list-details-symbolic", 16, IconType.ACTION, null, true);
		VIEW_ICONS_ICON = new BeatBox.Icon ("view-list-icons-symbolic", 16, IconType.ACTION, null, true);
		VIEW_VIDEO_ICON = new BeatBox.Icon ("view-list-video-symbolic", 16, IconType.ACTION, null, true);
	}
}

