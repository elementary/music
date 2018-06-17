// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
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
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>,
 *              Scott Ringwelski <sgringwe@mtu.edu>
 */

/**
 * Container and controller of the list and grid views, and info widgets
 * (welcome screen and embedded alert).
 *
 * A ViewWrapper triggers searches, status info updates, and also handles
 * view switching. It also works as a proxy for setting the media contained
 * by all the views. Please see set_media(), update_media(), remove_media()
 * and add_media().
 *
 * The views it contains implement the {@link Noise.ContentView} interface.
 */
public abstract class Noise.ViewWrapper : Gtk.Grid {
    public enum Hint {
        NONE,
        MUSIC,
        PLAYLIST,
        READ_ONLY_PLAYLIST,
        SMART_PLAYLIST,
        CDROM,
        DEVICE,
        DEVICE_AUDIO,
        DEVICE_PODCAST,
        DEVICE_AUDIOBOOK,
        NETWORK_DEVICE,
        ALBUM_LIST;
    }

    /**
     * Type of visual representation of the media.
     *
     * Values *must* match the index of the respective view in the view selector.
     */
    public enum ViewType {
        GRID    = 0,   // Matches index 0 of the view in lw.view_selector
        LIST    = 1,   // Matches index 1 of the view in lw.view_selector
        ALERT   = 2,   // For embedded alerts
        WELCOME = 3,   // For welcome screens
        NONE    = 4    // Nothing showing
    }

    public ListView list_view { get; protected set; }
    public AlbumsView grid_view { get; protected set; }
    protected Granite.Widgets.AlertView embedded_alert { get; set; }
    protected Granite.Widgets.Welcome welcome_screen { get; set; }

    public bool has_grid_view { get { return grid_view != null; } }
    public bool has_list_view { get { return list_view != null;  } }
    public bool has_embedded_alert { get { return embedded_alert != null; } }
    public bool has_welcome_screen { get { return welcome_screen != null; } }

    protected ViewType current_view {
        get {
            var view = view_stack.visible_child;

            if (view == grid_view)
                return ViewType.GRID;

            if (view == list_view)
                return ViewType.LIST;

            if (view == embedded_alert) {
                return ViewType.ALERT;
            }

            if (view == welcome_screen)
                return ViewType.WELCOME;

            return ViewType.NONE;
        }
    }


    /**
     * This is by far the most important property of this object.
     * It defines how child widgets behave and some other properties.
     */
    public Hint hint { get; construct set; }
    public Library library { get; protected construct set; }

    public bool is_current_wrapper {
        get {
            return (App.main_window.initialization_finished && App.main_window.view_stack.visible_child == this);
        }
    }

    public Playlist? playlist { get; construct set; default = null; }

    public int media_count {
        get { return (int) list_view.n_media; }
    }

    // Contruction must always happen before population
    protected const int VIEW_CONSTRUCT_PRIORITY = Priority.DEFAULT_IDLE - 10;

    private bool widgets_ready = false;
    private ViewStack view_stack;
    private ViewType last_used_view = ViewType.NONE;

    // Whether a call to set_media() has been issues on this view. This is important.
    // No widget is set as active until this is true!
    private bool data_initialized = false;

    public ViewWrapper (Hint hint, Library library) {
        Object (hint: hint, library: library);
    }

    construct {
        orientation = Gtk.Orientation.VERTICAL;

        view_stack = new ViewStack ();
        add (view_stack);

        App.main_window.view_selector.mode_changed.connect (view_selector_changed);
        library.search_finished.connect (search_field_changed);
    }

    /**
     * Checks which views are available and packs them in (if they are not packed yet)
     */
    protected void pack_views () {
        assert (view_stack != null);

        if (has_grid_view && grid_view.parent != view_stack)
            view_stack.add_view (grid_view);

        if (has_list_view && list_view.parent != view_stack)
            view_stack.add_view (list_view);

        if (has_welcome_screen && welcome_screen.parent != view_stack)
            view_stack.add_view (welcome_screen);

        if (has_embedded_alert && embedded_alert.parent != view_stack)
            view_stack.add_view (embedded_alert);

        widgets_ready = true;
        show_all ();
    }

    /**
     * Convenient visibility method
     */
    protected void set_active_view (ViewType type, out bool successful = null) {
        successful = true;

        if (type == current_view || !is_current_wrapper)
            return;

        switch (type) {
            case ViewType.LIST:
                if (has_list_view) {
                    view_stack.visible_child = list_view;
                    list_view.list_view.scroll_to_current_media (true);
                } else {
                    successful = false;
                }
                break;
            case ViewType.GRID:
                if (has_grid_view) {
                    view_stack.visible_child = grid_view;
                } else {
                    if (has_list_view) {
                        view_stack.visible_child = list_view;
                        list_view.list_view.scroll_to_current_media (true);
                    }
                    successful = false;
                }
                break;
            case ViewType.ALERT:
                view_stack.visible_child = embedded_alert;
                break;
            case ViewType.WELCOME:
                view_stack.visible_child = welcome_screen;
                break;
        }

        // We're not switching (officially) to the new view if it's not available
        if (!successful) {
            debug ("%s : VIEW %s was not available", hint.to_string (), type.to_string ());
            return;
        }

        last_used_view = type;

        // Update LibraryWindow widgets
        update_library_window_widgets ();
    }

