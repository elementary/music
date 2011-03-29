using Gtk;
using Gee;

public class BeatBox.SongEditor : Window {
	LinkedList<Song> _songs;
	
	//for padding around notebook mostly
	private VBox content;
	private HBox padding;
	
	private Notebook notebook;
	private Viewport editView;
	private VBox vert; // seperates editors with buttons and other stuff
	private HBox horiz; // seperates text with numerical editors
	private VBox textVert; // seperates text editors
	private VBox numerVert; // seperates numerical editors
	
	private HashMap<string, FieldEditor> fields;// a hashmap with each property and corresponding editor
	
	private Button _save;
	
	
	public signal void songs_saved(LinkedList<Song> songs);
	
	public SongEditor(LibraryWindow lw, LinkedList<Song> songs, LastFM.TrackInfo? track, LastFM.ArtistInfo? artist, LastFM.AlbumInfo? album) {
		this.title = "Properties";
		
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
		
		fields.set("Title", new FieldEditor("Title", sum.title, new Entry()));
		fields.set("Artist", new FieldEditor("Artist", sum.artist, new Entry()));
		fields.set("Album", new FieldEditor("Album", sum.album, new Entry()));
		fields.set("Genre", new FieldEditor("Genre", sum.genre, new Entry()));
		fields.set("Comment", new FieldEditor("Comment", sum.comment, new TextView()));
		fields.set("Track", new FieldEditor("Track", sum.track.to_string(), new SpinButton.with_range(0, 100, 1)));
		fields.set("Year", new FieldEditor("Year", sum.year.to_string(), new SpinButton.with_range(1000, 9999, 1)));
		
		content = new VBox(false, 10);
		padding = new HBox(false, 10);
		notebook = new Notebook();
		editView = new Viewport(null, null);
		vert = new VBox(false, 0);
		horiz = new HBox(false, 0);
		textVert = new VBox(false, 0);
		numerVert = new VBox(false, 0);
		
		textVert.pack_start(fields.get("Title"), false, true, 0);
		textVert.pack_start(fields.get("Artist"), false, true, 0);
		textVert.pack_start(fields.get("Album"), false, true, 0);
		textVert.pack_start(fields.get("Genre"), false, true, 0);
		textVert.pack_start(fields.get("Comment"), false, true, 0);
		
		numerVert.pack_start(fields.get("Track"), false, true, 0);
		numerVert.pack_start(fields.get("Year"), false, true, 0);
		
		horiz.pack_start(textVert, false, true, 0);
		horiz.pack_end(numerVert, false, true, 0);
		vert.pack_start(horiz, true, true, 0);
		
		HButtonBox buttonSep = new HButtonBox();
		buttonSep.set_layout(ButtonBoxStyle.END);
		_save = new Button.with_label("Done");
		
		buttonSep.pack_end(_save, false, false, 0);
		
		editView.add(vert);
		
		notebook.append_page(editView, new Label("Properties"));
		
		if(track != null)
			notebook.append_page(generate_track_page(track), new Label("Track Info"));
		if(artist != null)
			notebook.append_page(generate_artist_page(artist), new Label("Artist Info"));
		if(album != null)
			notebook.append_page(generate_album_page(album), new Label("Album Info"));
		
		content.pack_start(wrap_alignment(notebook, 10, 0, 0, 0), true, true, 0);
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
	private Image image;
	private Button reset;

	public FieldEditor(string name, string original, Widget w) {
		_name = name;
		_original = original;
		
		this.spacing = 5;
		
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
			entry.set_size_request(200, -1);
			entry.set_text(original);
			entry.changed.connect(entryChanged);
			this.pack_start(entry, true, true, 0);
		}
		else if(w is TextView) {
			check.set_active(original != "");
			
			textView = (TextView)w;
			textView.set_size_request(200, 100);
			textView.set_wrap_mode(WrapMode.WORD);
			textView.get_buffer().text = original;
			
			ScrolledWindow scroll = new ScrolledWindow(null, null);
			scroll.set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
			scroll.add(textView);
			
			textView.buffer.changed.connect(textViewChanged);
			this.pack_start(scroll, true, true, 0);
		}
		else if(w is SpinButton) {
			check.set_active(original != "-1");
			
			spinButton = (SpinButton)w;
			spinButton.set_size_request(80, -1);
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
		
		return "";
	}
}
