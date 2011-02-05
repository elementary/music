using Gtk;
using Gee;

public class BeatBox.SmartPlaylistEditor : Window {
	SmartPlaylist _sp;
	
	VBox vert;
	ElementaryWidgets.ElementaryEntry _name;
	ComboBox _and_or;
	VBox vertQueries;
	Button cancel;
	Button save;
	Button addButton;
	Gee.ArrayList<SmartPlaylistEditorQuery> spQueries;
	
	public signal void playlist_saved(SmartPlaylist sp);
	
	public SmartPlaylistEditor(SmartPlaylist sp) {
		_sp = sp;
		
		vert = new VBox(false, 10);
		
		HBox nameBox = new HBox(false, 1);
		_name = new ElementaryWidgets.ElementaryEntry("Playlist Title");
		nameBox.pack_start(_name, true, true, 0);
		
		if(_sp.name != "") {
			_name.set_text(_sp.name);
		}
		
		HBox andorBox = new HBox(false, 2);
		Label andorLabel1 = new Label("Match");
		_and_or = new ComboBox.text();
		_and_or.insert_text(0, "OR");
		_and_or.insert_text(0, "AND");
		Label andorLabel2 = new Label("of the queries:");
		andorBox.pack_start(andorLabel1, false, false, 0);
		andorBox.pack_start(_and_or, false, false, 0);
		andorBox.pack_start(andorLabel2, false, false, 0);
		
		if(_sp.conditional == "OR")
			_and_or.set_active(1);
		else
			_and_or.set_active(0);
		
		spQueries = new Gee.ArrayList<SmartPlaylistEditorQuery>();
		vertQueries = new VBox(true, 2);
		
		foreach(SmartQuery q in _sp.queries()) {
			SmartPlaylistEditorQuery speq = new SmartPlaylistEditorQuery(q);
			
			vertQueries.pack_start(speq._box, false, true, 1);
			spQueries.add(speq);
		}
		
		if(_sp.queries().size == 0) {
			addRow();
		}
		
		addButton = new Button.with_label("Add");
		vertQueries.pack_end(addButton, false, true, 1);
		addButton.clicked.connect(addButtonClick);
		
		HBox saveBox = new HBox(false, 1);
		cancel = new Button.with_label("Cancel");
		Label filler = new Label("");
		save = new Button.with_label("Save");
		saveBox.pack_start(cancel, false, false, 0);
		saveBox.pack_start(filler, false, false, 0);
		saveBox.pack_start(save, false, false, 0);
		
		save.clicked.connect(saveClick);
		
		vert.pack_start(nameBox, false, true, 1);
		vert.pack_start(andorBox, false, true, 1);
		vert.pack_start(vertQueries, false, true, 1);
		vert.pack_start(saveBox, false, false, 1);
		
		add(vert);
		
		show_all();
		
		//this.destroy.connect (Gtk.main_quit);
	}
	
	public void addRow() {
		SmartPlaylistEditorQuery speq = new SmartPlaylistEditorQuery(new SmartQuery());
		
		vertQueries.pack_start(speq._box, false, true, 1);
		spQueries.add(speq);
	}
	
	public virtual void addButtonClick() {
		addRow();
	}
	
	public virtual void saveClick() {
		_sp.clearQueries();
		foreach(SmartPlaylistEditorQuery speq in spQueries) {
			if(speq._box.visible)
				_sp.addQuery(speq.getQuery());
		}
		
		_sp.name = _name.text;
		_sp.conditional = _and_or.get_active_text();
		
		playlist_saved(_sp);
		
		this.destroy();
	}
	
}

public class BeatBox.SmartPlaylistEditorQuery : GLib.Object {
	public HBox _box;
	private ComboBox _field;
	private ComboBox _comparator;
	private Entry _value;
	private Button _remove;
	
	public HashMap<string, int> fields;
	public HashMap<string, int> comparators;
	
	public SmartPlaylistEditorQuery(SmartQuery q) {
		//TODO: ADD SUPPORT FOR REMOVING THIS. Google "removing from gtk box".
		fields = new HashMap<string, int>();
		comparators = new HashMap<string, int>();
		
		fields.set("album", 0);
		fields.set("artist", 1);
		fields.set("bitrate", 2);
		fields.set("comment", 3);
		fields.set("dateadded", 4);
		fields.set("genre", 5);
		fields.set("lastplayed", 6);
		fields.set("length", 7);
		fields.set("playcount", 8);
		fields.set("rating", 9);
		fields.set("title", 10);
		fields.set("track", 11);
		fields.set("year", 12);
		
		comparators.set("=", 0);
		comparators.set("<", 1);
		comparators.set(">", 2);
		comparators.set("LIKE", 3);
		
		_box = new HBox(false, 2);
		_field = new ComboBox.text();
		_comparator = new ComboBox.text();
		_value = new Entry();
		_remove = new Button.with_label("Remove");
		
		_field.insert_text(0, "album");
		_field.insert_text(1, "artist");
		_field.insert_text(2, "bitrate");
		_field.insert_text(3, "comment");
		_field.insert_text(4, "dateadded");
		_field.insert_text(5, "genre");
		_field.insert_text(6, "lastplayed");
		_field.insert_text(7, "length");
		_field.insert_text(8, "playcount");
		_field.insert_text(9, "rating");
		_field.insert_text(10, "title");
		_field.insert_text(11, "track");
		_field.insert_text(12, "year");
		
		_comparator.insert_text(0, "=");
		_comparator.insert_text(1, "<");
		_comparator.insert_text(2, ">");
		_comparator.insert_text(3, "LIKE");
		
		_field.set_active(fields.get(q.field));
		_comparator.set_active(comparators.get(q.comparator));
		_value.text = q.value;
		
		_box.pack_start(_field, false, true, 2);
		_box.pack_start(_comparator, false ,true, 2);
		_box.pack_start(_value, false, true, 2);
		_box.pack_start(_remove, false, true, 2);
		
		_box.show_all();
		
		_remove.clicked.connect(removeClicked);
	}
	
	public SmartQuery getQuery() {
		SmartQuery rv = new SmartQuery();
		
		rv.field = _field.get_active_text();
		rv.comparator = _comparator.get_active_text();
		rv.value = _value.text;
		
		
		return rv;
	}
	
	public virtual void removeClicked() {
		this._box.hide();
	}
}
