/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originaly Written by Scott Ringwelski for BeatBox Music Player
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

/* Merely a place holder for multiple pieces of information regarding
 * the current media playing. Mostly here because of dependence. */

public class BeatBox.PreferencesWindow : Gtk.Window {
    BeatBox.LibraryManager _lm;
    BeatBox.LibraryWindow _lw;

    Gtk.FileChooserButton library_fileChooser;
    
    Gtk.Switch organize_folders_switch;
    Gtk.Switch write_file_metadata_switch;
    Gtk.Switch copy_imported_music_switch;

    Gtk.Button saveChanges;
    
    public Granite.Widgets.StaticNotebook main_static_notebook;
    
    public signal void changed(string folder);
    
    public PreferencesWindow (LibraryManager lm, LibraryWindow lw) {
    
        this._lm = lm;
        this._lw = lw;
        
        build_ui();
        
        _lm.file_operations_done.connect(fileOperationsDone);
        
        BeatBox.plugins.hook_preferences_window (this);
    }
    
    void build_ui () {
    
        set_title(_("Preferences"));

        // Window properties
        window_position = Gtk.WindowPosition.CENTER;
        type_hint = Gdk.WindowTypeHint.DIALOG;
        set_transient_for(_lw);
        
        var main_grid = new Gtk.Grid ();
        main_static_notebook = new Granite.Widgets.StaticNotebook (false);
        saveChanges = new Gtk.Button.from_stock (Gtk.Stock.CLOSE);
        saveChanges.margin_right = 12;
        saveChanges.margin_bottom = 12;
        
        main_static_notebook.append_page (get_general_box (), new Gtk.Label (_("Behavior")));
        
        if (Peas.Engine.get_default ().get_plugin_list ().length() > 0) {
            //create static notebook
            var plugins_label = new Gtk.Label (_("Extensions"));
            
            main_static_notebook.append_page (plugins.get_view (), plugins_label);
        }
        
        main_static_notebook.set_hexpand (true);
        
        main_grid.attach (main_static_notebook, 0, 0, 3, 1);
        main_grid.attach (saveChanges, 2, 1, 1, 1);
        add (main_grid);
        
        saveChanges.clicked.connect(saveClicked);
        
        show_all();
    }
    
    Gtk.Widget get_general_box () {
        
        //BeatBox.Settings.schema.bind("show-at-start", start, "active-id", SettingsBindFlags.DEFAULT);
        
        var general_grid = new Gtk.Grid ();
        general_grid.row_spacing = 6;
        general_grid.column_spacing = 12;
        general_grid.margin_left = 12;
        general_grid.margin_right = 12;
        general_grid.margin_top = 12;
        general_grid.margin_bottom = 6;
        general_grid.set_hexpand (true);
        general_grid.set_vexpand (true);
        
        set_size_request(400, -1);
        
        var music_label = new Gtk.Label("");
        music_label.set_markup ("<b>%s</b>".printf (_("Music Folder Location")));
        music_label.set_alignment (0, 0.5f);
        
        library_fileChooser = new Gtk.FileChooserButton(_("Music Folder"), Gtk.FileChooserAction.SELECT_FOLDER);
        
        var management_label = new Gtk.Label("");
        management_label.set_markup("<b>%s</b>".printf (_("Library Management")));
        management_label.set_alignment (0, 0.5f);
        
        var organize_folders_label = new Gtk.Label (_("Keep music folder organized:"));
        organize_folders_label.set_alignment (1, 0.5f);
        organize_folders_switch = new Gtk.Switch ();
        var write_file_metadata_label = new Gtk.Label (_("Write metadata to file:"));
        write_file_metadata_label.set_alignment (1, 0.5f);
        write_file_metadata_switch = new Gtk.Switch ();
        var copy_imported_music_label = new Gtk.Label (_("Copy new files to music folder:"));
        copy_imported_music_label.set_hexpand (true);
        copy_imported_music_label.set_alignment (1, 0.5f);
        copy_imported_music_switch = new Gtk.Switch ();
        var fake_label = new Gtk.Label ("");
        fake_label.set_hexpand (true);
        
        // fancy up the category labels

        // file chooser stuff
        library_fileChooser.set_current_folder(_lw.main_settings.music_folder);
        //library_fileChooser.set_local_only(true);
        
        if (_lm.doing_file_operations()) {
            library_fileChooser.set_sensitive(false);
            library_fileChooser.set_tooltip_text(_("You must wait until previous file operations finish before setting your music folder"));
        }
        
        // initialize library management settings
        organize_folders_switch.set_active(_lw.main_settings.update_folder_hierarchy);
        write_file_metadata_switch.set_active(_lw.main_settings.write_metadata_to_file);
        copy_imported_music_switch.set_active(_lw.main_settings.copy_imported_music);
        
        // Pack all widgets
        general_grid.attach (management_label, 0, 0, 3, 1);
        general_grid.attach (library_fileChooser, 0, 1, 3, 1);
        general_grid.attach (music_label, 0, 2, 3, 1);
        general_grid.attach (organize_folders_label, 0, 3, 1, 1);
        general_grid.attach (organize_folders_switch, 1, 3, 1, 1);
        general_grid.attach (write_file_metadata_label, 0, 4, 1, 1);
        general_grid.attach (write_file_metadata_switch, 1, 4, 1, 1);
        general_grid.attach (copy_imported_music_label, 0, 5, 1, 1);
        general_grid.attach (copy_imported_music_switch, 1, 5, 1, 1);
        general_grid.attach (fake_label, 2, 5, 1, 1);
        
        return general_grid;
    }
        
    void saveClicked() {
    
        if(library_fileChooser.get_current_folder() != _lw.main_settings.music_folder || _lm.media_count() == 0) {
            changed(library_fileChooser.get_current_folder());
        }
        
        _lw.main_settings.update_folder_hierarchy = organize_folders_switch.get_active();
        _lw.main_settings.write_metadata_to_file = write_file_metadata_switch.get_active();
        _lw.main_settings.copy_imported_music = copy_imported_music_switch.get_active();
        
        destroy();
    }

    void fileOperationsDone () {
    
        library_fileChooser.set_tooltip_text("");
        library_fileChooser.set_sensitive(true);
    }
}
