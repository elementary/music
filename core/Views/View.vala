/**
* A view of the app.
*
* To create a view, subclass this and register an instance with {@link Noise.ViewManager.add}
*/
public abstract class Noise.View : Gtk.ScrolledWindow {

    /**
    * The title of the view.
    *
    * It will be displayed in the sidebar
    */
    public string title { get; set; default = ""; }

    /**
    * An unique identifier for this view.
    */
    public string id { get; construct set; default = ""; }

    /**
    * The icon of this view.
    *
    * It will be displayed in the sidebar
    */
    public GLib.Icon icon { get; set; }

    /**
    * The badge to display next to the name of the view in the sidebar
    */
    public string badge { get; set; }

    /**
    * The category of this view.
    *
    * Views are grouped by category in the sidebar.
    *
    * @see Noise.Category
    */
    public string category { get; set; default = "library"; }

    /**
    * View are ordered by priority in the sidebar.
    */
    public int priority { get; construct set; default = 0; }

    /**
    * Does this view handles drop. If it does, {@link Noise.View.data_drop} will be called when data is received.
    */
    public bool accept_data_drop { get; set; default = false; }

    /**
    * Deletes this view.
    */
    public signal void remove_view ();

    /**
    * Called every time this view is shown
    */
    public virtual void shown () {}

    /**
    * Called every time this view is hidden
    */
    public virtual void hidden () {}

    /**
    * Filter the content of this view.
    *
    * Called when the text of the search box changes
    *
    * @param search The search string
    * @return true if something was found
    */
    public abstract bool filter (string search);

    /**
    * Get the context menu to display for the sidebar item of this view
    */
    public virtual Gtk.Menu? get_sidebar_context_menu () {
        return null;
    }

    /**
    * Called when data is dragged in this view.
    *
    * If this view accept data drop, make sure to set {@link Noise.View.accept_data_drop} to true.
    */
    public virtual void data_drop (Gtk.SelectionData data) {}
}
