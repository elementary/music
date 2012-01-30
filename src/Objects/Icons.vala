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

/* TODO: Use a namespace rather than a class */

public class BeatBox.Icons : GLib.Object {
	// TODO
	//public Icon MEDIA_PLAY_SYMBOLIC_ICON;
	//public Icon MEDIA_STOP_SYMBOLIC_ICON;

	// 128 x 128
	public Icon DEFAULT_ALBUM_ART = new Icon ("media-audio", 128, Icon.IconType.MIMETYPE, Icon.IconFileType.PNG, true);
	public Icon DROP_ALBUM = new Icon ("drop-album", 128, Icon.IconType.MIMETYPE, null, true);
	public Icon MUSIC_FOLDER = new Icon ("folder-music", 128, Icon.IconType.MIMETYPE, null, true);

	// 22 x 22
	public Icon HISTORY_ICON = new Icon ("document-open-recent", 22, Icon.IconType.ACTION, null, true);

	// 16 x 16
	public Icon BEATBOX_ICON = new Icon ("beatbox", 16, Icon.IconType.APP, null, true);
	public Icon RADIO_ICON = new Icon ("internet-radio", 16, Icon.IconType.MIMETYPE, null, true);
	public Icon MUSIC_ICON = new Icon ("library-music", 16, Icon.IconType.MIMETYPE, null, true);
	public Icon PODCAST_ICON = new Icon ("library-podcast", 16, Icon.IconType.MIMETYPE, null, true);
	public Icon AUDIOBOOK_ICON = new Icon ("library-audiobook", 16, Icon.IconType.MIMETYPE, null, true);
	public Icon AUDIO_CD_ICON = new Icon ("media-cdrom-audio", 16, Icon.IconType.MIMETYPE, null, true);
	public Icon PLAYLIST_ICON = new Icon ("playlist", 16, Icon.IconType.MIMETYPE, null, true);
	public Icon SMART_PLAYLIST_ICON = new Icon ("playlist-automatic", 16, Icon.IconType.MIMETYPE, null, true);
	public Icon LASTFM_LOVE_ICON = new Icon ("lastfm-love", 16, Icon.IconType.ACTION, null, true);
	public Icon LASTFM_BAN_ICON = new Icon ("lastfm-ban", 16, Icon.IconType.ACTION, null, true);
	public Icon STARRED_ICON = new Icon ("starred", 16, Icon.IconType.STATUS, null, true);
	public Icon NOT_STARRED_ICON = new Icon ("not-starred", 16, Icon.IconType.STATUS, null, true);
	public Icon INFO_ICON = new Icon ("help-info", 16, Icon.IconType.STATUS, null, true);
	public Icon NEW_PODCAST_ICON = new Icon ("podcast-new", 16, Icon.IconType.STATUS, null, true);

	// SYMBOLIC ICONS
	public Icon STARRED_SYMBOLIC_ICON = new Icon ("starred-symbolic", 16, Icon.IconType.STATUS, null, true);
	public Icon NOT_STARRED_SYMBOLIC_ICON = new Icon ("non-starred-symbolic", 16, Icon.IconType.STATUS, null, true);
	public Icon PROCESS_COMPLETED_ICON = new Icon ("process-completed-symbolic", 16, Icon.IconType.STATUS, null, true);
	public Icon PROCESS_ERROR_ICON = new Icon ("process-error-symbolic", 16, Icon.IconType.STATUS, null, true);
	public Icon NOW_PLAYING_ICON = new Icon ("audio-volume-high-symbolic", 16, Icon.IconType.STATUS, null, true);
	public Icon PROCESS_STOP_ICON = new Icon ("process-stop-symbolic", 16, Icon.IconType.ACTION, null, true);
	public Icon SHUFFLE_ON_ICON = new Icon ("media-playlist-shuffle-symbolic", 16, Icon.IconType.STATUS, null, true);
	public Icon SHUFFLE_OFF_ICON = new Icon ("media-playlist-no-shuffle-symbolic", 16, Icon.IconType.STATUS, null, true);
	public Icon REPEAT_ON_ICON = new Icon ("media-playlist-repeat-symbolic", 16, Icon.IconType.STATUS, null, true);
	public Icon REPEAT_ONCE_ICON = new Icon ("media-playlist-repeat-one-symbolic", 16, Icon.IconType.STATUS, null, true);
	public Icon REPEAT_OFF_ICON = new Icon ("media-playlist-no-repeat-symbolic", 16, Icon.IconType.STATUS, null, true);
	public Icon VIEW_COLUMN_ICON = new Icon ("view-list-column-symbolic", 16, Icon.IconType.ACTION, null, true);
	public Icon VIEW_DETAILS_ICON =new Icon ("view-list-details-symbolic", 16, Icon.IconType.ACTION, null, true);
	public Icon VIEW_ICONS_ICON = new Icon ("view-list-icons-symbolic", 16, Icon.IconType.ACTION, null, true);
	public Icon VIEW_VIDEO_ICON = new Icon ("view-list-video-symbolic", 16, Icon.IconType.ACTION, null, true);

	public Icons (LibraryManager lm, LibraryWindow lw) {
		// TODO: Get rid of this constructor as well
	}

	public void load_icons () {
		// TODO: Get rid of this function
	}

	/**
	 * These methods are useful for rendering non-loaded icons (Stock icons, etc.)
	 **/
	public Gdk.Pixbuf? render_icon (string icon_name, Gtk.IconSize size, Gtk.StyleContext? context = null) {
		var icon = new Icon (icon_name, null, null, null, false);
		return icon.render (size, context);
	}

	public Gtk.Image? render_image (string icon_name, Gtk.IconSize size) {
		var icon = new Icon (icon_name, null, null, null, false);
		return icon.render_image (size);
	}
}

