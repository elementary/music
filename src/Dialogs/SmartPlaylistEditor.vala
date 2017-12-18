// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2017 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>,
 *              Corentin Noël <corentin@elementary.io>
 */

public class Noise.SmartPlaylistEditor : Gtk.Dialog {
    public SmartPlaylist smart_playlist { get; construct; }
    public bool is_new { get; construct; default = false; }
    public Library library { get; construct; }
    private Gee.ArrayList<SmartPlaylistEditorQuery> queries_list;
    private int row = 0;

    private Gtk.Entry name_entry;
    private Gtk.ComboBoxText match_combobox;
    private Gtk.Button save_button;
    private Gtk.Grid main_grid;
    private Gtk.Grid queries_grid;
    private Gtk.CheckButton limit_check;
    private Gtk.SpinButton limit_spin;
    private Gtk.Button adding_button;

    public SmartPlaylistEditor (SmartPlaylist? smart_playlist = null, Library library) {
        Object (
            library: library,
            is_new: smart_playlist == null,
            smart_playlist: smart_playlist ?? new SmartPlaylist (library)
        );
    }

    construct {
        border_width = 6;
        deletable = false;
        destroy_with_parent = true;
        transient_for = App.main_window;
        window_position = Gtk.WindowPosition.CENTER_ON_PARENT;

        name_entry = new Gtk.Entry ();
        name_entry.changed.connect (name_changed);
        name_entry.placeholder_text = _("Playlist Title");
        name_entry.text = is_new ? "" : smart_playlist.name;

        match_combobox = new Gtk.ComboBoxText ();
        match_combobox.insert_text (0, _("any"));
        match_combobox.insert_text (1, _("all"));
        match_combobox.active = is_new ? 0 : smart_playlist.conditional;

        var match_grid = new Gtk.Grid ();
        match_grid.column_spacing = 6;
        match_grid.margin_left = 12;
        match_grid.attach (new Gtk.Label (_("Match")), 0, 0, 1, 1);
        match_grid.attach (match_combobox, 1, 0, 1, 1);
        match_grid.attach (new Gtk.Label (_("of the following:")), 2, 0, 1, 1);

        queries_list = new Gee.ArrayList<SmartPlaylistEditorQuery> ();
        queries_grid = new Gtk.Grid ();
        queries_grid.column_spacing = 6;
        queries_grid.row_spacing = 6;
        queries_grid.expand = true;

        adding_button = new Gtk.Button.with_label (_("Add"));

        var limiter_grid = new Gtk.Grid ();
        limiter_grid.column_spacing = 6;
        limit_check = new Gtk.CheckButton.with_label (_("Limit to"));
        limit_spin = new Gtk.SpinButton.with_range (0, 500, 10);

        if (is_new) {
            limit_check.active = true;
            limit_spin.value = 50;
        } else {
            limit_check.active = smart_playlist.limit;
            limit_spin.value = (double) smart_playlist.limit_amount;
        }

        limit_spin.sensitive = limit_check.active;
        limit_check.toggled.connect (() => { limit_spin.sensitive = limit_check.active; });

        limiter_grid.attach (limit_check, 0, 0, 1, 1);
        limiter_grid.attach (limit_spin, 1, 0, 1, 1);
        limiter_grid.attach (new Gtk.Label (_("items")), 2, 0, 1, 1);
        limiter_grid.margin_left = 12;

        save_button = new Gtk.Button.with_label (_("Save"));
        save_button.clicked.connect (save_playlist);
        save_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var close_button = new Gtk.Button.with_label (_("Cancel"));
        close_button.clicked.connect (() => { destroy (); });

        var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_box.layout_style = Gtk.ButtonBoxStyle.END;
        button_box.pack_end (close_button, false, false, 0);
        button_box.pack_end (save_button, false, false, 0);
        button_box.spacing = 6;

        main_grid = new Gtk.Grid ();
        main_grid.expand = true;
        main_grid.margin_left = main_grid.margin_right = 12;
        main_grid.column_spacing = 12;
        main_grid.row_spacing = 6;
        main_grid.attach (new Granite.HeaderLabel (_("Name of Playlist")), 0, 0, 3, 1);
        main_grid.attach (name_entry, 0, 1, 3, 1);
        main_grid.attach (new Granite.HeaderLabel (_("Rules")), 0, 2, 3, 1);
        main_grid.attach (match_grid, 0, 3, 3, 1);
        main_grid.attach (queries_grid, 0, 4, 3, 1);
        main_grid.attach (new Granite.HeaderLabel (_("Options")), 0, 5, 3, 1);
        main_grid.attach (limiter_grid, 0, 6, 3, 1);
        main_grid.attach (button_box, 0, 7, 3, 1);
        ((Gtk.Container) get_content_area ()).add (main_grid);
    }

