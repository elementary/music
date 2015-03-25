// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2013 Noise Developers (http://launchpad.net/noise)
 *
 * This software is licensed under the GNU General Public License
 * (version 2 or later). See the COPYING file in this distribution.
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
 *              Corentin Noël <tintou@mailoo.org>
 */

public class Noise.SmartPlaylistEditor : Gtk.Dialog {
    SmartPlaylist sp;
    private bool is_new = false;
    private Gtk.Entry name_entry;
    private Gtk.ComboBoxText match_combobox;
    private Gtk.Button save_button;
    private Gtk.Grid main_grid;
    private Gtk.Grid queries_grid;
    private Gtk.CheckButton limit_check;
    private Gtk.SpinButton limit_spin;
    private Gtk.Button adding_button;
    private Gee.ArrayList<SmartPlaylistEditorQuery> queries_list;
    private int row = 0;
    private Library library;

    public SmartPlaylistEditor (SmartPlaylist? sp = null, Library library) {
        this.title = _("Smart Playlist Editor");
        this.library = library;
        this.deletable = false;

        if (sp == null) {
            is_new = true;
            this.sp = new SmartPlaylist (library);
        } else {
            this.sp = sp;
        }

        /* start out by creating all category labels */
        var name_label = new Gtk.Label (_("Name of Playlist"));
        var rules_label = new Gtk.Label (_("Rules"));
        var options_label = new Gtk.Label (_("Options"));

        /* make them look good */
        name_label.halign = Gtk.Align.START;
        rules_label.halign = Gtk.Align.START;
        options_label.halign = Gtk.Align.START;
        name_label.set_markup ("<b>" + Markup.escape_text (_("Name of Playlist"), -1) + "</b>");
        rules_label.set_markup ("<b>" + Markup.escape_text (_("Rules"), -1) + "</b>");
        options_label.set_markup ("<b>" + Markup.escape_text (_("Options"), -1) + "</b>");

        /* add the name entry */
        name_entry = new Gtk.Entry ();
        name_entry.placeholder_text = _("Playlist Title");
        if (is_new == false)
            name_entry.text = sp.name;

        var match_grid = new Gtk.Grid ();
        match_grid.column_spacing = 12;
        var match_label = new Gtk.Label (_("Match"));
        match_combobox = new Gtk.ComboBoxText ();
        match_combobox.insert_text (0, _("any"));
        match_combobox.insert_text (1, _("all"));
        if (is_new == false)
            match_combobox.set_active (sp.conditional);
        else
            match_combobox.set_active (0);

        var match_following_label = new Gtk.Label (_("of the following:"));
        match_grid.attach (match_label, 0, 0, 1, 1);
        match_grid.attach (match_combobox, 1, 0, 1, 1);
        match_grid.attach (match_following_label, 2, 0, 1, 1);

        /* create rule list */
        queries_list = new Gee.ArrayList<SmartPlaylistEditorQuery> ();
        queries_grid = new Gtk.Grid ();
        queries_grid.column_spacing = 12;
        queries_grid.row_spacing = 6;
        queries_grid.expand = true;

        adding_button = new Gtk.Button.with_label (_("Add"));

        /* create extra option: limiter */
        var limiter_grid = new Gtk.Grid ();
        limiter_grid.column_spacing = 12;
        limit_check = new Gtk.CheckButton.with_label (_("Limit to"));
        limit_spin = new Gtk.SpinButton.with_range (0, 500, 10);
        var limit_label = new Gtk.Label (_("items"));

        if (is_new == false) {
            limit_check.set_active (sp.limit);
            limit_spin.set_value ((double)sp.limit_amount);
        } else {
            limit_check.set_active (true);
            limit_spin.set_value (50);
        }

        limit_spin.sensitive = limit_check.active;
        limit_check.toggled.connect(() => { limit_spin.sensitive = limit_check.active; });

        limiter_grid.attach (limit_check, 0, 0, 1, 1);
        limiter_grid.attach (limit_spin, 1, 0, 1, 1);
        limiter_grid.attach (limit_label, 2, 0, 1, 1);

        /* add the Save button on bottom */
        var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_box.spacing = 6;
        save_button = new Gtk.Button.with_label (_(STRING_SAVE));
        save_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        var close_button = new Gtk.Button.with_label (_(STRING_CANCEL));
        button_box.set_layout (Gtk.ButtonBoxStyle.END);
        button_box.pack_end (close_button, false, false, 0);
        button_box.pack_end (save_button, false, false, 0);

        main_grid = new Gtk.Grid ();
        main_grid.expand = true;
        main_grid.margin_left = main_grid.margin_right = 12;
        main_grid.column_spacing = 12;
        main_grid.row_spacing = 6;
        main_grid.attach (name_label, 0, 0, 3, 1);
        main_grid.attach (name_entry, 0, 1, 3, 1);
        main_grid.attach (rules_label, 0, 2, 3, 1);
        main_grid.attach (match_grid, 0, 3, 3, 1);
        main_grid.attach (queries_grid, 0, 4, 3, 1);
        main_grid.attach (options_label, 0, 5, 3, 1);
        main_grid.attach (limiter_grid, 0, 6, 3, 1);
        main_grid.attach (button_box, 0, 7, 3, 1);
        ((Gtk.Container) get_content_area ()).add (main_grid);

        save_button.clicked.connect (save_click);
        close_button.clicked.connect (close_click);
        name_entry.changed.connect (name_changed);
    }

