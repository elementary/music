using Gtk;
using Gee;

public class BeatBox.SetMusicFolderConfirmation : Window {
	LibraryManager lm;
	LibraryWindow lw;
	string folder_path;
	
	private VBox content;
	private HBox padding;
	
	Button savePlaylists;
	Button ok;
	Button cancel;
	
	Gtk.Image is_finished;
	Gtk.Spinner is_working;
	
	public signal void finished(bool response);
	
	public SetMusicFolderConfirmation(LibraryManager lm, LibraryWindow lw, string path) {
		this.lm = lm;
		this.lw = lw;
		folder_path = path;
		
		this.set_title("BeatBox");
		
		// set the size based on saved gconf settings
		//this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(lw);
		this.destroy_with_parent = true;
		
		//set_default_size(250, -1);
		resizable = false;
		
		content = new VBox(false, 10);
		padding = new HBox(false, 20);
		
		// initialize controls
		Image warning = new Image.from_stock(Gtk.Stock.DIALOG_WARNING, Gtk.IconSize.DIALOG);
		Label title = new Label("");
		Label info = new Label("");
		savePlaylists = new Button.with_label(_("Export Playlists"));
		ok = new Button.with_label(_("Set Music Folder"));
		cancel = new Button.with_label(_("Cancel"));
		is_finished = new Gtk.Image();
		is_working = new Gtk.Spinner();
		
		// pretty up labels
		title.xalign = 0.0f;
		title.set_markup("<span weight=\"bold\" size=\"larger\">%s</span>".printf(_("Set Music Folder?")));
		info.xalign = 0.0f;
		info.set_line_wrap(true);
		info.set_markup("Are you sure you want to set the music folder to <b>" + path.replace("&", "&amp;") + "</b>? This will reset your library and remove static playlists.");
		
		/* set up controls layout */
		HBox information = new HBox(false, 0);
		VBox information_text = new VBox(false, 0);
		information.pack_start(warning, false, false, 10);
		information_text.pack_start(title, false, true, 10);
		information_text.pack_start(info, false, true, 0);
		information.pack_start(information_text, true, true, 10);
		
		// save playlist hbox
		HBox playlistBox = new HBox(false, 6);
		playlistBox.pack_start(savePlaylists, true, true, 0);
		playlistBox.pack_end(is_finished, false, false, 0);
		playlistBox.pack_end(is_working, false, false, 0);
		
		HButtonBox bottomButtons = new HButtonBox();
		bottomButtons.set_layout(ButtonBoxStyle.END);
		bottomButtons.pack_start(playlistBox, false, false, 0);
		bottomButtons.pack_end(cancel, false, false, 0);
		bottomButtons.pack_end(ok, false, false, 0);
		bottomButtons.set_spacing(10);
		
		((Gtk.ButtonBox)bottomButtons).set_child_secondary(playlistBox, true);
		
		content.pack_start(information, false, true, 0);
		content.pack_start(bottomButtons, false, true, 10);
		
		padding.pack_start(content, true, true, 10);
		
		savePlaylists.set_sensitive(lm.media_count() > 0 && lm.playlist_count() > 0);
		
		savePlaylists.clicked.connect(savePlaylistsClicked);
		cancel.clicked.connect(cancel_clicked);
		ok.clicked.connect(ok_clicked);
		
		add(padding);
		show_all();
		
		is_working.hide();
	}
	
	public void savePlaylistsClicked() {
		string folder = "";
		var file_chooser = new FileChooserDialog ("Choose Music Folder", this,
								  FileChooserAction.SELECT_FOLDER,
								  Gtk.Stock.CANCEL, ResponseType.CANCEL,
								  Gtk.Stock.OPEN, ResponseType.ACCEPT);
		if (file_chooser.run () == ResponseType.ACCEPT) {
			folder = file_chooser.get_filename();
		}
		
		file_chooser.destroy ();
		
		if(folder != "") {
			is_working.show();
			is_finished.hide();
			
			// foreach playlist in lm.playlists(), save to (p.name).m3u
			var success = true;
			foreach(var p in lm.playlists()) {
				if(!p.save_playlist_m3u(lm, folder))
					success = false;
			}
			
			is_working.hide();
			is_finished.show();
			
			var process_completed_icon = Icons.PROCESS_COMPLETED_ICON.render (IconSize.MENU);
			var process_error_icon = Icons.PROCESS_ERROR_ICON.render (IconSize.MENU);
			
			is_finished.set_from_pixbuf(success ? process_completed_icon : process_error_icon);
		}
	}
	
	public void cancel_clicked() {
		finished(false);
		
		this.destroy();
	}
	
	public void ok_clicked() {
		finished(true);
		
		this.destroy();
	}
}