    public void load_smart_playlist () {
        show_all ();
        var sp_queries = smart_playlist.get_queries ();
        foreach (SmartQuery q in sp_queries) {
            var editor_query = new SmartPlaylistEditorQuery (q);
            editor_query.removed.connect (() => {queries_list.remove (editor_query);});
            queries_grid.attach (editor_query.grid, 0, row, 1, 1);
            editor_query.grid.show ();
            queries_list.add (editor_query);
            row++;
        }

        queries_grid.attach (adding_button, 0, row, 1, 1);
        if (sp_queries.size == 0) {
            add_row ();
        }

        adding_button.clicked.connect (add_row);
        adding_button.show ();
        // Validate initial state
        name_changed ();
    }

    private void name_changed () {
        if (String.is_white_space (name_entry.text)) {
            save_button.sensitive = false;
            return;
        } else {
            foreach (var p in library.get_smart_playlists ()) {
                var fixed_name = name_entry.text.strip ();
                if (smart_playlist.rowid != p.rowid && fixed_name == p.name) {
                    save_button.sensitive = false;
                    return;
                }
            }
        }

        save_button.sensitive = true;
    }

    public void add_row () {
        if (adding_button.parent != null) {
            queries_grid.remove (adding_button);
        }

        var editor_query = new SmartPlaylistEditorQuery (new SmartQuery ());
        editor_query.removed.connect (() => { queries_list.remove (editor_query); });
        editor_query.changed.connect (() => {
            if (!queries_list.contains (editor_query)) {
                queries_list.add (editor_query);
            }
        });
        queries_grid.attach (editor_query.grid, 0, row, 1, 1);
        editor_query.grid.show ();
        row++;
        queries_grid.attach (adding_button, 0, row, 1, 1);
    }

    public virtual void save_playlist () {
        smart_playlist.clear_queries ();
        smart_playlist.clear ();
        var queries = new Gee.TreeSet<SmartQuery> ();
        foreach (SmartPlaylistEditorQuery speq in queries_list) {
            queries.add (speq.query);
            debug ("QUERY FIELD SAVED: %s", speq.query.field.to_string());
            debug ("QUERY COMPARATOR SAVED: %s", speq.query.comparator.to_string());
            debug ("QUERY VALUE SAVED: %s", (string) speq.query.value);
        }

        smart_playlist.add_queries (queries);
        smart_playlist.name = name_entry.text.strip ();
        smart_playlist.conditional = (SmartPlaylist.ConditionalType) match_combobox.active;
        smart_playlist.limit = limit_check.active;
        smart_playlist.limit_amount = (int) limit_spin.value;
        if (is_new) {
            App.main_window.newly_created_playlist = true;
            library.add_smart_playlist (smart_playlist);
        }

        destroy ();
    }

    private class SmartPlaylistEditorQuery : GLib.Object {
        private GLib.HashTable<int, SmartQuery.ComparatorType> comparators;
        private Gtk.ComboBoxText field_combobox;
        private Gtk.ComboBoxText comparator_combobox;
        private Granite.Widgets.Rating value_rating;
        private Gtk.SpinButton value_numerical;
        private Gtk.Label units;
        private Gtk.Button remove_button;
        private Gtk.Entry value_entry;
        public Gtk.Grid grid;
        public SmartQuery query { get; construct; }
        public signal void removed ();
        public signal void changed ();