    public void load_smart_playlist () {
        show_all ();
        var sp_queries = sp.get_queries ();
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

        foreach(SmartPlaylistEditorQuery speq in queries_list) {
            speq.field_changed (false);
        }

        adding_button.clicked.connect (add_button_click);
        adding_button.show ();
        // Validate initial state
        name_changed ();
    }
    
    private void name_changed () {
        if (String.is_white_space (name_entry.text)) {
            save_button.set_sensitive (false);
            return;
        } else {
            foreach (var p in library.get_smart_playlists ()) {
                var fixed_name = name_entry.text.strip ();
                if (sp.rowid != p.rowid && fixed_name == p.name) {
                    save_button.set_sensitive (false);
                    return;
                }
            }
        }

        save_button.set_sensitive (true);
    }

    public void add_row () {
        if (adding_button.parent != null)
            queries_grid.remove (adding_button);

        var editor_query = new SmartPlaylistEditorQuery (new SmartQuery());
        editor_query.removed.connect (() => {queries_list.remove (editor_query);});
        editor_query.changed.connect (() => {if (!queries_list.contains (editor_query)) queries_list.add (editor_query);});
        queries_grid.attach (editor_query.grid, 0, row, 1, 1);
        editor_query.grid.show ();
        row++;
        queries_grid.attach (adding_button, 0, row, 1, 1);
        editor_query.field_changed (false);
    }

    public virtual void add_button_click () {
        add_row ();
    }

    public virtual void close_click () {
        this.destroy ();
    }

    public virtual void save_click () {
        sp.clear_queries ();
        var queries = new Gee.LinkedList<SmartQuery> ();
        foreach (SmartPlaylistEditorQuery speq in queries_list) {
            queries.add (speq.get_query ());
        }

        sp.add_queries (queries);
        sp.name = name_entry.text.strip ();
        sp.conditional = (SmartPlaylist.ConditionalType) match_combobox.get_active ();
        sp.limit = limit_check.get_active ();
        sp.limit_amount = (int)limit_spin.get_value ();
        if (is_new) {
            App.main_window.newly_created_playlist = true;
            library.add_smart_playlist (sp);
        }

        this.destroy ();
    }
}
public class Noise.SmartPlaylistEditorQuery : GLib.Object {
    private SmartQuery _q;

    public Gtk.Grid grid;
    private Gtk.ComboBoxText field_combobox;
    private Gtk.ComboBoxText comparator_combobox;
    private Granite.Widgets.Rating _valueRating;
    private Gtk.SpinButton _valueNumerical;
    private Gtk.ComboBoxText _valueOption;
    private Gtk.Label _units;
    private Gtk.Button remove_button;
    private Gtk.Entry value_entry;

    private GLib.HashTable<int, SmartQuery.ComparatorType> comparators;

    public signal void removed ();
    public signal void changed ();

