/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

public class Music.SearchBar : Granite.Bin {
    public signal void activated ();

    public ListModel list_model { get; construct; }

    private Gtk.StringFilter filter;
    private Gtk.FilterListModel filter_model;
    private Gtk.SearchEntry search_entry;

    /**
     * @param new_model the new model with the search applied. Make sure to use this one in further UI
     * instead of the old given model.
     */
    public SearchBar (ListModel list_model, out ListModel new_model) {
        Object (list_model: list_model);

        new_model = filter_model;
    }

    construct {
        var expression = new Gtk.PropertyExpression (typeof (AudioObject), null, "title");

        filter = new Gtk.StringFilter (expression) {
            ignore_case = true,
            match_mode = SUBSTRING
        };

        filter_model = new Gtk.FilterListModel (list_model, filter);

        search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Search titles in playlist")
        };

        child = search_entry;

        search_entry.search_changed.connect (on_search_changed);
        search_entry.activate.connect (() => activated ());
    }

    private void on_search_changed () {
        filter.search = search_entry.text;
    }

    public void start_search () {
        search_entry.grab_focus ();
    }
}