    /**
     * This method ensures that the view switcher and search box are sensitive/insensitive
     * when they have to. It also selects the proper view switcher item based on the
     * current view.
     */
    protected void update_library_window_widgets () {
        if (!is_current_wrapper || !has_list_view || !App.main_window.initialization_finished)
            return;

        debug ("update_library_window_widgets [%s]", hint.to_string ());

        // Search field
        // Insensitive if there's no media to search (applies to ALERT/WELCOME views)
        App.main_window.search_entry.set_sensitive (media_count > 0);

        // View switcher
        // Insensitive if the current view is the welcome/alert screen or if both views
        // are not available (in the queue, device, or playlist sources).
        App.main_window.view_selector.set_sensitive (has_grid_view && has_list_view
                                                    && current_view != ViewType.WELCOME
                                                    && current_view != ViewType.ALERT);

        // Set active mode to column view if it is visible. We have to ensure
        // that it is not null because the column_browser is not guaranteed to
        // exist. This is done separately from below because of ViewSelector's
        // poor API.
        App.main_window.view_selector.set_column_browser_toggle_active (list_view.column_browser != null
                                                                       && list_view.column_browser.visible);

        // select the right view in the view selector if it's one of the three views.
        // The order is important here. The sensitivity set above must be set before this,
        // as view_selector_changed() depends on that.
        if (!App.main_window.view_selector.get_column_browser_toggle_active ()) {
            if (App.main_window.view_selector.selected != (int)last_used_view && (int)last_used_view <= 1)
                App.main_window.view_selector.selected = (Widgets.ViewSelector.Mode)last_used_view;
        }
    }

    public void view_selector_changed () {
        if (!App.main_window.initialization_finished || !App.main_window.view_selector.sensitive)
            return;

        if ((current_view == ViewType.ALERT && media_count < 1) ||
        current_view == ViewType.WELCOME)
            return;

        debug ("view_selector_changed [%s]", hint.to_string ());

        var selected_view = (ViewType) App.main_window.view_selector.selected;

        if (is_current_wrapper) {
            set_active_view (selected_view);
        } else
            last_used_view = selected_view;
    }

    public void play_first_media (bool? force=false) {
        if (!has_list_view)
            return;

        debug ("play_first_media [%s]", hint.to_string ());

        list_view.set_as_current_list (1);
        var m = App.player.media_from_current_index (0);

        if (m == null)
           return;
        App.player.play_media (m);
        App.player.start_playback ();
    }

    /**
     * This handles updating all the shared stuff outside the view area.
     *
     * You should only call this method on the respective ViewWrapper whenever the sidebar's
     * selected view changes.
     *
     * Note: The sidebar-item selection and other stuff is handled automatically by the LibraryWindow
     *       by request of SideTreeView. See LibraryWindow :: set_active_view() for more details.
     */
    public void set_as_current_view () {
        if (!App.main_window.initialization_finished)
            return;
        debug ("SETTING AS CURRENT VIEW [%s]", hint.to_string ());

        update_visible_media ();
        check_have_media ();
        update_library_window_widgets ();
    }

    private void search_field_changed () {
        if (!is_current_wrapper)
            return;

        // Do the actual search and show up results....
        update_visible_media ();
    }

    /**
     * Thhis method tells the parent class whether the search field, media control buttons,
     * and other external widgets should be sensitive or not (among other things), so that
     * the abstract parent class can take care of all these automated/repetitive tasks.
     * The default implementation is very limited, so it's recommended to override this
     * method from the subclass.
     *
     * OVERRIDING THE METHOD:
     *
     * In case the view contains an alert box and/or welcome screen, it is recommended
     * to set either view as current from your implementation before returning anything.
     * (Using set_active_view.)
     *
     * The child ViewWrappers are also responsible for setting the proper view back after
     * the alert/welcome screens are no longer needed (i.e. when the method would return
     * 'true'.)
     * select_proper_content_view() selects the best suited view for you in case you
     * don't want to handle that. You still need to call it from the implementation though.
     *
     * WARNING: Don't ever attempt calling the set_media(), update_media(), add_media() or
     *          remove_media() methods (including async variations) from your implementation,
     *          unless you want the method to fall into an infinite chain of recursive calls,
     *          freezing the entire application.
     *
     * @return true if the ViewWrapper has media. false otherwise.
     */
    protected virtual bool check_have_media () {
        // we don't want to display any widget until the initial media is set.
        if (!data_initialized)
            return false;

        bool have_media = media_count > 0;
        // show alert or welcome screen if there's no media
        if (have_media) {
            select_proper_content_view ();
        } else if (has_welcome_screen) {
            set_active_view (ViewType.WELCOME);
        } else if (has_embedded_alert) {
            set_no_media_alert ();
            set_active_view (ViewType.ALERT);
        }

        return have_media;
    }