        private static SmartQuery.FieldType[] number_fields = {
            SmartQuery.FieldType.BITRATE, SmartQuery.FieldType.YEAR, SmartQuery.FieldType.RATING,
            SmartQuery.FieldType.PLAYCOUNT, SmartQuery.FieldType.SKIPCOUNT, SmartQuery.FieldType.LENGTH,
            SmartQuery.FieldType.TITLE,
        };

        private static SmartQuery.FieldType[] string_fields = {
            SmartQuery.FieldType.ALBUM, SmartQuery.FieldType.ARTIST, SmartQuery.FieldType.COMMENT,
            SmartQuery.FieldType.COMPOSER, SmartQuery.FieldType.GENRE, SmartQuery.FieldType.GROUPING,
            SmartQuery.FieldType.URI, SmartQuery.FieldType.TITLE
        };

        private static SmartQuery.FieldType[] rating_fields = {
            SmartQuery.FieldType.RATING
        };

        private static SmartQuery.FieldType[] date_fields = {
            SmartQuery.FieldType.LAST_PLAYED, SmartQuery.FieldType.DATE_ADDED
        };

        public SmartPlaylistEditorQuery (SmartQuery input_query) {
            Object (query: input_query);
        }

        construct {
            debug ("QUERY FIELD: %s", query.field.to_string());
            debug ("QUERY COMPARATOR: %s", query.comparator.to_string());
            debug ("QUERY VALUE: %s", (string)query.value);
            
            remove_button = new Gtk.Button.from_icon_name ("process-stop-symbolic");
            remove_button.clicked.connect (() => {
                removed ();
                grid.hide ();
            });
            remove_button.get_style_context ().add_class ("button");
            
            value_entry = new Gtk.Entry ();
            value_entry.changed.connect (() => {
                query.value = query.field == SmartQuery.FieldType.URI
                    ? Uri.escape_string (value_entry.text, "/")
                    : value_entry.text;
            });

            value_numerical = new Gtk.SpinButton.with_range (0, 9999, 1);
            value_numerical.value_changed.connect (() => {
                query.value = (int) value_numerical.value;
            });

            value_rating = new Granite.Widgets.Rating (true, Gtk.IconSize.MENU, true);
            value_rating.rating_changed.connect (() => {
                query.value = value_rating.rating;
            });
            
            if (query.field in string_fields) {
                value_entry.text = query.field == SmartQuery.FieldType.URI
                    ? Uri.unescape_string (query.value.get_string ())
                    : query.value.get_string ();
            } else if (query.field == SmartQuery.FieldType.RATING) {
                value_rating.rating = query.value.get_int ();
            } else {
                value_numerical.value = query.value.get_int ();
            }
            
            comparators = new GLib.HashTable<int, SmartQuery.ComparatorType> (null, null);

            comparator_combobox = new Gtk.ComboBoxText ();
            comparator_combobox.changed.connect (() => {
                //FIXME: this lamda is not stable enough to do the correct assignment
                //the changed signal is triggered multiple times in field_changed
                query.comparator = comparators[comparator_combobox.active];
            });

            field_combobox = new Gtk.ComboBoxText ();
            field_combobox.append_text (_("Album"));
            field_combobox.append_text (_("Artist"));
            field_combobox.append_text (_("Bitrate"));
            field_combobox.append_text (_("Comment"));
            field_combobox.append_text (_("Composer"));
            field_combobox.append_text (_("Date Added"));
            field_combobox.append_text (_("Genre"));
            field_combobox.append_text (_("Grouping"));
            field_combobox.append_text (_("Last Played"));
            field_combobox.append_text (_("Length"));
            field_combobox.append_text (_("Playcount"));
            field_combobox.append_text (_("Rating"));
            field_combobox.append_text (_("Skipcount"));
            field_combobox.append_text (_("Title"));
            field_combobox.append_text (_("Year"));
            field_combobox.append_text (_("URI"));
            field_combobox.changed.connect (() => {
                query.field = (SmartQuery.FieldType) field_combobox.active;
                field_changed (true);
            });
            field_combobox.active = (int) query.field;

            units = new Gtk.Label ("");

            grid = new Gtk.Grid ();
            grid.column_spacing = 6;
            grid.hexpand = true;
            grid.attach (remove_button, 0, 0, 1, 1);
            grid.attach (field_combobox, 1, 0, 1, 1);
            grid.attach (comparator_combobox, 2, 0, 1, 1);
            grid.attach (value_entry, 3, 0, 1, 1);
            grid.attach (value_rating, 4, 0, 1, 1);
            grid.attach (value_numerical, 4, 0, 1, 1);
            grid.attach (units, 5, 0, 1, 1);

            field_changed (false);
            remove_button.show ();
            field_combobox.show ();
        }

