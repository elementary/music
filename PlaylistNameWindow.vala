using Gtk;

public class BeatBox.PlaylistNameWindow : Window {
	public Playlist _original;
	
	public Entry _name;
	public Button _save;
	public Button _cancel;
	
	public signal void playlist_saved(Playlist p);
	
	public PlaylistNameWindow(Playlist original) {
		title = "New Playlist Name";
		
		_original = original;
		VBox vert = new VBox(false, 3);
		HBox nameSep = new HBox(false, 3);
		HBox buttonSep = new HBox(false, 3);
		//Label directions = new Label("Please enter the new playlist name");
		_name = new Entry();
		_name.text = original.name;
		Label nameLabel = new Label("Playlist Name:");
		_cancel = new Button.with_label("Cancel");
		Label fillerLabel = new Label("");
		_save = new Button.with_label("Save");
		
		_cancel.clicked.connect( () => { this.destroy(); } );
		_save.clicked.connect(saveClicked);
		
		nameSep.pack_start(nameLabel, false, false, 5);
		nameSep.pack_start(_name, false, true, 2);
		
		buttonSep.pack_start(_cancel, false, false, 0);
		buttonSep.pack_start(fillerLabel, true, true, 0);
		buttonSep.pack_start(_save, false, false, 0);
		
		//vert.pack_start(directions, false, true, 5);
		vert.pack_start(nameSep, false, true, 5);
		vert.pack_start(buttonSep, false, true, 5);
		
		add(vert);
		
		show_all();
	}
	
	public virtual void saveClicked() {
		_original.name = _name.text;
		
		playlist_saved(_original);
		
		this.destroy();
	}
}
