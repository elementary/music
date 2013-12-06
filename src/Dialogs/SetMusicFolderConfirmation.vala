/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

using Gtk;
using Gee;

public class Noise.SetMusicFolderConfirmation : Window {
	string folder_path;
	
	private Box content;
	private Box padding;
	
	Button savePlaylists;
	Button ok;
	Button cancel;
	
	Gtk.Image is_finished;
	Gtk.Spinner is_working;
	
	public signal void finished(bool response);
	
	public SetMusicFolderConfirmation(string path) {
		folder_path = path;
		
		// set the size based on saved gconf settings
		//this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal (true);
		this.set_transient_for (App.main_window);
		this.destroy_with_parent = true;
		
		//set_default_size(250, -1);
		resizable = false;
		
		content = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
		padding = new Gtk.Box(Gtk.Orientation.HORIZONTAL,  20);
		
		// initialize controls
		Image warning = new Image.from_icon_name ("dialog-warning", Gtk.IconSize.DIALOG);
		Label title = new Label("");
		Label info = new Label("");
		savePlaylists = new Button.with_label(_("Export Playlists"));
		ok = new Button.with_label(_("Set Music Folder"));
		cancel = new Button.from_stock ("dialog-cancel");
		is_finished = new Gtk.Image();
		is_working = new Gtk.Spinner();
		
		// pretty up labels
		title.xalign = 0.0f;
		title.set_markup("<span weight=\"bold\" size=\"larger\">%s</span>".printf(String.escape (_("Set Music Folder?"))));
		info.xalign = 0.0f;
		info.set_line_wrap(true);
		info.set_markup (_("Are you sure you want to set the music folder to %s? This will reset your library and remove your playlists.").printf ("<b>" + String.escape (path) + "</b>"));

		/* set up controls layout */
		var information = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		var information_text = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		information.pack_start(warning, false, false, 10);
		information_text.pack_start(title, false, true, 10);
		information_text.pack_start(info, false, true, 0);
		information.pack_start(information_text, true, true, 10);
		
		// save playlist hbox
		var playlistBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
		playlistBox.pack_start(savePlaylists, true, true, 0);
		playlistBox.pack_end(is_finished, false, false, 0);
		playlistBox.pack_end(is_working, false, false, 0);
		
		var bottomButtons = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
		bottomButtons.set_layout(Gtk.ButtonBoxStyle.END);
		bottomButtons.pack_start(playlistBox, false, false, 0);
		bottomButtons.pack_end(cancel, false, false, 0);
		bottomButtons.pack_end(ok, false, false, 0);
		bottomButtons.set_spacing(10);
		
		((Gtk.ButtonBox)bottomButtons).set_child_secondary(playlistBox, true);
		
		content.pack_start(information, false, true, 0);
		content.pack_start(bottomButtons, false, true, 10);
		
		padding.pack_start(content, true, true, 10);
		
		savePlaylists.set_sensitive(!libraries_manager.local_library.get_medias ().is_empty && libraries_manager.local_library.playlist_count_without_read_only () > 0);
		
		savePlaylists.clicked.connect(savePlaylistsClicked);
		cancel.clicked.connect(cancel_clicked);
		ok.clicked.connect(ok_clicked);
		
		add(padding);
		show_all();
		
		is_working.hide();
	}
	
	public void savePlaylistsClicked() {
		string folder = "";
		var file_chooser = new FileChooserDialog (_("Choose Music Folder"), this,
								  FileChooserAction.SELECT_FOLDER,
								  "dialog-cancel", ResponseType.CANCEL,
								  "document-open", ResponseType.ACCEPT);
		if (file_chooser.run () == ResponseType.ACCEPT) {
			folder = file_chooser.get_filename();
		}
		
		file_chooser.destroy ();
		
		if(folder != "") {
			is_working.show();
			is_finished.hide();
			
			// foreach playlist in lm.playlists(), save to (p.name).m3u
			var success = true;
			foreach(var p in libraries_manager.local_library.get_playlists()) {
				if(!Noise.PlaylistsUtils.save_playlist_m3u(p, folder, ""))
					success = false;
			}
			
			is_working.hide();
			is_finished.show();
			
			var process_completed_icon = Icons.PROCESS_COMPLETED.render (IconSize.MENU);
			var process_error_icon = Icons.PROCESS_ERROR.render (IconSize.MENU);
			
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
