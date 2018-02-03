public abstract class Noise.View : Gtk.Bin {
    public string title { get; set; default = ""; }
    public string id { get; construct set; default = ""; }
    public GLib.Icon icon { get; set; }
    public string category { get; set; default = "library"; }

    public signal void remove_view ();

    public virtual void shown () {}

    public virtual void hidden () {}

    public abstract bool filter (string search);
}