    protected virtual void select_proper_content_view () {
        var new_view = (ViewType) App.main_window.view_selector.selected;

        const int N_VIEWS = 2; // list and grid views
        if (new_view < 0 || new_view > N_VIEWS - 1)
            new_view = ViewType.LIST;

        if (new_view == ViewType.LIST && has_list_view)
            set_active_view (ViewType.LIST);
        else if (new_view == ViewType.GRID && has_grid_view)
            set_active_view (ViewType.GRID);
        else if (has_list_view) {
            view_stack.visible_child = list_view;
            list_view.list_view.scroll_to_current_media (true);
        } else if (has_grid_view)
            view_stack.visible_child = grid_view;
    }

    /**
     * @return A collection containing ALL the media associated to this view.
     */
    public Gee.Collection<Media> get_media_list () {
        return list_view.get_media ();
    }

    /**
     * Resets all the filters (external and internal) applied to a view inside
     * the view wrapper. It should only be called if the view is the current active
     * wrapper.
     */
    public void clear_filters () requires (is_current_wrapper) {
        update_visible_media (); // force a refresh ;)
    }

    /**
     * Updates the data in visible_media and re-populates all the views.
     * Primarily used for searches
     */
    protected void update_visible_media () {
        if (!is_current_wrapper)
            return;
        debug ("UPDATING VISIBLE MEDIA [%s]", hint.to_string ());

        if (has_list_view) {
            lock (list_view) {
                list_view.refilter ();
            }
        }

        if (has_grid_view) {
            lock (grid_view) {
                grid_view.refilter ();
            }
        }
    }

    protected virtual void set_no_media_alert () {
        embedded_alert.icon_name = "dialog-information";
        embedded_alert.title = _("No media");
    }

    public async void set_media_async (Gee.Collection<Media> new_media) {
        if (!widgets_ready)
            return;
        set_media (new_media);
    }

    public async void add_media_async (Gee.Collection<Media> to_add) {
        if (!widgets_ready)
            return;
        add_media (to_add);
        update_visible_media ();
    }

    public async void remove_media_async (Gee.Collection<Media> to_remove) {
        if (!widgets_ready)
            return;
        remove_media (to_remove);
    }

    public async void update_media_async (Gee.Collection<Media> to_update) {
        if (!widgets_ready)
            return;
        update_media (to_update);
    }

    private void set_media (Gee.Collection<Media> new_media) {
        debug ("SETTING MEDIA [%s]", hint.to_string ());

        if (has_list_view) {
            lock (list_view) {
                list_view.set_media (new_media);
            }
        }

        if (has_grid_view) {
            lock (grid_view) {
                grid_view.set_media (new_media);
            }
        }

        data_initialized = true;

        update_visible_media ();
        update_widget_state ();
    }

    private void update_media (Gee.Collection<Media> media) requires (data_initialized) {
        if (media.is_empty)
            return;

        debug ("UPDATING MEDIA [%s]", hint.to_string ());

        if (has_list_view) {
            lock (list_view) {
                list_view.update_media (media);
            }
        }

        if (has_grid_view) {
            lock (grid_view) {
                grid_view.update_media (media);
            }
        }

        update_widget_state ();
    }

    private void add_media (Gee.Collection<Media> new_media) requires (data_initialized) {
        if (new_media.is_empty)
            return;

        if (has_list_view) {
            lock (list_view) {
                list_view.add_media (new_media);
            }
        }

        if (has_grid_view) {
            lock (grid_view) {
                grid_view.add_media (new_media);
            }
        }

        update_widget_state ();
    }

    private void remove_media (Gee.Collection<Media> media) requires (data_initialized) {
        if (media.is_empty)
            return;

        debug ("REMOVING MEDIA [%s]", hint.to_string ());

        if (has_list_view) {
            lock (list_view) {
                list_view.remove_media (media);
            }
        }

        if (has_grid_view) {
            lock (grid_view) {
                grid_view.remove_media (media);
            }
        }

        update_widget_state ();
    }

    private void update_widget_state () {
        check_have_media ();

        // Update view wrapper state
        if (is_current_wrapper)
            update_library_window_widgets ();
    }
}
