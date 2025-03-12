public class Music.SearchBar : Granite.Bin {
    public signal void activated ();

    public Gtk.FilterListModel list_model { get; construct; }

    private Gtk.StringFilter filter;
    private Gtk.SearchEntry search_entry;

    public SearchBar (Gtk.FilterListModel list_model) {
        Object (list_model: list_model);
    }

    construct {
        var expression = new Gtk.PropertyExpression (typeof (AudioObject), null, "title");

        list_model.filter = filter = new Gtk.StringFilter (expression) {
            ignore_case = true,
            match_mode = SUBSTRING
        };

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
