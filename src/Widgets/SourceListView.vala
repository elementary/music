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
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

// Add an interface so that SourceListItem and SourceListExpandableItem still share a common
// ancestor that is compatible with the SourceList widget.
public interface Noise.SourceListEntry : Granite.Widgets.SourceList.Item {
}

/**
 * SourceList item. It stores the number of the corresponding page in the notebook widget.
 */
public class Noise.SourceListItem : Granite.Widgets.SourceList.Item, SourceListEntry, Granite.Widgets.SourceListDragDest {
    public signal void playlist_rename_clicked (int page_number);
    public signal void playlist_edit_clicked (int page_number);
    public signal void playlist_remove_clicked (int page_number);
    public signal void playlist_save_clicked (int page_number);
    public signal void playlist_export_clicked (int page_number);
    public signal void playlist_media_added (int page_number, string[] media);

    public int page_number { get; set; default = -1; }
    public ViewWrapper.Hint hint { get; construct; }
    public GLib.Icon? activatable_icon { get; construct; }

    private Gtk.Menu playlist_menu;

    public SourceListItem (int page_number, string name, ViewWrapper.Hint hint, GLib.Icon icon, GLib.Icon? activatable_icon = null) {
        Object (
            activatable_icon: activatable_icon,
            hint: hint,
            icon: icon,
            name: name,
            page_number: page_number
        );
    }

    construct {
        playlist_menu = new Gtk.Menu ();

        switch (hint) {
            case ViewWrapper.Hint.PLAYLIST:
                var playlist_rename = new Gtk.MenuItem.with_label (_("Rename"));
                var playlist_remove = new Gtk.MenuItem.with_label (_("Remove"));
                playlist_menu.append (playlist_rename);
                playlist_menu.append (playlist_remove);
                playlist_rename.activate.connect (() => {
                    playlist_rename_clicked (page_number);
                });
                playlist_remove.activate.connect (() => {
                    playlist_remove_clicked (page_number);
                });
                break;
            case ViewWrapper.Hint.SMART_PLAYLIST:
                var playlist_rename = new Gtk.MenuItem.with_label (_("Rename"));
                var playlist_edit = new Gtk.MenuItem.with_label (_("Edit…"));
                var playlist_remove = new Gtk.MenuItem.with_label (_("Remove"));
                playlist_menu.append (playlist_rename);
                playlist_menu.append (playlist_edit);
                playlist_menu.append (playlist_remove);
                playlist_rename.activate.connect (() => {
                    playlist_rename_clicked (page_number);
                });
                playlist_edit.activate.connect (() => {
                    playlist_edit_clicked (page_number);
                });
                playlist_remove.activate.connect (() => {
                    playlist_remove_clicked (page_number);
                });
                break;
            case ViewWrapper.Hint.READ_ONLY_PLAYLIST:
                var playlist_save = new Gtk.MenuItem.with_label (_("Save as Playlist"));
                playlist_menu.append (playlist_save);
                playlist_save.activate.connect (() => {
                    playlist_save_clicked (page_number);
                });
                break;
        }

        var playlist_export = new Gtk.MenuItem.with_label (_("Export…"));
        playlist_export.activate.connect (() => {
            playlist_export_clicked (page_number);
        });

        playlist_menu.append (playlist_export);
        playlist_menu.show_all ();
    }

    public override Gtk.Menu? get_context_menu () {
        if (playlist_menu != null) {
            if (playlist_menu.get_attach_widget () != null) {
                playlist_menu.detach ();
            }
            return playlist_menu;
        }
        return null;
    }

    public bool data_drop_possible (Gdk.DragContext context, Gtk.SelectionData data) {
        // TODO: need a 'hint' for for QUEUE more specific than READ_ONLY_PLAYLIST
        return hint == ViewWrapper.Hint.PLAYLIST
            && data.get_target () == Gdk.Atom.intern_static_string ("text/uri-list");
    }

    public Gdk.DragAction data_received (Gdk.DragContext context, Gtk.SelectionData data) {
        playlist_media_added (page_number, data.get_uris ());
        return Gdk.DragAction.COPY;
    }
}