    public SmartPlaylistEditorQuery (SmartQuery q) {
        _q = q;

        comparators = new GLib.HashTable<int, SmartQuery.ComparatorType> (null, null);

        field_combobox = new Gtk.ComboBoxText ();
        comparator_combobox = new Gtk.ComboBoxText();
        value_entry = new Gtk.Entry ();
        value_entry.changed.connect (() => {changed ();});
        _valueNumerical = new Gtk.SpinButton.with_range (0, 9999, 1);
        _valueOption = new Gtk.ComboBoxText ();
        _valueRating = new Granite.Widgets.Rating (true, Gtk.IconSize.MENU, true);
        remove_button = new Gtk.Button.with_label (_("Remove"));
        remove_button.halign = Gtk.Align.END;

        field_combobox.append_text (_("Album"));
        field_combobox.append_text (_("Artist"));
        field_combobox.append_text (_("Bitrate"));
        field_combobox.append_text (_("Comment"));
        field_combobox.append_text (_("Composer"));
        field_combobox.append_text (_("Date Added"));
        field_combobox.append_text (_("Date Released"));
        field_combobox.append_text (_("Genre"));
        field_combobox.append_text (_("Grouping"));
        field_combobox.append_text (_("Last Played"));
        field_combobox.append_text (_("Length"));
        field_combobox.append_text (_("Playcount"));
        field_combobox.append_text (_("Rating"));
        field_combobox.append_text (_("Skipcount"));
        field_combobox.append_text (_("Title"));
        field_combobox.append_text (_("Year"));

        field_combobox.set_active ((int)q.field);
        debug ("setting filed to %d\n", q.field);
        comparator_combobox.set_active ((int)q.comparator);

        if (needs_value (q.field)) {
            value_entry.text = q.value;
        } else if (q.field == SmartQuery.FieldType.RATING) {
            _valueRating.rating = int.parse (q.value);
        } else {
            _valueNumerical.set_value (int.parse (q.value));
        }

        _units = new Gtk.Label ("");
        grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.hexpand = true;
        grid.attach (field_combobox, 0, 0, 1, 1);
        grid.attach (comparator_combobox, 1, 0, 1, 1);
        grid.attach (value_entry, 2, 0, 1, 1);
        grid.attach (_valueOption, 3, 0, 1, 1);
        grid.attach (_valueRating, 3, 0, 1, 1);
        grid.attach (_valueNumerical, 3, 0, 1, 1);
        grid.attach (_units, 4, 0, 1, 1);
        grid.attach (remove_button, 5, 0, 1, 1);

        field_changed (false);

        remove_button.clicked.connect (remove_clicked);
        field_combobox.changed.connect (() => {field_changed (true);});
    }

    public SmartQuery get_query () {
        SmartQuery rv = new SmartQuery ();

        rv.field = (SmartQuery.FieldType)field_combobox.get_active ();
        rv.comparator = comparators.get (comparator_combobox.get_active ());
        if (needs_value ((SmartQuery.FieldType)field_combobox.get_active ()))
            rv.value = value_entry.text;
        else if (field_combobox.get_active () == SmartQuery.FieldType.RATING)
            rv.value = _valueRating.rating.to_string ();
        else
            rv.value = _valueNumerical.value.to_string ();

        return rv;
    }
    
