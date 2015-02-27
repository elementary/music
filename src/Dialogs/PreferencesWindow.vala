// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
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
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 */

public class Noise.PreferencesWindow : Gtk.Dialog {

    public const int MIN_WIDTH = 420;
    public const int MIN_HEIGHT = 300;

    public Gtk.FileChooserButton library_filechooser;

    private Gee.Map<int, unowned Noise.SettingsWindow.NoteBook_Page> sections = new Gee.HashMap<int, unowned Noise.SettingsWindow.NoteBook_Page> ();
    private Gtk.Stack main_stack;
    private Gtk.StackSwitcher main_stackswitcher;
    private int index = 0;

    public PreferencesWindow () {
        build_ui ();
        App.main_window.add_preference_page.connect ((page) => {add_page (page);});
        
        // Add general section
        library_filechooser = new Gtk.FileChooserButton (_("Select Music Folder…"), Gtk.FileChooserAction.SELECT_FOLDER);
        library_filechooser.hexpand = true;

        library_filechooser.set_current_folder (Settings.Main.get_default ().music_folder);
        //library_filechooser.set_local_only (true);
        var general_section = new Preferences.GeneralPage (library_filechooser);
        library_filechooser.file_set.connect (() => {App.main_window.setMusicFolder(library_filechooser.get_current_folder ());});
        add_page (general_section.page);

        Plugins.Manager.get_default ().hook_preferences_window (this);
    }


    public int add_page (Noise.SettingsWindow.NoteBook_Page section) {
        return_val_if_fail (section != null, -1);

        // Pack the section
        main_stack.add_titled (section, "%d".printf (index), section.name);
        sections.set (index, section);
        index++;

        section.show_all ();

        return index;
    }

    public void remove_section (int index) {
        var section = sections.get (index);
        section.destroy ();
        sections.unset (index);
    }

    private void build_ui () {
        // Window properties
        title = _("Preferences");
        set_size_request (MIN_WIDTH, MIN_HEIGHT);
        resizable = false;
        deletable = false;
        destroy_with_parent = true;
        window_position = Gtk.WindowPosition.CENTER;
        set_transient_for (App.main_window);

        main_stack = new Gtk.Stack ();
        main_stackswitcher = new Gtk.StackSwitcher ();
        main_stackswitcher.set_stack (main_stack);
        main_stackswitcher.halign = Gtk.Align.CENTER;

        var close_button = new Gtk.Button.with_label (_("Close"));
        close_button.clicked.connect (() => {this.destroy ();});

        var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_box.set_layout (Gtk.ButtonBoxStyle.END);
        button_box.pack_end (close_button);
        button_box.margin_right = 12;

        // Pack everything into the dialog
        Gtk.Grid main_grid = new Gtk.Grid ();
        main_grid.attach (main_stackswitcher, 0, 0, 1, 1);
        main_grid.attach (main_stack, 0, 1, 1, 1);
        main_grid.attach (button_box, 0, 2, 1, 1);

        ((Gtk.Container) get_content_area ()).add (main_grid);
    }
}


/**
 * General preferences section
 */
private class Noise.Preferences.GeneralPage {

    private Gtk.Switch organize_folders_switch;
    private Gtk.Switch write_file_metadata_switch;
    private Gtk.Switch copy_imported_music_switch;
    private Gtk.Switch hide_on_close_switch;
    public Noise.SettingsWindow.NoteBook_Page page;

    public GeneralPage (Gtk.FileChooserButton library_filechooser) {

        page = new Noise.SettingsWindow.NoteBook_Page (_("General"));

        int row = 0;
        
        // Music Folder Location
        
        var label = new Gtk.Label (_("Music Folder Location:"));
        page.add_section (label, ref row);
        
        var spacer = new Gtk.Label ("");
        spacer.set_hexpand (true);

        page.add_full_option (library_filechooser, ref row);
        
        label = new Gtk.Label (_("Library Management:"));
        page.add_section (label, ref row);
        
        var main_settings = Settings.Main.get_default ();
        
        organize_folders_switch = new Gtk.Switch ();
        main_settings.schema.bind("update-folder-hierarchy", organize_folders_switch, "active", SettingsBindFlags.DEFAULT);
        page.add_option (new Gtk.Label (_("Keep Music folder organized:")), organize_folders_switch, ref row);
        
        write_file_metadata_switch = new Gtk.Switch ();
        main_settings.schema.bind("write-metadata-to-file", write_file_metadata_switch, "active", SettingsBindFlags.DEFAULT);
        page.add_option (new Gtk.Label (_("Write metadata to file:")), write_file_metadata_switch, ref row);
        
        copy_imported_music_switch = new Gtk.Switch ();
        main_settings.schema.bind("copy-imported-music", copy_imported_music_switch, "active", SettingsBindFlags.DEFAULT);
        page.add_option (new Gtk.Label (_("Copy imported files to Library:")), copy_imported_music_switch, ref row);
        
        label = new Gtk.Label (_("Desktop Integration:"));
        page.add_section (label, ref row);

        hide_on_close_switch = new Gtk.Switch ();
        main_settings.schema.bind("close-while-playing", hide_on_close_switch, "active", SettingsBindFlags.INVERT_BOOLEAN);
        page.add_option (new Gtk.Label (_("Continue playback when closed:")), hide_on_close_switch, ref row);
        
    }
}