        private void field_changed (bool from_user = true) {
            value_numerical.hide ();
            value_rating.hide ();
            value_entry.hide ();

            if (query.field in string_fields) {
                value_entry.show ();
                comparator_combobox.remove_all ();
                comparator_combobox.append_text (_("is"));
                comparator_combobox.append_text (_("contains"));
                comparator_combobox.append_text (_("does not contain"));
                comparators.remove_all ();
                comparators.insert (0, SmartQuery.ComparatorType.IS);
                comparators.insert (1, SmartQuery.ComparatorType.CONTAINS);
                comparators.insert (2, SmartQuery.ComparatorType.NOT_CONTAINS);
                switch (query.comparator) {
                    case SmartQuery.ComparatorType.CONTAINS:
                        comparator_combobox.active = 1;
                        break;
                    case SmartQuery.ComparatorType.NOT_CONTAINS:
                        comparator_combobox.active = 2;
                        break;
                    case default: // SmartQuery.ComparatorType.IS or unset
                        comparator_combobox.active = 0;
                        break;
                }
            } else {
                if (query.field in rating_fields) {
                    value_rating.show ();
                } else {
                    value_numerical.show ();
                }

                if (query.field in number_fields) {
                    comparator_combobox.remove_all ();
                    comparator_combobox.append_text (_("is exactly"));
                    comparator_combobox.append_text (_("is at most"));
                    comparator_combobox.append_text (_("is at least"));
                    comparators.remove_all ();
                    comparators.insert (0, SmartQuery.ComparatorType.IS_EXACTLY);
                    comparators.insert (1, SmartQuery.ComparatorType.IS_AT_MOST);
                    comparators.insert (2, SmartQuery.ComparatorType.IS_AT_LEAST);
                    if ((int) query.comparator >= 4) {
                        comparator_combobox.active = (int) query.comparator - 4;
                    } else {
                        comparator_combobox.active = 0;
                    }

                } else if (query.field in date_fields) {
                    comparator_combobox.remove_all ();
                    comparator_combobox.append_text (_("is exactly"));
                    comparator_combobox.append_text (_("is within"));
                    comparator_combobox.append_text (_("is before"));
                    comparators.remove_all ();
                    comparators.insert (0, SmartQuery.ComparatorType.IS_EXACTLY);
                    comparators.insert (1, SmartQuery.ComparatorType.IS_WITHIN);
                    comparators.insert (2, SmartQuery.ComparatorType.IS_BEFORE);
                    switch (query.comparator) {
                        case SmartQuery.ComparatorType.IS_WITHIN:
                            comparator_combobox.active = 1;
                            break;
                        case SmartQuery.ComparatorType.IS_BEFORE:
                            comparator_combobox.active = 2;
                            break;
                        default: // SmartQuery.ComparatorType.IS_EXACTLY or unset
                            comparator_combobox.active = 0;
                            break;
                    }
                }
            }

            comparator_combobox.show ();

            //helper for units
            if ((SmartQuery.FieldType) field_combobox.active == SmartQuery.FieldType.LENGTH) {
                units.label = _("seconds");
                units.show ();
            } else if (((SmartQuery.FieldType) field_combobox.active) in date_fields) {
                units.label = _("days ago");
                units.show ();
            } else if ((SmartQuery.FieldType) field_combobox.active == SmartQuery.FieldType.BITRATE) {
                units.label = _("kbps");
                units.show ();
            } else {
                units.hide ();
            }
            
            if (from_user) {
                changed ();
            }
        }
    }
}
