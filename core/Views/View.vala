public interface Noise.View : Gtk.Widget {
    public abstract string title { get; protected set; }
    public abstract string id { get; construct; }
    public abstract Icon icon { get; protected set; }
    public abstract string category { get; protected set; }

    public signal void removed ();

    public abstract void shown ();

    public abstract void hide ();

    public void remove () {
        removed ();
    }

    public abstract bool filter (string search);
}
