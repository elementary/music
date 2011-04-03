using Gtk;
using Gee;

public class BeatBox.InfoPanel : ScrolledWindow {
	private LibraryManager lm;
	private LibraryWindow lw;
	private int id; // need this for when rating the song
	
	private Label title;
	private Label artist;
	private Gtk.Image artistImage;
	private RatingWidget rating; // need to make custom widget in future
	private Label album;
	private Label year;
	private SimilarSongsView ssv;
	
	public InfoPanel(LibraryManager lmm, LibraryWindow lww) {
		lm = lmm;
		lw = lww;
		
		buildUI();
		
		lm.songs_updated.connect(songs_updated);
	}
	
	private void buildUI() {
		/* put it in event box so we can color background white */
		EventBox eb = new EventBox();
		
		// make the background white
		Gdk.Color c = Gdk.Color();
		Gdk.Color.parse("#FFFFFF", out c);
		eb.modify_bg(StateType.NORMAL, c);
		
		title = new Label("Title");
		artist = new Label("Artist");
		artistImage = new Image();
		rating = new RatingWidget();
		album = new Label("Album");
		year = new Label("Year");
		ssv = new SimilarSongsView(lm, lw);
		
		/* use markup */
		title.set_markup("<span size=\"large\"><b>Title</b></span>");
		year.set_markup("<span size=\"x-small\">Year</span>");
		
		/* ellipsize */
		title.ellipsize = Pango.EllipsizeMode.END;
		artist.ellipsize = Pango.EllipsizeMode.END;
		album.ellipsize = Pango.EllipsizeMode.END;
		year.ellipsize = Pango.EllipsizeMode.END;
		
		
		HBox padding = new HBox(false, 10);
		VBox content = new VBox(false, 0);
		
		content.pack_start(wrap_alignment(title, 5, 0, 0, 5), false, true, 0);
		content.pack_start(wrap_alignment(artist, 2, 0, 0, 5), false, true, 0);
		content.pack_start(wrap_alignment(artistImage, 5, 0, 0, 5), false, true, 0);
		content.pack_start(wrap_alignment(rating, 5, 0, 0, 5), false, true, 0);
		content.pack_start(wrap_alignment(album, 5, 0, 0, 5), false, true, 0);
		content.pack_start(wrap_alignment(year, 0, 0, 20, 5), false, true, 0);
		content.pack_start(ssv, true, true, 0);
		
		eb.add(content);
		
		padding.pack_start(eb, true, true, 0);
		
		Viewport vp = new Viewport(null, null);
		vp.set_shadow_type(ShadowType.NONE);
		vp.add(padding);
		
		add(vp);
		
		this.set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
		this.set_shadow_type(ShadowType.NONE);
		
		// signals here
		rating.rating_changed.connect(ratingChanged);
		this.size_allocate.connect(resized);
	}
	
	public static Gtk.Alignment wrap_alignment (Gtk.Widget widget, int top, int right, int bottom, int left) {
		var alignment = new Gtk.Alignment(0.0f, 0.0f, 1.0f, 1.0f);
		alignment.top_padding = top;
		alignment.right_padding = right;
		alignment.bottom_padding = bottom;
		alignment.left_padding = left;
		
		alignment.add(widget);
		return alignment;
	}
	
	public void updateSong(int new_id) {
		id = new_id;
		Song s = lm.song_from_id(id);
		
		title.set_markup("<span size=\"large\"><b>" + s.title.replace("&", "&amp;") + "</b></span>");
		artist.set_text(s.artist);
		album.set_text(s.album);
		
		// do rating stuff
		rating.set_rating(s.rating);
		
		if(s.year > 1900)
			year.set_markup("<span size=\"x-small\">" + s.year.to_string() + "</span>");
		else
			year.set_markup("");
		
		updateArtistImage();
		ssv.hide();
	}
	
	public void updateArtistImage() {
		if(lm.song_from_id(id) == null)
			return;
		
		string file = "";
		if((file = lm.get_artist_image_location(id)) != null) {
			artistImage.show();
			try {
				artistImage.set_from_pixbuf(new Gdk.Pixbuf.from_file_at_scale(file, lm.settings.getMoreWidth() - 10, lm.settings.getMoreWidth() - 10, true));
				//artistImage.set_from_pixbuf(new Gdk.Pixbuf.from_file(file));
			}
			catch(GLib.Error err) {
				stdout.printf("Could not set info panel image art: %s\n", err.message);
			}
		}
		else
			artistImage.hide();
	}
	
	public void updateSongList(Collection<Song> songs) {
		if(songs.size > 8) {
			ssv.show();
			ssv.populateView(songs);
		}
		else {
			ssv.hide();
		}
	}
	
	public virtual void ratingChanged(int new_rating) {
		lm.song_from_id(id).rating = new_rating;
		lm.update_song(lm.song_from_id(id), false);
	}
	
	public virtual void songs_updated(Collection<int> ids) {
		if(ids.contains(lm.song_info.song.rowid))
			rating.set_rating(lm.song_info.song.rating);
	}
	
	public virtual void resized(Gdk.Rectangle rectangle) {
		// resize the image to fit
		updateArtistImage();
	}
}
