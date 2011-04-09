using Gtk;
using Gee;

public class BeatBox.SongEditor : Window {
	LinkedList<Song> _songs;
	
	//for padding around notebook mostly
	private VBox content;
	private HBox padding;
	
	private VBox vert; // seperates editors with buttons and other stuff
	private HBox horiz; // seperates text with numerical editors
	private VBox textVert; // seperates text editors
	private VBox numerVert; // seperates numerical editors
	
	private HashMap<string, FieldEditor> fields;// a hashmap with each property and corresponding editor
	private StatsDisplay stats;
	
	private Button _save;
	
	
	public signal void songs_saved(LinkedList<Song> songs);
	
	public SongEditor(LibraryWindow lw, LinkedList<Song> songs, LastFM.TrackInfo? track, LastFM.ArtistInfo? artist, LastFM.AlbumInfo? album) {
		this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(lw);
		this.destroy_with_parent = true;
		
		fields = new HashMap<string, FieldEditor>();
		
		_songs = songs;
		Song sum = songs.get(0).copy();
		
		/** find what these songs have what common, and keep those values **/
		foreach(Song s in songs) {
			if(s.track != sum.track)
				sum.track = -1;
			if(s.title != sum.title)
				sum.title = "";
			if(s.artist != sum.artist)
				sum.artist = "";
			if(s.album != sum.album)
				sum.album = "";
			if(s.genre != sum.genre)
				sum.genre = "";
			if(s.comment != sum.comment)
				sum.comment = "";
			if(s.year != sum.year)
				sum.year = -1;
			if(s.bitrate != sum.bitrate)
				sum.bitrate = -1;
			//length = 0;
			//samplerate = 0;
			if(s.bpm != sum.bpm)
				sum.bpm = -1;
			if(s.rating != sum.rating)
				sum.rating = -1;
			//score = 0;
			//play_count = 0;
			//skip_count = 0;
			//date_added = 0;
			//last_played = 0;
		}
		
		if(songs.size == 1) {
			title = "Editing " + sum.title + (sum.artist != "" ? (" by " + sum.artist) : "") + (sum.album != "" ? (" on " + sum.album) : "");
		}
		else {
			title = "Editing " + songs.size.to_string() + " songs";// + (sum.artist != "" ? (" by " + sum.artist + " ") : " ") + (sum.album != "" ? (" on " + sum.album) : "");
		}
		
		fields.set("Title", new FieldEditor("Title", sum.title, new Entry()));
		fields.set("Artist", new FieldEditor("Artist", sum.artist, new Entry()));
		fields.set("Album", new FieldEditor("Album", sum.album, new Entry()));
		fields.set("Genre", new FieldEditor("Genre", sum.genre, new Entry()));
		fields.set("Comment", new FieldEditor("Comment", sum.comment, new TextView()));
		fields.set("Track", new FieldEditor("Track", sum.track.to_string(), new SpinButton.with_range(0, 100, 1)));
		fields.set("Year", new FieldEditor("Year", sum.year.to_string(), new SpinButton.with_range(1000, 9999, 1)));
		fields.set("Rating", new FieldEditor("Rating", sum.rating.to_string(), new RatingWidget(null, false)));
		
		content = new VBox(false, 10);
		padding = new HBox(false, 10);
		vert = new VBox(false, 0);
		horiz = new HBox(false, 0);
		textVert = new VBox(false, 0);
		numerVert = new VBox(false, 0);
		stats = new StatsDisplay(sum.play_count, sum.skip_count, sum.last_played);
		
		textVert.pack_start(fields.get("Title"), false, true, 0);
		textVert.pack_start(fields.get("Artist"), false, true, 5);
		textVert.pack_start(fields.get("Album"), false, true, 5);
		textVert.pack_start(fields.get("Comment"), false, true, 5);
		
		numerVert.pack_start(fields.get("Track"), false, true, 0);
		numerVert.pack_start(fields.get("Genre"), false, true, 5);
		numerVert.pack_start(fields.get("Year"), false, true, 5);
		numerVert.pack_start(fields.get("Rating"), false, true, 5);
		//if(songs.size == 1)
			//numerVert.pack_start(stats, false, true, 5);
		
		horiz.pack_start(wrap_alignment(textVert, 0, 30, 0, 0), false, true, 0);
		horiz.pack_end(numerVert, false, true, 0);
		vert.pack_start(horiz, true, true, 0);
		
		HButtonBox buttonSep = new HButtonBox();
		buttonSep.set_layout(ButtonBoxStyle.END);
		_save = new Button.with_label("Done");
		
		buttonSep.pack_end(_save, false, false, 0);
		
		content.pack_start(wrap_alignment(vert, 10, 0, 0, 0), true, true, 0);
		content.pack_start(wrap_alignment(buttonSep, 0, 0, 10, 0), false, true, 0);
		
		padding.pack_start(content, true, true, 10);
		add(padding);
		
		show_all();
		
		if(_songs.size == 1) {
			foreach(FieldEditor fe in fields.values)
				fe.set_check_visible(false);
		}
		
		_save.clicked.connect(saveClicked);
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
	
	public Viewport generate_track_page(LastFM.TrackInfo track) {
		Viewport rv = new Viewport(null, null);
		
		Label l = new Label(track.name + "," + track.url + "," + track.artist);
		rv.add(l);
		
		return rv;
	}
	
	public Viewport generate_artist_page(LastFM.ArtistInfo artist) {
		Viewport rv = new Viewport(null, null);
		
		Label l = new Label(artist.name + "," + artist.url);
		rv.add(l);
		
		return rv;
	}
	
	public Viewport generate_album_page(LastFM.AlbumInfo album) {
		Viewport rv = new Viewport(null, null);
		
		Label l = new Label(album.name);
		rv.add(l);
		
		return rv;
	}
	
	public virtual void saveClicked() {
		foreach(Song s in _songs) {
			if(fields.get("Title").checked())
				s.title = fields.get("Title").get_value();
			if(fields.get("Artist").checked())
				s.artist = fields.get("Artist").get_value();
			if(fields.get("Album").checked())
				s.album = fields.get("Album").get_value();
			if(fields.get("Genre").checked())
				s.genre = fields.get("Genre").get_value();
			if(fields.get("Comment").checked())
				s.comment = fields.get("Comment").get_value();
				
			if(fields.get("Track").checked())
				s.track = int.parse(fields.get("Track").get_value());
			if(fields.get("Year").checked())
				s.year = int.parse(fields.get("Year").get_value());
			if(fields.get("Rating").checked())
				s.rating = int.parse(fields.get("Rating").get_value());
		}
		
		songs_saved(_songs);
		this.destroy();
	}
}

public class BeatBox.FieldEditor : VBox {
	private string _name;
	private string _original;
	
