/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
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

public class Noise.Media : GLib.Object {
	public enum MediaType {
		SONG,
		PODCAST,
		AUDIOBOOK,
		STATION,
		UNSPECIFIED
	}
	
	// TODO: Define more constants or even enum values
	public const int PREVIEW_ROWID = -2;

	//core info
	public string uri { get; set; default = ""; }
	public uint file_size { get; set; default = 0; }
	public int rowid { get; construct set; default = 0; }
	public MediaType mediatype { get; set; default = MediaType.SONG; }
	
	//tags
	public string title { get; set; default = _("Unknown Title"); }
	public string composer { get; set; default = ""; }
	public string artist { get; set; default = _("Unknown Artist"); }
	public string album_artist { get; set; default = ""; }
	public string album { get; set; default = _("Unknown Album"); }
	public string grouping { get; set; default = ""; }
	public string genre { get; set; default = ""; }
	public string comment { get; set; default = ""; }
	public uint year { get; set; default = 0; }
	public uint track { get; set; default = 0; }
	public uint track_count { get; set; default = 0; }
	public uint album_number { get; set; default = 0; }
	public uint album_count { get; set; default = 0; }
	public uint bitrate { get; set; default = 0; }
	public uint length { get; set; default = 0; }
	public uint bpm { get; set; default = 0; }
	public uint samplerate { get; set; default = 0; }
	public string lyrics { get; set; default = ""; }
	
	private uint _rating;
	public uint rating {
		get { return _rating; }
		set { 
			if(value >= 0 && value <= 5)
				_rating = value;
		}
	}
	
	public uint play_count { get; set; default = 0; }
	public uint skip_count { get; set; default = 0; }
	public uint date_added { get; set; default = 0; }
	public uint last_played { get; set; default = 0; }
	public uint last_modified { get; set; default = 0; }
	
	public string podcast_rss { get; set; default = ""; }
	public string podcast_url { get; set; default = ""; }
	public bool is_new_podcast { get; set; default = false; }
	public int resume_pos { get; set; default = 0; } // for podcasts and audiobooks
	public int podcast_date { get; set; default = 0; }
	
	private string _album_path;
	public bool has_embedded { get; set; default = false; }
	public bool is_video { get; set; default = false; }
	
	public bool isPreview { get; set; default = false; }
	public bool isTemporary { get; set; default = false; }
	public bool location_unknown { get; set; default = false; }
	
	public Gdk.Pixbuf? unique_status_image;
	public bool showIndicator { get; set; default = false; }
	public int pulseProgress { get; set; default = 0; }
	
	//core stuff
	public Media(string uri) {
		this.uri = uri;
	}
	
	//audioproperties
	public string pretty_length() {
		return TimeUtils.pretty_time_mins (length);
	}
	
	public string pretty_last_played() {
		return TimeUtils.pretty_timestamp_from_uint (last_played);
	}
	
	public string pretty_date_added() {
		return TimeUtils.pretty_timestamp_from_uint (date_added);
	}

	public string pretty_podcast_date() {
		return TimeUtils.pretty_timestamp_from_uint (podcast_date);
	}

	public Media copy() {
		Media rv = new Media(uri);
		rv.file_size = file_size;
		rv.rowid = rowid;
		rv.track = track;
		rv.track_count = track_count;
		rv.album_number = album_number;
		rv.album_count = album_count;
		rv.title = title;
		rv.artist = artist;
		rv.composer = composer;
		rv.album_artist = album_artist;
		rv.album = album;
		rv.genre = genre;
		rv.grouping = grouping;
		rv.comment = comment;
		rv.year = year;
		rv.bitrate = bitrate;
		rv.length = length;
		rv.samplerate = samplerate;
		rv.bpm = bpm;
		rv.rating = rating;
		rv.play_count = play_count;
		rv.skip_count = skip_count;
		rv.date_added = date_added;
		rv.last_played = last_played;
		rv.lyrics = lyrics; 
		rv.setAlbumArtPath(getAlbumArtPath());
		rv.isPreview = isPreview;
		rv.isTemporary = isTemporary;
		rv.last_modified = last_modified;
		rv.pulseProgress = pulseProgress;
		rv.showIndicator = showIndicator;
		rv.unique_status_image = unique_status_image;
		rv.location_unknown = location_unknown;
		
		// added for podcasts/audiobooks
		rv.mediatype = mediatype;
		rv.podcast_url = podcast_url;
		rv.podcast_rss = podcast_rss;
		rv.is_new_podcast = is_new_podcast;
		rv.resume_pos = resume_pos;
		rv.podcast_date = podcast_date;
		
		return rv;
	}
	
	public void setAlbumArtPath(string? path) {
		if(path != null)
			_album_path = path;
	}
	
	public string getAlbumArtPath() {
#if 0
		if(_album_path == "" || _album_path == "")
			return Icons.DEFAULT_ALBUM_ART.backup_filename;
		else
			return _album_path;
#endif
        if (_album_path == null)
            _album_path = "";
        return _album_path;
	}
	
	public string getArtistImagePath() {
		if(isTemporary == true || mediatype != Media.MediaType.SONG)
			return "";
		
		var path_file = File.new_for_uri(uri);
		if(!path_file.query_exists())
			return "";
		
		var path = path_file.get_path();
		return Path.build_path("/", path.substring(0, path.substring(0, path.last_index_of("/", 0)).last_index_of("/", 0)), "Artist.jpg");
	}
}
