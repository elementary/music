using Gtk;
using Gee;

public class BeatBox.SmartPlaylistEditor : Window {
	SmartPlaylist _sp;
	
	VBox vert;
	Entry _name;
	ComboBox _and_or;
	VBox vertQueries;
	Button save;
	Button addButton;
	Gee.ArrayList<SmartPlaylistEditorQuery> spQueries;
	
	public signal void playlist_saved(SmartPlaylist sp);
	
	public SmartPlaylistEditor(SmartPlaylist sp) {
		_sp = sp;
		
		vert = new VBox(false, 10);
		
		_name = new Entry();
		
		if(_sp.name != "")
			_name.text = _sp.name;
		
		_and_or = new ComboBox.text();
		_and_or.insert_text(0, "OR");
		_and_or.insert_text(0, "AND");
		
		if(_sp.conditional == "OR")
			_and_or.set_active(1);
		else
			_and_or.set_active(0);
		
		spQueries = new Gee.ArrayList<SmartPlaylistEditorQuery>();
		vertQueries = new VBox(true, 2);
		foreach(SmartQuery q in _sp.queries()) {
			SmartPlaylistEditorQuery speq = new SmartPlaylistEditorQuery(q);
			HBox box = new HBox(false, 2);
			
			box.pack_start(speq._field, false, true, 2);
			box.pack_start(speq._comparator, false ,true, 2);
			box.pack_start(speq._value, false, true, 2);
			box.pack_start(speq._remove, false, true, 2);
			
			vertQueries.pack_end(box, false, true, 1);
			spQueries.add(speq);
		}
		
		if(_sp.queries().size == 0) {
			addRow();
		}
		
		addButton = new Button.with_label("Add");
		vertQueries.pack_end(addButton, false, true, 1);
		addButton.clicked.connect(addButtonClick);
		
		save = new Button.with_label("Save");
		save.clicked.connect(saveClick);
		
		vert.pack_start(_name, false, true, 1);
		vert.pack_start(_and_or, false, true, 1);
		vert.pack_start(vertQueries, false, true, 1);
		vert.pack_start(save, false, false, 1);
		
		add(vert);
		
		show_all();
		
		//this.destroy.connect (Gtk.main_quit);
	}
	
	public void addRow() {
		SmartPlaylistEditorQuery speq = new SmartPlaylistEditorQuery(new SmartQuery());
		HBox box = new HBox(false, 2);
			
		box.pack_start(speq._field, false, true, 2);
		box.pack_start(speq._comparator, false ,true, 2);
		box.pack_start(speq._value, false, true, 2);
		box.pack_start(speq._remove, false, true, 2);
		
		box.show_all();
		vertQueries.pack_start(box, false, true, 1);
		spQueries.add(speq);
	}
	
	public virtual void addButtonClick() {
		addRow();
	}
	
	public virtual void saveClick() {
		_sp.clearQueries();
		foreach(SmartPlaylistEditorQuery speq in spQueries) {
			_sp.addQuery(speq.getQuery());
			
		}
		
		_sp.name = _name.text;
		_sp.conditional = _and_or.get_active_text();
		
		playlist_saved(_sp);
		
		this.destroy();
	}
	
}

public class BeatBox.SmartPlaylistEditorQuery : GLib.Object {
	public ComboBox _field;
	public ComboBox _comparator;
	public Entry _value;
	public Button _remove;
	
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
	}
	
	public SmartQuery getQuery() {
		SmartQuery rv = new SmartQuery();
		
		rv.field = _field.get_active_text();
		rv.comparator = _comparator.get_active_text();
		rv.value = _value.text;
		
		
		return rv;
	}
}
