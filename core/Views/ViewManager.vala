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
* Errors related to view management
*/
public errordomain Noise.ViewError {
    /**
    * A requested view or category was not found
    */
    NOT_FOUND
}

/**
* Central place to add, remove, organize views (and categories) and get notified about their changes
*
* Categories are groups of views. They have an icon and a name, and are displayed as top-level items in the sidebar.
*
* A view is made of some metadata (title, icon, etc) that will be displayed in the sidebar, and a {@link Gtk.Widget} to
* display when this view is the active one.
*/
public class Noise.ViewManager : Object {
    /**
    * A list of all registered views
    */
    public Gee.ArrayList<View> views { get; private construct set; }

    /**
    * A list of all registered categories
    */
    public Gee.ArrayList<Category> categories { get; private construct set; }

    /**
    * The visible view
    */
    public View selected_view { get; private construct set; }

    /**
    * A new view have been registered
    */
    public signal void view_added (View new_view);

    /**
    * A view have been unregistered
    */
    public signal void view_removed (View view);

    /**
    * A category have been registered
    */
    public signal void category_added (Category cat);

    /**
    * A category have been unregistered
    */
    public signal void category_removed (Category cat);

    construct {
        views = new Gee.ArrayList<View> ();
        categories = new Gee.ArrayList<Category> ();
    }

    /**
    * Register a new category
    */
    public void add_category (Category cat) {
        if (!(cat in categories)) {
            categories.add (cat);
            category_added (cat);
            cat.remove.connect (() => {
                category_removed (cat);
            });
        }
    }

    /**
    * Try to retrieve a registered category.
    *
    * @return The requested category if found
    * @throw Throws an error if the category couldn't be found
    */
    public Category get_category (string id) throws ViewError {
        foreach (var cat in categories) {
            if (cat.id == id) {
                return cat;
            }
        }

        throw new ViewError.NOT_FOUND (@"Cant't find any category with the following ID: $id");
    }

    /**
    * Register a new view.
    *
    * Make sure you have registered its category before.
    */
    public void add (View view, bool select = false) {
        try {
            get_category (view.category);
            if (!(view in views)) {
                debug ("Adding view: %s", view.id);
                views.add (view);

                if (selected_view == null || select) {
                    selected_view = view;
                }

                view_added (view);
                view.remove.connect(() => {
                    view_removed (view);
                });
            }
        } catch (Error err) {
            warning (@"Tried to register a new view ($(view.id)) but its category ($(view.category)) wasn't registered yet.");
        }
    }

    /**
    * Remove a view.
    */
    public void remove_view (View view) {
        views.remove (view);
        view.destroy ();
        view_removed (view);
    }

    /**
    * Try to retrieve a registered view.
    *
    * @return The requested view if found
    * @throw Throws an error if the view couldn't be found
    */
    public new View get (string id) throws ViewError {
        foreach (var view in views) {
            if (view.id == id) {
                return view;
            }
        }

        throw new ViewError.NOT_FOUND (@"Cant't find any view with the following ID: $id");
    }

    /**
    * Show a certain view
    */
    public void select (View view) {
        if (!(view in views)) {
            add (view);
        }

        selected_view = view;
    }

    /**
    * Show a view, given its ID
    *
    * @return true if the view was found (and selected), false otherwise
    */
    public bool select_by_id (string id) {
        foreach (var view in views) {
            if (view.id == id) {
                select (view);
                return true;
            }
        }

        warning (@"Cant' show requested view: no view with the $id ID found");
        return false;
    }

    /**
    * Filter the current view
    *
    * @return true if something was found, false otherwise
    */
    public bool filter_view (string search) {
        return selected_view.filter (search);
    }
}