public class Noise.SourceListExpandableItem : Granite.Widgets.SourceList.ExpandableItem, SourceListEntry {
    public int page_number { get; set; default = -1; }
    public ViewWrapper.Hint hint;

    private Gtk.Menu device_menu;

    public signal void device_import_clicked (int page_number);
    public signal void device_eject_clicked (int page_number);
    public signal void device_sync_clicked (int page_number);
    public signal void device_new_playlist_clicked (int page_number);
    public signal void device_new_smartplaylist_clicked (int page_number);

    public SourceListExpandableItem (int page_number, string name, ViewWrapper.Hint hint, GLib.Icon icon, GLib.Icon? activatable_icon = null, Object? give_more_information = null) {
        base (name);
        this.page_number = page_number;
        this.icon = icon;
        this.hint = hint;
        if (activatable_icon != null)
            this.activatable = activatable_icon;

        device_menu = new Gtk.Menu ();

        if (hint == ViewWrapper.Hint.DEVICE_AUDIO) {
            var import_menuitem = new Gtk.MenuItem.with_label(_("Import to Library"));
            import_menuitem.activate.connect (() => {
                device_import_clicked (page_number);
            });

            device_menu.append (import_menuitem);
        }

        if (hint == ViewWrapper.Hint.DEVICE) {
            var eject_menuitem = new Gtk.MenuItem.with_label (_("Eject"));
            eject_menuitem.activate.connect (() => {
                device_eject_clicked (page_number);
            });

            if (give_more_information is Device) {
                var device = (Device) give_more_information;
                var device_library = device.get_library ();

                if (device_library.support_playlists ()) {
                    var add_playlist_menuitem = new Gtk.MenuItem.with_label (_("New Playlist"));
                    add_playlist_menuitem.activate.connect (() => {
                        device_new_playlist_clicked (page_number);
                    });
                    device_menu.append (add_playlist_menuitem);
                }

                if (device_library.support_smart_playlists ()) {
                    var add_smart_playlist_menuitem = new Gtk.MenuItem.with_label (_("New Smart Playlist"));
                    add_smart_playlist_menuitem.activate.connect (() => {
                        device_new_smartplaylist_clicked (page_number);
                    });
                    device_menu.append (add_smart_playlist_menuitem);
                }

                if (device.read_only() == false) {
                    var sync_menuitem = new Gtk.MenuItem.with_label (_("Sync"));
                    sync_menuitem.activate.connect (() => {
                        device_sync_clicked (page_number);
                    });
                    device_menu.append (sync_menuitem);
                }
            }
            device_menu.append (eject_menuitem);
        }

        device_menu.show_all ();
    }

    public override Gtk.Menu? get_context_menu () {
        return device_menu;
    }
}

public class Noise.PlayListCategory : Granite.Widgets.SourceList.ExpandableItem, Granite.Widgets.SourceListSortable {
    private Gtk.Menu playlist_menu;
    public signal void playlist_import_clicked ();

    public PlayListCategory (string name) {
        Object (name: name);
    }

    construct {
        var playlist_new = new Gtk.MenuItem.with_label (_("New Playlist"));
        var smart_playlist_new = new Gtk.MenuItem.with_label (_("New Smart Playlist"));
        var playlist_import = new Gtk.MenuItem.with_label (_("Import Playlists"));

        playlist_menu = new Gtk.Menu ();
        playlist_menu.append (playlist_new);
        playlist_menu.append (smart_playlist_new);
        playlist_menu.append (playlist_import);
        playlist_menu.show_all ();

        playlist_new.activate.connect (() => {
            App.main_window.create_new_playlist ();
        });

        smart_playlist_new.activate.connect (() => {
            App.main_window.show_smart_playlist_dialog ();
        });

        playlist_import.activate.connect (() => {
            playlist_import_clicked ();
        });
    }

    public override Gtk.Menu? get_context_menu () {
        return playlist_menu;
    }

    // implement Sortable interface
    public bool allow_dnd_sorting () {
        return true;
    }

