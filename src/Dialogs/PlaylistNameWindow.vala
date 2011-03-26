using Gtk;

public class BeatBox.PlaylistNameWindow : Window {
	public Playlist _original;
	
	VBox content;
	HBox padding;
	
	public Entry _name;
	public Button _save;
	
	public signal void playlist_saved(Playlist p);
	
	public PlaylistNameWindow(LibraryWindow lw, Playlist original) {
		title = "Playlist Editor";
		
		this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(lw);
		this.destroy_with_parent = true;
		//this.type = WindowType.POPUP;
		
		_original = original;
		
		content = new VBox(false, 10);
		padding = new HBox(false, 10);
		
		/* start out by creating all category labels */
		Label nameLabel = new Label("Name of Playlist");
		_name = new Entry();
		_save = new Button.with_label("Done");
		
		/* set up controls */
		nameLabel.xalign = 0.0f;
		nameLabel.set_markup("<b>Name of Playlist</b>");
		
		_name.text = original.name;
		
		/* add controls to form */
		HButtonBox bottomButtons = new HButtonBox();
		bottomButtons.set_layout(ButtonBoxStyle.END);
		bottomButtons.pack_end(_save, false, false, 0);
		
		content.pack_start(wrap_alignment(nameLabel, 10, 0, 0, 0), false, true, 0);
		content.pack_start(wrap_alignment(_name, 0, 10, 0, 10), false, true, 0);
		content.pack_start(bottomButtons, false, false, 10);
		
		padding.pack_start(content, true, true, 10);
		
		add(padding);
		
		show_all();
		
		_save.clicked.connect(saveClicked);
		_name.activate.connect(nameActivate);
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
	
	public virtual void saveClicked() {
		_original.name = _name.text;
		playlist_saved(_original);
		
		this.destroy();
	}
	
	public virtual void nameActivate() {
		saveClicked();
	}
}
