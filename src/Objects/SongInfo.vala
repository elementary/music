/* Merely a place holder for multiple pieces of information regarding
 * the current song playing. Mostly here because of dependence. */

public class BeatBox.SongInfo : GLib.Object {
	public BeatBox.Song? song;
	public LastFM.ArtistInfo? artist;
	public LastFM.TrackInfo? track;
	public LastFM.AlbumInfo? album;
	
    public SongInfo() {
		//don't initialize song because we check for null throughout the program
		artist = new LastFM.ArtistInfo.basic();
		track = new LastFM.TrackInfo();
		album = new LastFM.AlbumInfo.basic();
	}
	
	public void update(LastFM.ArtistInfo? art, LastFM.TrackInfo? tra, LastFM.AlbumInfo? alb, BeatBox.Song? s) {
		song = s;
		artist = art;
		track = tra;
		album = alb;
	}
}
