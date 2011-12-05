/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
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

//using Gst;
using Gtk;

public class BeatBox.Song : GLib.Object{
	//core info
	public string file { get; set; default = ""; }
	public uint file_size { get; set; default = 0; }
	public int rowid { get; construct set; default = 0; }
	public int mediatype { get; set; default = 0; } // 0 = song, 1 = podcast, 2 = audiobook
	
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
	
	public string podcast_url { get; set; default = ""; }
	public bool is_new_podcast { get; set; default = false; }
	public int resume_pos { get; set; default = 0; } // for podcasts and audiobooks
	public int podcast_date { get; set; default = 0; }
	
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
		
		// added for podcasts/audiobooks
		rv.mediatype = mediatype;
		rv.podcast_url = podcast_url;
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
		if(_album_path == "" || _album_path == null)
			return GLib.Path.build_filename("/", "usr", "share", "icons", "hicolor", "128x128", "mimetypes", "media-audio.png", null);
		else
			return _album_path;
	}
	
	public string getArtistImagePath() {
		return Path.build_path("/", file.substring(0, _file.substring(0, _file.last_index_of("/", 0)).last_index_of("/", 0)), "Artist.jpg");
	}
	
	public static Song from_track(string root, GPod.Track track) {
		Song rv = new Song(Path.build_path("/", root, GPod.iTunesDB.filename_ipod2fs(track.ipod_path)));
		
		if(track.title != null) {			rv.title = track.title; }
		if(track.artist != null) {			rv.artist = track.artist; }
		if(track.albumartist != null) {		rv.album_artist = track.albumartist; }
		if(track.album != null) {			rv.album = track.album; }
		if(track.genre != null) {			rv.genre = track.genre; }
		if(track.comment != null) {			rv.comment = track.comment; }
		if(track.composer != null) {		rv.composer = track.composer; }
		if(track.grouping != null) {		rv.grouping = track.grouping; }
		rv.album_number = track.cd_nr;
		rv.album_count = track.cds;
		rv.track = track.track_nr;
		rv.track_count = track.tracks;
		rv.bitrate = track.bitrate;
		rv.year = track.year;
		rv.date_added = (int)track.time_added;
		rv.last_modified = (int)track.time_modified;
		rv.last_played = (int)track.time_played;
		rv.rating = track.rating;
		rv.play_count = track.playcount;
		rv.bpm = track.BPM;
		rv.skip_count = track.skipcount;
		rv.length = track.tracklen  / 1000;
		rv.file_size = track.size / 1000000;
		
		if(track.mediatype == GPod.MediaType.AUDIO)
			rv.mediatype = 0;
		else if(track.mediatype == GPod.MediaType.PODCAST)
			rv.mediatype = 1;
		else if(track.mediatype == GPod.MediaType.AUDIOBOOK)
			rv.mediatype = 2;
		
		rv.podcast_url = track.podcasturl;
		rv.is_new_podcast = track.mark_unplayed == 1;
		rv.resume_pos = (int)track.bookmark_time;
		rv.podcast_date = (int)track.time_released;
		
		if(rv.artist == "" && rv.album_artist != null)
			rv.artist = rv.album_artist;
		else if(rv.album_artist == "" && rv.artist != null)
			rv.album_artist = rv.artist;
		
		return rv;
	}
	
	public void update_track(ref unowned GPod.Track t) {
		if(t == null)
			return;
			
		if(title != null) 			t.title = title;
		if(artist != null) 			t.artist = artist;
		if(album_artist != null) 	t.albumartist = album_artist;
		if(album != null) 			t.album = album;
		if(genre != null) 			t.genre = genre;
		if(comment != null) 		t.comment = comment;
		if(composer != null) 		t.composer = composer;
		if(grouping != null)		t.grouping = grouping;
		t.cd_nr = (int)album_number;
		t.cds = (int)album_count;
		t.track_nr = (int)track;
		t.tracks = (int)track_count;
		t.bitrate = (int)bitrate;
		t.year = (int)year;
		t.time_modified = (time_t)last_modified;
		t.time_played = (time_t)last_played;
		t.rating = rating;
		t.playcount = play_count;
		t.recent_playcount = play_count;
		t.BPM = (uint16)bpm;
		t.skipcount = skip_count;
		t.tracklen = (int)length * 1000;
		t.size = file_size * 1000000;
		t.mediatype = 1;
		t.lyrics_flag = 1;
		t.description = lyrics;
		
		// TODO: Podcast stuff
		
		if(t.artist == "" && t.albumartist != null)
			t.artist = t.albumartist;
		else if(t.albumartist == "" && t.artist != null)
			t.albumartist = t.artist;
	}
	
	/* caller must set ipod_path */
	public GPod.Track track_from_song() {
		GPod.Track t = new GPod.Track();
		
		t.title = title;
		t.artist = artist;
		t.albumartist = album_artist;
		t.album = album;
		t.genre = genre;
		t.comment = comment;
		t.composer = composer;
		t.grouping = grouping;
		t.cd_nr = (int)album_number;
		t.cds = (int)album_count;
		t.track_nr = (int)track;
		t.tracks = (int)track_count;
		t.bitrate = (int)bitrate;
		t.year = (int)year;
		t.time_modified = (time_t)last_modified;
		t.time_played = (time_t)last_played;
		t.rating = rating;
		t.playcount = play_count;
		t.recent_playcount = play_count;
		t.BPM = (uint16)bpm;
		t.skipcount = skip_count;
		t.tracklen = (int)length * 1000;
		t.size = file_size * 1000000;
		t.mediatype = 1;
		t.lyrics_flag = 1;
		t.description = lyrics;
		
		// TODO: podcast stuff
		
		return t;
	}
}