	private HBox nameBox;
	
	private CheckButton check;
	private Label label;
	private Entry entry;
	private TextView textView;
	private SpinButton spinButton;
	private RatingWidget ratingWidget;
	private Image image;
	private Button reset;

	public FieldEditor(string name, string original, Widget w) {
		_name = name;
		_original = original;
		
		this.spacing = 0;
		
		check = new CheckButton();
		label = new Label(_name);
		nameBox = new HBox(false, 0);
		
		label.justify = Justification.LEFT;
		label.xalign = 0.0f;
		label.set_markup("<b>" + _name + "</b>");
		
		nameBox.pack_start(check, false, false, 0);
		nameBox.pack_start(label, false, true, 0);
		
		this.pack_start(nameBox, false, false, 0);
		
		if(w is Entry && !(w is SpinButton)) {
			check.set_active(original != "");
			
			entry = (Entry)w;
			if(name != "Genre")
				entry.set_size_request(300, -1);
			else
				entry.set_size_request(100, -1);
			
			entry.set_text(original);
			entry.changed.connect(entryChanged);
			this.pack_start(entry, true, true, 0);
		}
		else if(w is TextView) {
			check.set_active(original != "");
			
			textView = (TextView)w;
			textView.set_size_request(300, 100);
			textView.set_wrap_mode(WrapMode.WORD);
			textView.get_buffer().text = original;
			
			ScrolledWindow scroll = new ScrolledWindow(null, null);
			Viewport viewport = new Viewport(null, null);
			
			viewport.set_shadow_type(ShadowType.ETCHED_IN);
			scroll.set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
			
			viewport.add(textView);
			scroll.add(viewport);
			
			scroll.set_size_request(300, 100);
			viewport.set_size_request(300, 100);
			
			textView.buffer.changed.connect(textViewChanged);
			this.pack_start(scroll, true, true, 0);
		}
		else if(w is SpinButton) {
			check.set_active(original != "-1");
			
			spinButton = (SpinButton)w;
			spinButton.set_size_request(100, -1);
			spinButton.value = double.parse(original);
			spinButton.adjustment.value_changed.connect(spinButtonChanged);
			this.pack_start(spinButton, true, true, 0);
		}
		else if(w is Image) {
			check.set_active(original != "");
			
			image = (Image)w;
			image.set_size_request(100, 100);
			image.set_from_file(original);
			//callback on file dialogue saved. setup here
			this.pack_start(image, true, true, 0);
		}
		else if(w is RatingWidget) {
			check.set_active(original != "");
			
			ratingWidget = (RatingWidget)w;
			ratingWidget.set_rating(int.parse(original));
			ratingWidget.rating_changed.connect(ratingChanged);
			
			this.pack_start(ratingWidget, true, true, 0);
		}
	}
	
