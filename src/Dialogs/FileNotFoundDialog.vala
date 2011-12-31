using Gtk;
using Gee;

public class BeatBox.FileNotFoundDialog : Window {
	LibraryManager lm;
	LibraryWindow lw;
	int song_id;
	
	private VBox content;
	private HBox padding;
	
	Button removeSong;
	Button locateSong;
	Button rescanLibrary;
	Button doNothing;
	
	public FileNotFoundDialog(LibraryManager lm, LibraryWindow lw, int id) {
		this.lm = lm;
		this.lw = lw;
		song_id = id;
		
		Song s = lm.song_from_id(song_id);
		
		this.set_title("BeatBox");
		
		// set the size based on saved gconf settings
		//this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(lw);
		this.destroy_with_parent = true;
		
		set_default_size(475, -1);
		resizable = false;
		
		content = new VBox(false, 10);
		padding = new HBox(false, 20);
		
		// initialize controls
		Image warning = new Image.from_stock(Gtk.Stock.DIALOG_ERROR, Gtk.IconSize.DIALOG);
		Label title = new Label("");
		Label info = new Label("");
		removeSong = new Button.with_label("Remove Song");
		locateSong = new Button.with_label("Locate Song");
		rescanLibrary = new Button.with_label("Rescan Library");
		doNothing = new Button.with_label("Do Nothing");
		
		// pretty up labels
		title.xalign = 0.0f;
		title.set_markup("<span weight=\"bold\" size=\"larger\">Could not find music file</span>");
		info.xalign = 0.0f;
		info.set_line_wrap(false);
		info.set_markup("The music file for <b>" + s.title.replace("&", "&amp;") + "</b> by <b>" + s.artist.replace("&", "&amp;") + "</b> could not be found. What would you like to do?");
		
		rescanLibrary.set_sensitive(!lm.doing_file_operations());
		
		/* set up controls layout */
		HBox information = new HBox(false, 0);
		VBox information_text = new VBox(false, 0);
		information.pack_start(warning, false, false, 10);
		information_text.pack_start(title, false, true, 10);
		information_text.pack_start(info, false, true, 0);
		information.pack_start(information_text, true, true, 10);
		
		HButtonBox bottomButtons = new HButtonBox();
		bottomButtons.set_layout(ButtonBoxStyle.END);
		bottomButtons.pack_end(removeSong, false, false, 0);
		bottomButtons.pack_end(rescanLibrary, false, false, 0);
		bottomButtons.pack_end(locateSong, false, false, 0);
		bottomButtons.pack_end(doNothing, false, false, 10);
		bottomButtons.set_spacing(10);
		
		content.pack_start(information, false, true, 0);
		content.pack_start(bottomButtons, false, true, 10);
		
		padding.pack_start(content, true, true, 10);
		
		removeSong.clicked.connect(removeSongClicked);
		locateSong.clicked.connect(locateSongClicked);
		rescanLibrary.clicked.connect(rescanLibraryClicked);
		doNothing.clicked.connect( () => { 
			this.destroy(); 
		});
		
		lm.file_operations_started.connect(file_operations_started);
		lm.file_operations_done.connect(file_operations_done);
		
		add(padding);
		show_all();
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
	
	public void removeSongClicked() {
		var temp = new LinkedList<Song>();
		temp.add(lm.song_from_id(song_id));
		lm.remove_songs(temp, false);
		
		this.destroy();
	}
	
	public void locateSongClicked() {
		string file = "";
		var file_chooser = new FileChooserDialog ("Choose Music Folder", this,
								  FileChooserAction.OPEN,
								  Gtk.Stock.CANCEL, ResponseType.CANCEL,
								  Gtk.Stock.OPEN, ResponseType.ACCEPT);
		
		// try and help user by setting a sane default folder
		var invalid_file = File.new_for_path(lm.song_from_id(song_id).file);
		
		if(invalid_file.get_parent().query_exists())
			file_chooser.set_current_folder(invalid_file.get_parent().get_path());
		else if(invalid_file.get_parent().get_parent().query_exists() && 
		invalid_file.get_parent().get_parent().get_path().contains(lm.settings.getMusicFolder()))
			file_chooser.set_current_folder(invalid_file.get_parent().get_parent().get_path());
		else if(File.new_for_path(lm.settings.getMusicFolder()).query_exists())
			file_chooser.set_current_folder(lm.settings.getMusicFolder());
		else
			file_chooser.set_current_folder(Environment.get_home_dir());
		
		if (file_chooser.run () == ResponseType.ACCEPT) {
			file = file_chooser.get_filename();
		}
		
		file_chooser.destroy ();
		
		if(file != "") {
			lm.song_from_id(song_id).file = file;
			lm.update_song(lm.song_from_id(song_id), false, false);
			
			this.destroy();
		}
	}
	
	public void rescanLibraryClicked() {
		lw.fileRescanMusicFolderClick();
		
		this.destroy();
	}
	
	public void file_operations_done() {
		rescanLibrary.set_sensitive(true);
	}
	
	public void file_operations_started() {
		rescanLibrary.set_sensitive(false);
	}
	
}