    public int compare (Granite.Widgets.SourceList.Item a, Granite.Widgets.SourceList.Item b) {
        var item_a = a as SourceListItem;
        var item_b = b as SourceListItem;

        if (item_a == null || item_b == null)
            return 0;

        if (item_a.hint == ViewWrapper.Hint.READ_ONLY_PLAYLIST) {
            // sort read-only playlists alphabetically
            if (item_b.hint == ViewWrapper.Hint.READ_ONLY_PLAYLIST)
                return strcmp (item_a.name.collate_key (), item_b.name.collate_key ());

            // place read-only playlists before any item of different kind
            return -1;
        }

        if (item_a.hint == ViewWrapper.Hint.SMART_PLAYLIST) {
            // place smart playlists after read-only playlists
            if (item_b.hint == ViewWrapper.Hint.READ_ONLY_PLAYLIST)
                return 1;

            // allow free sorting between smart playlists (users can move them around)
            if (item_b.hint == ViewWrapper.Hint.SMART_PLAYLIST)
                return 0;

            // place smart playlists before static playlists
            if (item_b.hint == ViewWrapper.Hint.PLAYLIST)
                return -1;
        }

        if (item_a.hint == ViewWrapper.Hint.PLAYLIST) {
            // allow free sorting between static playlists (users can move them around)
            if (item_b.hint == ViewWrapper.Hint.PLAYLIST)
                return 0;

            // place static playlists after everything else
            return 1;
        }

        return 0;
    }
}

public class Noise.SourceListRoot : Granite.Widgets.SourceList.ExpandableItem, Granite.Widgets.SourceListSortable {
    public SourceListRoot () {
        base ("SourceListRoot");
    }

    public bool allow_dnd_sorting () {
        return true;
    }

    public int compare (Granite.Widgets.SourceList.Item a, Granite.Widgets.SourceList.Item b) {
        return 0;
    }
}

public class Noise.SourceListView : Granite.Widgets.SourceList {

    Granite.Widgets.SourceList.ExpandableItem library_category;
    Granite.Widgets.SourceList.ExpandableItem devices_category;
    Granite.Widgets.SourceList.ExpandableItem network_category;
    PlayListCategory playlists_category;

    public signal void edited (int page_number, string new_name);
    public signal void item_action_activated (int page_number);
    public signal void selection_changed (int page_number);
    public signal void activated ();

    public signal void playlist_rename_clicked (int page_number);
    public signal void playlist_edit_clicked (int page_number);
    public signal void playlist_remove_clicked (int page_number);
    public signal void playlist_save_clicked (int page_number);
    public signal void playlist_export_clicked (int page_number);
    public signal void playlist_import_clicked ();
    public signal void playlist_media_added (int page_number, string[] uris);

    public signal void device_import_clicked (int page_number);
    public signal void device_eject_clicked (int page_number);
    public signal void device_sync_clicked (int page_number);
    public signal void device_new_playlist_clicked (int page_number);
    public signal void device_new_smartplaylist_clicked (int page_number);

    public SourceListView () {
        base (new SourceListRoot ());

        // Adds the different sidebar categories.
        library_category = new Granite.Widgets.SourceList.ExpandableItem (_("Library"));
        devices_category = new Granite.Widgets.SourceList.ExpandableItem (_("Devices"));
        network_category = new Granite.Widgets.SourceList.ExpandableItem (_("Network"));
        playlists_category = new PlayListCategory (_("Playlists"));
        playlists_category.playlist_import_clicked.connect (() => {playlist_import_clicked ();});
        this.root.add (library_category);
        this.root.add (devices_category);
        this.root.add (network_category);
        this.root.add (playlists_category);
        this.root.expand_all (false, false);

        Gtk.TargetEntry uri_list_entry = { "text/uri-list", Gtk.TargetFlags.SAME_APP, 0 };
        enable_drag_dest ({ uri_list_entry }, Gdk.DragAction.COPY);
    }

    /**
     * Change the visibility of each category
     */

    public void change_playlist_category_visibility (bool visible) {
        playlists_category.visible = visible;
    }

