/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originaly Written by Scott Ringwelski for BeatBox Music Player
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

//using Gst;
using Gtk;

public class BeatBox.Song : GLib.Object{
	//core info
	public string file { get; set; default = ""; }
	public uint file_size { get; set; default = 0; }
	public int rowid { get; construct set; default = 0; }
	
	//tags
	public string title { get; set; default = "Unkown Title"; }
	public string composer { get; set; default = ""; }
	public string artist { get; set; default = "Unkown Artist"; }
	public string album_artist { get; set; default = ""; }
	public string album { get; set; default = "Unkown Album"; }
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
	public string lastfm_url { get; set; default = ""; }
	
	private string _album_path;
	public bool has_embedded { get; set; default = false; }
	
	public bool isPreview { get; set; default = false; }
	public bool isTemporary { get; set; default = false; }
	
	public Gdk.Pixbuf? unique_status_image;
	public bool showIndicator;
	public int pulseProgress;
	
	//core stuff
	public Song(string file) {
		this.file = file;
		
	}
	
	//audioproperties
	public string pretty_length() {
		uint minute = 0;
		uint seconds = length;
		
		while(seconds >= 60) {
			++minute;
			seconds -= 60;
		}
		
		return minute.to_string() + ":" + ((seconds < 10 ) ? "0" + seconds.to_string() : seconds.to_string());
	}
	
	public string pretty_last_played() {
		var t = Time.local(last_played);
		string rv = t.format("%m/%e/%Y %l:%M %p");
		return rv;
	}
	
	public string pretty_date_added() {
		var t = Time.local(date_added);
		string rv = t.format("%m/%e/%Y %l:%M %p");
		return rv;
	}
	
	public Song copy() {
		Song rv = new Song(_file);
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
		
		return rv;
	}
	
	public void setAlbumArtPath(string? path) {
		if(path != null)
			_album_path = path;
	}
	
	public string getAlbumArtPath() {
		if(_album_path == "" || _album_path == null)
			return GLib.Path.build_filename("/", "usr", "share", "icons", "hicolor", "128x128", "mimetypes", "media-audio.png", null);
		else
			return _album_path;
	}
	
	public string getArtistImagePath() {
		return Path.build_path("/", file.substring(0, _file.substring(0, _file.last_index_of("/", 0)).last_index_of("/", 0)), "Artist.jpg");
	}
}