    public virtual void field_changed (bool from_user = true) {
        _valueNumerical.hide ();
        _valueOption.hide ();
        _valueRating.hide ();
        value_entry.hide ();
        field_combobox.show ();
        if (needs_value ( (SmartQuery.FieldType)field_combobox.get_active ())) {
            value_entry.show ();
            comparator_combobox.remove_all ();
            comparator_combobox.append_text (_("is"));
            comparator_combobox.append_text (_("contains"));
            comparator_combobox.append_text (_("does not contain"));
            comparators.remove_all ();
            comparators.insert (0, SmartQuery.ComparatorType.IS);
            comparators.insert (1, SmartQuery.ComparatorType.CONTAINS);
            comparators.insert (2, SmartQuery.ComparatorType.NOT_CONTAINS);

            switch (_q.comparator) {
                case SmartQuery.ComparatorType.CONTAINS:
                    comparator_combobox.set_active (1);
                    break;
                case SmartQuery.ComparatorType.NOT_CONTAINS:
                    comparator_combobox.set_active (2);
                    break;
                default: // SmartQuery.ComparatorType.IS or unset
                    comparator_combobox.set_active (0);
                    break;
            }
        } else {
            if (is_rating ((SmartQuery.FieldType)field_combobox.get_active ())) {
                _valueRating.show ();
            } else {
                _valueNumerical.show ();
            }

            if (needs_value_2 ((SmartQuery.FieldType)field_combobox.get_active ())) {
                comparator_combobox.remove_all ();
                comparator_combobox.append_text (_("is exactly"));
                comparator_combobox.append_text (_("is at most"));
                comparator_combobox.append_text (_("is at least"));
                comparators.remove_all ();
                comparators.insert (0, SmartQuery.ComparatorType.IS_EXACTLY);
                comparators.insert (1, SmartQuery.ComparatorType.IS_AT_MOST);
                comparators.insert (2, SmartQuery.ComparatorType.IS_AT_LEAST);
                if ((int)_q.comparator >= 4)
                    comparator_combobox.set_active ((int)_q.comparator-4);
                else
                    comparator_combobox.set_active (0);

            } else if (is_date((SmartQuery.FieldType)field_combobox.get_active ())) {
                comparator_combobox.remove_all ();
                comparator_combobox.append_text(_("is exactly"));
                comparator_combobox.append_text(_("is within"));
                comparator_combobox.append_text(_("is before"));
                comparators.remove_all ();
                comparators.insert (0, SmartQuery.ComparatorType.IS_EXACTLY);
                comparators.insert (1, SmartQuery.ComparatorType.IS_WITHIN);
                comparators.insert (2, SmartQuery.ComparatorType.IS_BEFORE);
                switch (_q.comparator) {
                    case SmartQuery.ComparatorType.IS_WITHIN:
                        comparator_combobox.set_active (1);
                        break;
                    case SmartQuery.ComparatorType.IS_BEFORE:
                        comparator_combobox.set_active (2);
                        break;
                    default: // SmartQuery.ComparatorType.IS_EXACTLY or unset
                        comparator_combobox.set_active (0);
                        break;
                }
            }
        }

        comparator_combobox.show();
        //helper for units
        if (field_combobox.get_active_text () == _("Length")) {
            _units.set_text (_("seconds"));
            _units.show ();
        } else if (is_date ((SmartQuery.FieldType)field_combobox.get_active ())) {
            _units.set_text (_("days ago"));
            _units.show ();
        } else if ((SmartQuery.FieldType)field_combobox.get_active () == SmartQuery.FieldType.BITRATE) {
            _units.set_text (_("kbps"));
            _units.show ();
        } else {
            _units.hide ();
        }

        if (from_user == true)
            changed ();
    }

    public virtual void remove_clicked () {
        removed ();
        this.grid.hide ();
    }

    public bool needs_value (SmartQuery.FieldType compared) {
        return (compared == SmartQuery.FieldType.ALBUM || compared == SmartQuery.FieldType.ARTIST
                || compared == SmartQuery.FieldType.COMMENT || compared == SmartQuery.FieldType.COMPOSER
                || compared == SmartQuery.FieldType.GENRE || compared == SmartQuery.FieldType.GROUPING
                || compared == SmartQuery.FieldType.TITLE);
    }

    public bool needs_value_2 (SmartQuery.FieldType compared) {
        return (compared == SmartQuery.FieldType.BITRATE || compared == SmartQuery.FieldType.YEAR
                || compared == SmartQuery.FieldType.RATING || compared == SmartQuery.FieldType.PLAYCOUNT
                || compared == SmartQuery.FieldType.SKIPCOUNT || compared == SmartQuery.FieldType.LENGTH
                || compared == SmartQuery.FieldType.TITLE);
    }

    public bool is_rating (SmartQuery.FieldType compared) {
        return compared == SmartQuery.FieldType.RATING;
    }

    public bool is_date (SmartQuery.FieldType compared) {
        return (compared == SmartQuery.FieldType.LAST_PLAYED || compared == SmartQuery.FieldType.DATE_ADDED
                || compared == SmartQuery.FieldType.DATE_RELEASED);
    }
}
