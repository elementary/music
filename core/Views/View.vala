public abstract class Noise.View : Gtk.ScrolledWindow {
    public string title { get; set; default = ""; }
    public string id { get; construct set; default = ""; }
    public GLib.Icon icon { get; set; }
    public string category { get; set; default = "library"; }
    public int priority { get; construct set; default = 0; }
    public bool accept_data_drop { get; set; default = false; }

    public signal void remove_view ();

    public virtual void shown () {}

    public virtual void hidden () {}

    public abstract bool filter (string search);

    public virtual Gtk.Menu? get_sidebar_context_menu () {
        return null;
    }

    public virtual void data_drop (Gtk.SelectionData data) {}
}