	public void set_check_visible(bool val) {
		check.set_visible(false);
	}
	
	public virtual void entryChanged() {
		if(entry.text != _original)
			check.set_active(true);
		else
			check.set_active(false);
	}
	
	public virtual void textViewChanged() {
		if(textView.get_buffer().text != _original)
			check.set_active(true);
		else
			check.set_active(false);
	}
	
	public virtual void spinButtonChanged() {
		if(spinButton.value != double.parse(_original))
			check.set_active(true);
		else
			check.set_active(false);
	}
	
	public virtual void ratingChanged(int new_rating) {
		if(ratingWidget.get_rating() != int.parse(_original))
			check.set_active(true);
		else
			check.set_active(false);
	}
	
	public bool checked() {
		return check.get_active();
	}
	
	public virtual void resetClicked() {
		if(entry != null) {
			entry.text = _original;
		}
		else if(textView != null) {
			textView.get_buffer().text = _original;
		}
		else if(spinButton != null) {
			spinButton.value = double.parse(_original);
		}
		else if(image != null) {
			image.set_from_file(_original);
		}
		else if(ratingWidget != null) {
			ratingWidget.set_rating(int.parse(_original));
		}
	}
	
	public string get_value() {
		if(entry != null) {
			return entry.text;
		}
		else if(textView != null) {
			return textView.get_buffer().text;
		}
		else if(spinButton != null) {
			return spinButton.value.to_string();
		}
		else if(image != null) {
			return image.file;
		}
		else if(ratingWidget != null) {
			return ratingWidget.get_rating().to_string();
		}
		
		return "";
	}
}

public class BeatBox.StatsDisplay : VBox {
	public int plays;
	public int skips;
	public int last_played;
	
	Label header;
	Label info;
	Button reset;
	
	public StatsDisplay(int plays, int skips, int last_played) {
		this.plays = plays;
		this.skips = skips;
		this.last_played = last_played;
		
		header = new Label("");
		info = new Label("");
		reset = new Button.with_label("Reset");
		
		header.justify = Justification.LEFT;
		header.xalign = 0.0f;
		header.set_markup("<b>Stats</b>");
		
		info.justify = Justification.LEFT;
		info.xalign = 0.0f;
		
		setInfoText();
		
		pack_start(header, true, false, 0);
		pack_start(info, true, true, 0);
		pack_start(reset, true, false, 0);
		
		reset.clicked.connect(resetClicked);
	}
	
	public virtual void resetClicked() {
		plays = 0;
		skips = 0;
		last_played = 0;
		
		setInfoText();
		
		reset.set_sensitive(false);
	}
	
	private void setInfoText() {
		var t = Time.local(last_played);
		string pretty_last_played = t.format("%m/%e/%Y %l:%M %p");
		
		string text = "";
		text += "Plays: <span gravity=\"east\">" + plays.to_string() + "</span>\n";
		text += "Skips: <span gravity=\"east\">" + skips.to_string() + "</span>\n";
		text += "Last Played: <span gravity=\"east\">" + ((last_played != 0) ? pretty_last_played : "Never") + "</span>";
		
		info.set_markup(text);
	}
}
