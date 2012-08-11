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

public class Noise.PreferencesWindow : Gtk.Window {

    public const int WINDOW_WIDTH = 420;

    /**
     * A section in the preferences dialog. Each section has a page in the window's
     * notebook containing @container. SubSections can be added to the page through
     * the add_subsection() method.
     *
     * When the preferences' window save button is clicked, save_changes() is called for
     * every section.
     */
    public class Section {
        public string name { get; private set; }
        public Gtk.Grid container { get; private set; }

        private static const int IDENTATION_MARGIN = 12;

        public Section (string name) {
            this.name = name;

            container = new Gtk.Grid ();
            container.margin_bottom = 12;
            container.orientation = Gtk.Orientation.VERTICAL;
            container.row_homogeneous = false;
            container.hexpand = true;
        }

        /**
         * Appends a subsection. Its main purpose is to allow easier addition of
         * subsections to a normal Section. This makes it easy to maintain a
         * consistent look through all the different preferences sections
         * (even those added by plugins, etc.)
         */
        public void add_subsection (string title, Gtk.Container contents) {
            var subsection_title_label = new Gtk.Label (null);
            subsection_title_label.set_markup (Markup.printf_escaped ("<b>%s</b>", title));
            subsection_title_label.set_alignment (0.0f, 0.5f);
            subsection_title_label.margin_top = 12;
            subsection_title_label.margin_bottom = 6;

            container.add (subsection_title_label);

            if (contents != null) {
                contents.hexpand = true;
                contents.margin_left = IDENTATION_MARGIN;
                container.add (contents);
            }
        }

        /**
         * Not abstract since some sections may save their preferences in real time.
         * Return false to prevent the window from being closed.
         *
         * @return whether the preferences window can be closed
         */
        public virtual bool save_changes () {
            return true;
        }
    }


    // XXX: deprecate. This should be part of Noise.Preferences.GeneralSection
    public signal void changed (string folder);


    private Gee.Map<int, Section> sections = new Gee.HashMap<int, Section> ();
    private Gtk.Button save_button;
    private Granite.Widgets.StaticNotebook main_static_notebook;


    // TODO: don't receive the library manager parameter. Each library manager should register
    //       its own section and pass the parameters directly to that section.
    public PreferencesWindow (LibraryManager lm, LibraryWindow lw) {
        build_ui (lw);

        // Add general section
        var general_section = new Preferences.GeneralSection (lm, lw);
        add_section (general_section);

        general_section.changed.connect ( (folder) => changed (folder) );

        Noise.App.plugins.hook_preferences_window (this);

        // TODO: this should be called by the window's creator
        show_all ();
    }


    public int add_section (Section section) {
        return_val_if_fail (section.container != null, -1);

        // Pack the section
        // TODO: file a bug against granite's static notebook: append_page()
        // should return the index of the new page.
        main_static_notebook.append_page (section.container, new Gtk.Label (section.name));
        int index = sections.size;
        sections.set (index, section);

        section.container.show_all ();

        return index;
    }


    public void remove_section (int index) {
        main_static_notebook.remove_page (index);
        sections.unset (index);
    }


    private void build_ui (Gtk.Window parent_window) {
        set_size_request (WINDOW_WIDTH, -1);
        set_default_size (WINDOW_WIDTH, -1);

        // Window properties
        title = _("Preferences");
        resizable = false;
        window_position = Gtk.WindowPosition.CENTER;
        type_hint = Gdk.WindowTypeHint.DIALOG;
        transient_for = parent_window;
        modal = true;

        save_button = new Gtk.Button.with_label (_("Done"));
        save_button.halign = Gtk.Align.END;
        save_button.set_size_request (90, -1);
        save_button.clicked.connect (on_save_button_clicked);

        main_static_notebook = new Granite.Widgets.StaticNotebook (false);
        main_static_notebook.hexpand = true;
        main_static_notebook.margin_bottom = 24;

        var main_grid = new Gtk.Grid ();
        main_grid.margin = 12;
        main_grid.attach (main_static_notebook, 0, 0, 1, 1);
        main_grid.attach (save_button, 0, 1, 1, 1);

        // Use a fixedbin widget so that we're always in control of the window size
        var size_wrapper = new FixedBin (WINDOW_WIDTH, -1, WINDOW_WIDTH, -1);
        size_wrapper.set_widget (main_grid);

        add (size_wrapper);
    }


