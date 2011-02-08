using Gtk;

public class BeatBox.SongEditor : Window {
	private BeatBox.Song _original;
	
	private VBox vert; // seperates editors with buttons and other stuff
	private HBox horiz; // seperates text with numerical editors
	private VBox textVert; // seperates text editors
	private VBox numerVert; // seperates numerical editors
	
	
	private Entry _title;
	private Label _titleLabel;
	private HBox _titleBox;
	
	private Entry _artist;
	private Label _artistLabel;
	private HBox _artistBox;
	
	private Entry _album;
	private Label _albumLabel;
	private HBox _albumBox;
	
	private Entry _genre;
	private Label _genreLabel;
	private HBox _genreBox;
	
	private ScrolledWindow _commentScroll;
	private TextView _comment;
	private Label _commentLabel;
	private HBox _commentBox;
	
	private SpinButton _track;
	private Label _trackLabel;
	private HBox _trackBox;
	
	private SpinButton _year;
	private Label _yearLabel;
	private HBox _yearBox;
	
	private Button _save;
	private Button _cancel;
	
	
	public signal void song_saved(Song s);
	
	public SongEditor(Song s) {
		this.title = "Properties";
		this.window_position = WindowPosition.CENTER;
		
		_original = s;
		
		vert = new VBox(false, 0);
		horiz = new HBox(false, 0);
		
		textVert = new VBox(false, 0);
		numerVert = new VBox(false, 0);
		
		_title = new Entry();
		_title.set_size_request(300, 25);
		
		_artist = new Entry();
		_artist.set_size_request(300, 25);
		
		_album = new Entry();
		_album.set_size_request(300, 25);
		
		_genre = new Entry();
		_genre.set_size_request(300, 25);
		
		_commentScroll = new ScrolledWindow(null, null);
        _commentScroll.set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
		_comment = new TextView();
		_comment.set_size_request(300, 100);
		_comment.set_wrap_mode(WrapMode.WORD);
		_commentScroll.add(_comment);
		
		_track = new SpinButton.with_range(0, 100, 1);
		_track.set_size_request(100, 25);
		
		_year = new SpinButton.with_range(0, 2999, 1);
		_year.set_size_request(100, 25);
		
		_titleLabel = new Label("Title");
		_titleLabel.set_size_request(60, 20);
		
		_artistLabel = new Label("Artist");
		_artistLabel.set_size_request(60, 20);
		
		_albumLabel = new Label("Album");
		_albumLabel.set_size_request(60, 20);
		
		_genreLabel = new Label("Genre");
		_genreLabel.set_size_request(60, 20);
		
		_commentLabel = new Label("Comment");
		_commentLabel.set_size_request(60, 20);
		
		_trackLabel = new Label("Track");
		_trackLabel.set_size_request(60, 20);
		
		_yearLabel = new Label("Year");
		_yearLabel.set_size_request(60, 20);
		
		_title.text = s.title;
		_artist.text = s.artist;
		_album.text = s.album;
		_genre.text = s.genre;
		_comment.get_buffer().text = s.comment;
		_track.value = (double)s.track;
		_year.value = (double)s.year;
		
		_titleBox = new HBox(false, 0);
		_titleBox.pack_start(_titleLabel);
		_titleBox.pack_start(_title);
		
		_artistBox = new HBox(false, 0);
		_artistBox.pack_start(_artistLabel);
		_artistBox.pack_start(_artist);
		
		_albumBox = new HBox(false, 0);
		_albumBox.pack_start(_albumLabel);
		_albumBox.pack_start(_album);
		
		_genreBox = new HBox(false, 0);
		_genreBox.pack_start(_genreLabel);
		_genreBox.pack_start(_genre);
		
		_commentBox = new HBox(false, 0);
		_commentBox.pack_start(_commentLabel);
		_commentBox.pack_start(_commentScroll);
		
		textVert.pack_start(_titleBox, false, true, 5);
		textVert.pack_start(_artistBox, false, true, 5);
		textVert.pack_start(_albumBox, false, true, 5);
		textVert.pack_start(_genreBox, false, true, 5);
		textVert.pack_start(_commentBox, false, true, 5);
		
		_trackBox = new HBox(false, 0);
		_trackBox.pack_start(_trackLabel);
		_trackBox.pack_start(_track);
		
		_yearBox = new HBox(false, 0);
		_yearBox.pack_start(_yearLabel);
		_yearBox.pack_start(_year);
		
		numerVert.pack_start(_trackBox, false, true, 5);
		numerVert.pack_start(_yearBox, false, true, 5);
		
		horiz.pack_start(textVert, false, true, 10);
		horiz.pack_start(numerVert, false, true, 5);
		
		vert.pack_start(horiz, true, true, 0);
		
		HBox buttonSep = new HBox(false, 2);
		_cancel = new Button.with_label("Cancel");
		Label fillerLabel = new Label("");
		_save = new Button.with_label("Save");
		
		buttonSep.pack_start(_cancel, false, false, 0);
		buttonSep.pack_start(fillerLabel, true, true, 0);
		buttonSep.pack_start(_save, false, false, 0);
		
		_cancel.clicked.connect( () => { this.destroy(); } );
		_save.clicked.connect(saveClicked);
		
		vert.pack_start(buttonSep, false, true, 0);
		
		add(vert);
		
		show_all();
	}
	
	public virtual void saveClicked() {
		_original.title = _title.text;
		_original.artist = _artist.text;
		_original.album = _album.text;
		_original.genre = _genre.text;
		_original.comment = _comment.get_buffer().text;
		_original.track = (int)_track.value;
		_original.year = (int)_year.value;
		
		song_saved(_original);
		this.destroy();
	}
}
