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

    /**
     * A section in the preferences dialog. Each section has a page in the window's
     * notebook containing @container. SubSections can be added to the page through
     * the add_subsection() method.
     *
     * When the preferences' window save button is clicked, save_changes() is called for
     * every section.
     */
    public class NoteBook_Page {
        public string name { get; private set; }
        public Gtk.Grid grid { get; private set; }

        private static const int IDENTATION_MARGIN = 12;

        public NoteBook_Page (string name) {
            this.name = name;

            grid = new Gtk.Grid ();
            grid.margin = 12;
            grid.set_hexpand (true);
            grid.set_column_spacing (12);
            grid.set_row_spacing (6);
        }

        /**
         * Appends a subsection. Its main purpose is to allow easier addition of
         * subsections to a normal Section. This makes it easy to maintain a
         * consistent look through all the different preferences sections
         * (even those added by plugins, etc.)
         */
        
        public void add_section (Gtk.Label name, ref int row) {
            name.use_markup = true;
            name.set_markup ("<b>%s</b>".printf (name.get_text ()));
            name.halign = Gtk.Align.START;
            grid.attach (name, 0, row, 1, 1);
            row ++;
        }
        
        public void add_option (Gtk.Widget label, Gtk.Widget switcher, ref int row) {
            label.set_hexpand (true);
            label.set_halign (Gtk.Align.END);
            label.set_margin_left (20);
            switcher.set_halign (Gtk.Align.FILL);
            switcher.set_hexpand (true);
            
            if (switcher is Gtk.Switch || switcher is Gtk.CheckButton
                || switcher is Gtk.Entry) { /* then we don't want it to be expanded */
                switcher.halign = Gtk.Align.START;
            }
            
            grid.attach (label, 0, row, 1, 1);
            grid.attach (switcher, 1, row, 3, 1);
            row ++;
        }
        
        public void add_full_option (Gtk.Widget big_widget, ref int row) {
            big_widget.set_halign (Gtk.Align.FILL);
            big_widget.set_hexpand (true);
            big_widget.set_margin_left (20);
            big_widget.set_margin_right (20);
            
            grid.attach (big_widget, 0, row, 4, 1);
            row ++;
        }
    }

    private Gee.Map<int, NoteBook_Page> sections = new Gee.HashMap<int, NoteBook_Page> ();
    private Granite.Widgets.StaticNotebook main_static_notebook;
    public Gtk.FileChooserButton library_filechooser;

    public PreferencesWindow (LibraryWindow lw) {
        build_ui (lw);

        // Add general section
        library_filechooser = new Gtk.FileChooserButton (_("Select Music Folder..."), Gtk.FileChooserAction.SELECT_FOLDER);
        library_filechooser.hexpand = true;

        library_filechooser.set_current_folder (main_settings.music_folder);
        //library_filechooser.set_local_only (true);
        var general_section = new Preferences.GeneralPage (library_filechooser);
        library_filechooser.file_set.connect (() => {lw.setMusicFolder(library_filechooser.get_current_folder ());});
        add_page (general_section.page);

        plugins.hook_preferences_window (this);

    }


    public int add_page (NoteBook_Page section) {
        return_val_if_fail (section.grid != null, -1);

        // Pack the section
        // TODO: file a bug against granite's static notebook: append_page()
        // should return the index of the new page.
        main_static_notebook.append_page (section.grid, new Gtk.Label (section.name));
        int index = sections.size;
        sections.set (index, section);

        section.grid.show_all ();

        return index;
    }


    public void remove_section (int index) {
        main_static_notebook.remove_page (index);
        sections.unset (index);
    }


    private void build_ui (Gtk.Window parent_window) {
        set_size_request (MIN_WIDTH, MIN_HEIGHT);

        // Window properties
        title = _("Preferences");
        resizable = false;
        window_position = Gtk.WindowPosition.CENTER;
        type_hint = Gdk.WindowTypeHint.DIALOG;
        transient_for = parent_window;

        main_static_notebook = new Granite.Widgets.StaticNotebook (false);
        main_static_notebook.hexpand = true;
        main_static_notebook.margin_bottom = 24;

        ((Gtk.Box)get_content_area()).add (main_static_notebook);
        add_button (Gtk.Stock.CLOSE, Gtk.ResponseType.ACCEPT);
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
    public Noise.PreferencesWindow.NoteBook_Page page;

#if HAVE_LIBNOTIFY
    private Gtk.Switch show_notifications_switch;
#endif

    public GeneralPage (Gtk.FileChooserButton library_filechooser) {

        page = new Noise.PreferencesWindow.NoteBook_Page (_("General"));

        int row = 0;
        
        // Music Folder Location
        
        var label = new Gtk.Label (_("Music Folder Location:"));
        page.add_section (label, ref row);
        
        var spacer = new Gtk.Label ("");
        spacer.set_hexpand (true);

        page.add_full_option (library_filechooser, ref row);
        
        label = new Gtk.Label (_("Library Management:"));
        page.add_section (label, ref row);
        
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
        
#if HAVE_LIBNOTIFY
        show_notifications_switch = new Gtk.Switch ();
        main_settings.schema.bind("show-notifications", show_notifications_switch, "active", SettingsBindFlags.DEFAULT);
        page.add_option (new Gtk.Label (_("Show notifications:")), show_notifications_switch, ref row);
#endif

        string hide_on_close_desc;
        if (LibraryWindow.minimize_on_close ())
            hide_on_close_desc = _("Minimize window when a song is being played:");
        else
            hide_on_close_desc = _("Hide window when a song is being played:");

        hide_on_close_switch = new Gtk.Switch ();
        main_settings.schema.bind("close-while-playing", hide_on_close_switch, "active", SettingsBindFlags.INVERT_BOOLEAN);
        page.add_option (new Gtk.Label (hide_on_close_desc), hide_on_close_switch, ref row);
        
    }
}