    private void on_save_button_clicked () {
        foreach (var section in sections.values) {
            if (section != null && !section.save_changes ())
                return;
        }

        destroy ();
    }
}


/**
 * General preferences section
 */
private class Noise.Preferences.GeneralSection : Noise.PreferencesWindow.Section {
    public signal void changed (string folder);

    private LibraryWindow lw;
    private LibraryManager lm;

    private Gtk.CheckButton organize_folders_toggle;
    private Gtk.CheckButton write_file_metadata_toggle;
    private Gtk.CheckButton copy_imported_music_toggle;

    private Gtk.CheckButton is_default_application_toggle;

    private Gtk.FileChooserButton library_filechooser;


    public GeneralSection (LibraryManager lm, LibraryWindow lw) {
        base (_("General"));

        this.lm = lm;
        this.lw = lw;

        add_library_folder_section ();
        add_library_management_section ();
        add_default_application_section ();
    }


    private void add_library_folder_section () {
        library_filechooser = new Gtk.FileChooserButton (_("Select Music Folder"),
                                                         Gtk.FileChooserAction.SELECT_FOLDER);
        library_filechooser.hexpand = true;

        var folder_contents = new Gtk.Grid ();
        folder_contents.add (library_filechooser);

        add_subsection (_("Music Folder Location"), folder_contents);

        library_filechooser.set_current_folder (Settings.Main.instance.music_folder);

        if (lm.doing_file_operations ()) {
            library_filechooser.set_sensitive (false);
            library_filechooser.set_tooltip_text (_("You must wait until previous file operations finish before setting your music folder"));

            // Keep checking until the current file operations finish
            lm.file_operations_done.connect ( () =>  {
                library_filechooser.set_tooltip_text ("");
                library_filechooser.set_sensitive (true);
            });
        }
    }


    private void add_library_management_section () {
        organize_folders_toggle = new Gtk.CheckButton.with_label (_("Keep Music folder organized"));
        copy_imported_music_toggle = new Gtk.CheckButton.with_label (_("Copy files to Music folder when adding to Library"));
        // TODO: DEPRECATE
        write_file_metadata_toggle = new Gtk.CheckButton.with_label (_("Write metadata to file"));

        // initialize library management settings
        organize_folders_toggle.set_active(Settings.Main.instance.update_folder_hierarchy);
        write_file_metadata_toggle.set_active(Settings.Main.instance.write_metadata_to_file);
        copy_imported_music_toggle.set_active(Settings.Main.instance.copy_imported_music);

        var contents_grid = new Gtk.Grid ();
        contents_grid.row_spacing = 6;
        contents_grid.column_spacing = 6;

        contents_grid.attach (organize_folders_toggle,    0, 0, 1, 1);
        contents_grid.attach (copy_imported_music_toggle, 0, 1, 1, 1);
        contents_grid.attach (write_file_metadata_toggle, 0, 2, 1, 1);

        add_subsection (_("Library Management"), contents_grid);
    }


    private void add_default_application_section () {
        var contents_grid = new Gtk.Grid ();

        is_default_application_toggle = new Gtk.CheckButton.with_label (_("Use Noise as the default Music application"));
        is_default_application_toggle.set_active (Noise.App.instance.is_default_application);

        contents_grid.add (is_default_application_toggle);

        add_subsection (_("System Integration"), contents_grid);
    }


    public override bool save_changes () {
        if (library_filechooser.get_current_folder() != Settings.Main.instance.music_folder
            || lm.media_count() == 0)
        {
            changed (library_filechooser.get_current_folder ());
        }

        Settings.Main.instance.update_folder_hierarchy = organize_folders_toggle.get_active();
        Settings.Main.instance.write_metadata_to_file = write_file_metadata_toggle.get_active();
        Settings.Main.instance.copy_imported_music = copy_imported_music_toggle.get_active();

        Noise.App.instance.is_default_application = is_default_application_toggle.get_active ();

        return true;
    }
}
