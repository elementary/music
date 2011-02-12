 
public class BeatBox.SongInfo : Object {
	private GLib.File file;
	
	public BeatBox.Song song;
	public LastFM.ArtistInfo artist;
	public LastFM.TrackInfo track;
	public LastFM.AlbumInfo album;
	
    public SongInfo() {
		var beatbox_folder = GLib.File.new_for_path(Environment.get_user_cache_dir() + "/beatbox");
		if(!beatbox_folder.query_exists())
			beatbox_folder.make_directory(null);
		
		file  = GLib.File.new_for_path(beatbox_folder.get_path() + "/beatbox_song_info.html");
		
		if(!file.query_exists()) {
			stdout.printf("Creating song info file \n");
			
			try {
				file.create (FileCreateFlags.NONE);
			}
			catch(GLib.Error err) {
				stdout.printf("Could not create song info file: %s\n", err.message);
			}
		}
		
		artist = new LastFM.ArtistInfo.basic();
		track = new LastFM.TrackInfo();
		album = new LastFM.AlbumInfo.basic();
	}
	
	public string update_file(LastFM.ArtistInfo art, LastFM.TrackInfo tra, LastFM.AlbumInfo alb, BeatBox.Song s) {
		song = s;
		artist = art;
		track = tra;
		album = alb;
		
		string html = generate_html();
		
		try {
			file.delete();
			file = File.new_for_path(Environment.get_user_cache_dir() + "/beatbox_song_info.html");
			var file_stream = file.create (FileCreateFlags.NONE);
			var data_stream = new DataOutputStream (file_stream);
			data_stream.put_string (html);
		}
		catch(GLib.Error err) {
			stdout.printf("Could not refresh song info view with new song: %s\n", err.message);
		}
        
        /** Create thread to use Webkit.Download to download the biggest image (or maybe 3rd?)
         * to ~/.beatbox/albums/ folder and name it by the album name. 
         */
        
        return Environment.get_user_cache_dir() + "/beatbox_song_info.html";
	}
	
	public string generate_html() {
		// do something else for no internet connection
		
		string rv;
		rv = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">";
		rv += "<html>";
		rv += "<head>";
		rv += "<style type=\"text/css\">";
		
		rv += "* {";
		rv += "padding:0 0 0 0;";
		rv += "margin: 0 0 0 0";
		rv += "background-color: #000;";
		rv += "color: #FFF;";
		rv += "}";
		
		rv += "body { ";
		rv += "background-color: #000;";
		rv += "color: #FFF;";
		rv += " } ";

		rv += "#heading {";
		rv += "background-color: #000;";
		rv += "padding: 5px;";
		rv += "width: 100%;";
		rv += "height: 200px;";
		rv += "margin-left: auto;";
		rv += "margin-right: auto";
		rv += "margin-bottom: 40px;";
		rv += "}";

		rv += "#main {";
		rv += "width: 100%;";
		rv += "background-color: #000;";
		rv += "padding: 5px;";
		rv += "margin-left: auto;";
		rv += "margin-right: auto";
		rv += "clear: both;";
		rv += "}";

		rv += "#left {";
		rv += "width: 75%;";
		rv += "padding: 5px;";
		rv += "background-color: #000;";
		rv += "float: left;";
		rv += "}";

		/*rv += "#middle{";
		rv += "width: 39%;";
		rv += "padding: 5px;";
		rv += "background-color: #000;";
		rv += "float: left;";
		rv += "text-align: center;";
		rv += "}";*/

		rv += "#right {";
		rv += "width: 20%;";
		rv += "padding: 5px;";
		rv += "background-color: #000;";
		rv += "float: right;";
		rv += "}";

		rv += "#footer {";
		rv += "width: 100%;";
		rv += "padding: 5px;";
		rv += "background-color: #000;";
		rv += "margin-left: auto;";
		rv += "margin-right: auto";
		rv += "}";

		rv += "#navlist li";
		rv += "{";
		rv += "display: inline;";
		rv += "list-style-type: none;";
		rv += "padding-right: 20px;";
		rv += "}";

		rv += "</style>";
		rv += "</head>";
		rv += "<body>";
		
		rv += "<!--First Row-->";
		rv += "<div id=\"heading\">";
		
		rv += "<div id=\"left\">";
		rv += "<p>";
		
		// find the right image because vala is stupid
		LastFM.Image big = album.url_image;
		
		// i should show s.artist, s.title, etc. if no internet or results did not come back
		rv += "<img src=\"" + big.url + "\" align=\"left\" style=\" margin:10px;\" ><br/>";
		rv += "<span style=\"font-size:44px; \">" + track.name + "</span><br/>";
		rv += "<span style=\"font-size:32px; \">" + artist.name + "</span><br/>";
		rv += "<span style=\"font-size:22px; \">" + album.name + "</span><br/>";
		rv += "</p>";
		rv += "</div>";
		
		rv += "<div id=\"right\">";
		rv += "<p>";
		rv += "Listeners: " + track.listeners.to_string() + "<br/>";
		rv += "Play count: " + track.playcount.to_string() + "<br/><br/>";
		rv += "Tags: ";
		
		string tags = "";
		foreach(LastFM.Tag tag in track.tags()) {
			tags += " <a href=\"" + tag.url +"\">" + tag.tag + "</a>,";
		}
		rv += tags.substring(0, (long)(tags.length - 1));
		
		rv += "<br/><br/>";
		rv += "Similar Bands: ";
		string sim = "";
		foreach(LastFM.ArtistInfo similar in artist.similarArtists()) {
			sim += " <a href=\"" + similar.url +"\">" + similar.name + "</a>,";
		}
		
		rv += sim.substring(0, (long)(sim.length - 1));
		
		rv += "</div>";
		rv += "</div>";
		
		rv += "<div style=\" width: 100%; margin-left: auto; margin-right: auto; clear:both; \" >";

		rv += "<p style=\" text-align:left;\">";
		rv += track.summary;
		rv += "</p>";
		
		rv += "</div>";
		
		/*rv += "<!--Second Row-->";
		rv += "<div id=\"main\">";
		rv += "<div id=\"left\">";
		
		rv += "</div>";
		rv += "<div id=\"middle\">";
		
		rv += "</div>";
		rv += "<div id=\"right\">";
		rv += "<p>" + album.releasedate + "</p>";
		rv += "</div>";
		rv += "</div>";
		rv += "<!--Third Row-->";*/
		rv += "<div id=\"footer\">";
		
		rv += "<p align=\"right\" style=\"padding:10px;\">";
		// find the right image because vala is stupid
		big = artist.url_image;
		
		rv += "<img src=\"" + big.url + "\" align=\"right\" style=\" margin-left: 10px; \"><br/>";
		rv += "<span style=\"  \">" + artist.summary + "</span>";
		rv += "</p>";
		
		rv += "</body>";
		rv += "</html>";
		
		return rv;
	}
}