    /**
     * Adds an item to the sidebar for the ViewWrapper object.
     * It chooses the appropiate category based on the object's hint property.
     *
     * TODO: Change ViewWrapper.Hint to core values.
     */
    public SourceListEntry add_item (int page_number,
                        string name,
                        ViewWrapper.Hint hint,
                        GLib.Icon icon,
                        GLib.Icon? activatable_icon = null,
                        SourceListExpandableItem? into_expandable = null, Object? give_more_information = null) {

        // Initialize all widgets
        var sourcelist_item = new SourceListItem (page_number, name, hint, icon, activatable_icon);
        var expandable_item = new SourceListExpandableItem (page_number, name, hint, icon, activatable_icon, give_more_information);

        if (hint == ViewWrapper.Hint.DEVICE) {
            expandable_item.collapsible = false;
            expandable_item.icon = icon;
            if (activatable_icon != null)
                expandable_item.activatable = activatable_icon;
        }

        // Connect to signals
        sourcelist_item.activated.connect (() => {activated ();});
        sourcelist_item.edited.connect ((new_name) => {this.edited (sourcelist_item.page_number, new_name);});
        expandable_item.action_activated.connect ((sl) => {this.item_action_activated (sourcelist_item.page_number);});
        sourcelist_item.playlist_rename_clicked.connect ((pn) => {playlist_rename_clicked (pn);});
        sourcelist_item.playlist_edit_clicked.connect ((pn) => {playlist_edit_clicked (pn);});
        sourcelist_item.playlist_remove_clicked.connect ((pn) => {playlist_remove_clicked (pn);});
        sourcelist_item.playlist_save_clicked.connect ((pn) => {playlist_save_clicked (pn);});
        sourcelist_item.playlist_export_clicked.connect ((pn) => {playlist_export_clicked (pn);});
        sourcelist_item.playlist_media_added.connect ((pn, uris) => {playlist_media_added (pn, uris);});

        expandable_item.device_import_clicked.connect ((pn) => {device_import_clicked (get_device_from_item(expandable_item));});
        expandable_item.device_eject_clicked.connect ((pn) => {device_eject_clicked (pn);});
        expandable_item.device_sync_clicked.connect ((pn) => {device_sync_clicked (pn);});
        expandable_item.device_new_playlist_clicked.connect ((pn) => {device_new_playlist_clicked (pn);});
        expandable_item.device_new_smartplaylist_clicked.connect ((pn) => {device_new_smartplaylist_clicked (pn);});

        switch (hint) {
            case ViewWrapper.Hint.MUSIC:
                if (into_expandable == null) {
                    library_category.add (sourcelist_item);
                } else {
                    into_expandable.add (sourcelist_item);
                }
                break;
            case ViewWrapper.Hint.PLAYLIST:
                if (into_expandable == null) {
                    sourcelist_item.editable = true;
                    playlists_category.add (sourcelist_item);
                } else {
                    sourcelist_item.editable = true;
                    into_expandable.add (sourcelist_item);
                }
                break;
            case ViewWrapper.Hint.READ_ONLY_PLAYLIST:
                if (into_expandable == null) {
                    sourcelist_item.editable = false;
                    playlists_category.add (sourcelist_item);
                } else {
                    sourcelist_item.editable = false;
                    into_expandable.add (sourcelist_item);
                }
                break;
            case ViewWrapper.Hint.SMART_PLAYLIST:
                if (into_expandable == null) {
                    sourcelist_item.editable = true;
                    playlists_category.add (sourcelist_item);
                } else {
                    into_expandable.add (sourcelist_item);
                }
                break;
            case ViewWrapper.Hint.DEVICE:
                if (into_expandable == null) {
                    devices_category.add (expandable_item);
                } else {
                    into_expandable.add (expandable_item);
                }
                break;
            case ViewWrapper.Hint.DEVICE_AUDIO:
                if (into_expandable == null) {
                    devices_category.add (expandable_item);
                } else {
                    into_expandable.add (expandable_item);
                }
                break;
            case ViewWrapper.Hint.NETWORK_DEVICE:
                if (into_expandable == null) {
                    network_category.add (sourcelist_item);
                } else {
                    into_expandable.add (sourcelist_item);
                }
                break;
            default:
                break;
        }

        if (hint == ViewWrapper.Hint.DEVICE) {
            return expandable_item;
        } else {
            return sourcelist_item;
        }
    }

