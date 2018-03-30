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
 * Authored by: Baptiste Gelez <baptiste@gelez.xyz>
 */

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
    * The view wants to have it's label in the sidebar in edition mode.
    */
    public signal void request_sidebar_editing ();

    /**
    * Emitted when the view wants to be filtered again.
    */
    public signal void request_filtering ();

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
    *
    * @param list The source list
    * @param item The sidebar item associated with this view
    */
    public virtual Gtk.Menu? get_sidebar_context_menu (Granite.Widgets.SourceList list, Granite.Widgets.SourceList.Item item) {
        return null;
    }

    /**
    * Called when data is dragged in this view.
    *
    * If this view accept data drop, make sure to set {@link Noise.View.accept_data_drop} to true.
    */
    public virtual void data_drop (Gtk.SelectionData data) {}

    /**
    * Let you update the {@link Granite.Widgets.AlertView} that will be displayed if this view is empty
    *
    * A view is considered to be empty when {@link Noise.View.filter} returned false
    */
    public virtual void update_alert (Granite.Widgets.AlertView alert) {}
}