    public override void item_selected (Granite.Widgets.SourceList.Item? item) {
        if (item is Noise.SourceListItem) {
            var sidebar_item = item as SourceListItem;
            selection_changed (sidebar_item.page_number);
        } else if (item is Noise.SourceListExpandableItem) {
            var sidebar_item = item as SourceListExpandableItem;
            selection_changed (sidebar_item.page_number);
        }
    }

    // removes the playlist from menu
    public void remove_playlist (int page_number) {
        foreach (var playlist in playlists_category.children) {
            if (playlist is SourceListItem) {
                if (page_number == ((SourceListItem)playlist).page_number) {
                    playlists_category.remove (playlist);
                    return;
                }
            }
        }
        var items = new Gee.TreeSet<SourceListItem> ();
        foreach (var device in devices_category.children) {
            if (device is SourceListExpandableItem) {
                enumerate_children_items ((SourceListExpandableItem)device, ref items);
                foreach (var item in items) {
                    if (item.page_number == page_number) {
                        item.parent.remove (item);
                        return;
                    }
                }
            }
        }
    }

    // removes the device from menu
    public Gee.Collection<int> remove_device (int page_number) {
        var pages = new Gee.TreeSet<int>();
        foreach (var device in devices_category.children) {
            if (device is SourceListExpandableItem) {
                if (page_number == ((SourceListExpandableItem)device).page_number) {
                    enumerate_children_pages((SourceListExpandableItem)device, ref pages);
                    devices_category.remove (device);
                    return pages;
                }
            }
        }
        return pages;
    }

    // get the device page_number associated to the view
    public int get_device_from_item (Noise.SourceListExpandableItem item) {
        foreach (var device in devices_category.children) {
            if (item.parent == (Granite.Widgets.SourceList.ExpandableItem)device) {
                if (device is SourceListExpandableItem) {
                    return ((SourceListExpandableItem)device).page_number;
                }
            }
        }
        return -1;
    }

    public void enumerate_children_pages (SourceListExpandableItem exp_item, ref Gee.TreeSet<int> pages) {
        foreach (var views in ((SourceListExpandableItem)exp_item).children) {
            if (views is SourceListExpandableItem) {
                pages.add (((SourceListExpandableItem)views).page_number);
                enumerate_children_pages ((SourceListExpandableItem)views, ref pages);
            } else if (views is SourceListItem) {
                pages.add (((SourceListItem)views).page_number);
            }
        }
    }

    public void enumerate_children_items (SourceListExpandableItem exp_item, ref Gee.TreeSet<SourceListItem> pages) {
        foreach (var views in ((SourceListExpandableItem)exp_item).children) {
            if (views is SourceListExpandableItem) {
                enumerate_children_items ((SourceListExpandableItem)views, ref pages);
            } else if (views is SourceListItem) {
                pages.add (((SourceListItem)views));
            }
        }
    }

    // change the name shown
    public void change_playlist_name (int page_number, string new_name) {
        foreach (var playlist in playlists_category.children) {
            if (playlist is SourceListItem) {
                if (page_number == ((SourceListItem)playlist).page_number) {
                    ((SourceListItem)playlist).name = new_name;
                    return;
                }
            }
        }
        var items = new Gee.TreeSet<SourceListItem> ();
        foreach (var device in devices_category.children) {
            if (device is SourceListExpandableItem) {
                enumerate_children_items ((SourceListExpandableItem)device, ref items);
                foreach (var item in items) {
                    if (item.page_number == page_number) {
                        ((SourceListItem)item).name = new_name;
                        return;
                    }
                }
            }
        }
    }

    // change the name shown
    public void change_device_name (int page_number, string new_name) {
        foreach (var device in devices_category.children) {
            if (device is SourceListItem) {
                if (page_number == ((SourceListItem)device).page_number) {
                    ((SourceListItem)device).name = new_name;
                    return;
                }
            }
        }
    }
}
