/*-
 * Copyright (c) 2011-2012       Corentin Noël <tintou@mailoo.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

// Add an interface so that SourceListItem and SourceListExpandableItem still share a common
// ancestor that is compatible with the SourceList widget.
public interface Noise.SourceListEntry : Granite.Widgets.SourceList.Item {
}

/**
 * SourceList item. It stores the number of the corresponding page in the notebook widget.
 */
public class Noise.SourceListItem : Granite.Widgets.SourceList.Item, SourceListEntry,
                                    Granite.Widgets.SourceListDragDest
{
    public signal void playlist_rename_clicked (int page_number);
    public signal void playlist_edit_clicked (int page_number);
    public signal void playlist_remove_clicked (int page_number);
    public signal void playlist_save_clicked (int page_number);
    public signal void playlist_export_clicked (int page_number);
    public signal void playlist_media_added (int page_number, string[] media);

    public int page_number { get; set; default = -1; }
    public ViewWrapper.Hint hint;
    
    //for playlist right click
    Gtk.Menu playlistMenu;
    Gtk.MenuItem playlistRename;
    Gtk.MenuItem playlistEdit;
    Gtk.MenuItem playlistRemove;
    Gtk.MenuItem playlistSave;
    Gtk.MenuItem playlistExport;

    public SourceListItem (int page_number, string name, ViewWrapper.Hint hint, GLib.Icon icon, GLib.Icon? activatable_icon = null) {
        base (name);
        this.page_number = page_number;
        this.icon = icon;
        this.hint = hint;
        if (activatable_icon != null)
            this.activatable = activatable_icon;
        
        if (hint == ViewWrapper.Hint.PLAYLIST) {
            playlistMenu = new Gtk.Menu();
            playlistRename = new Gtk.MenuItem.with_label(_("Rename"));
            playlistRemove = new Gtk.MenuItem.with_label(_("Remove"));
            playlistExport = new Gtk.MenuItem.with_label(_("Export…"));
            playlistMenu.append(playlistRename);
            playlistMenu.append(playlistRemove);
            playlistMenu.append(playlistExport);
            playlistMenu.show_all ();
            playlistRename.activate.connect(() => {playlist_rename_clicked (page_number);});
            playlistRemove.activate.connect(() => {playlist_remove_clicked (page_number);});
            playlistExport.activate.connect(() => {playlist_export_clicked (page_number);});
        }
        if (hint == ViewWrapper.Hint.SMART_PLAYLIST) {
            playlistMenu = new Gtk.Menu();
            playlistRename = new Gtk.MenuItem.with_label(_("Rename"));
            playlistEdit = new Gtk.MenuItem.with_label(_("Edit…"));
            playlistRemove = new Gtk.MenuItem.with_label(_("Remove"));
            playlistExport = new Gtk.MenuItem.with_label(_("Export…"));
            playlistMenu.append(playlistRename);
            playlistMenu.append(playlistEdit);
            playlistMenu.append(playlistRemove);
            playlistMenu.append(playlistExport);
            playlistMenu.show_all ();
            playlistRename.activate.connect(() => {playlist_rename_clicked (page_number);});
            playlistEdit.activate.connect(() => {playlist_edit_clicked (page_number);});
            playlistRemove.activate.connect(() => {playlist_remove_clicked (page_number);});
            playlistExport.activate.connect(() => {playlist_export_clicked (page_number);});
        }
        if (hint == ViewWrapper.Hint.READ_ONLY_PLAYLIST) {
            playlistMenu = new Gtk.Menu();
            playlistSave = new Gtk.MenuItem.with_label(_("Save as Playlist"));
            playlistMenu.append(playlistSave);
            playlistExport = new Gtk.MenuItem.with_label(_("Export…"));
            playlistMenu.append(playlistExport);
            playlistMenu.show_all ();
            playlistSave.activate.connect(() => {playlist_save_clicked (page_number);});
            playlistExport.activate.connect(() => {playlist_export_clicked (page_number);});
        }
        
    }
    
    public override Gtk.Menu? get_context_menu () {
        if (playlistMenu != null) {
            if (playlistMenu.get_attach_widget () != null)
                playlistMenu.detach ();
            return playlistMenu;
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
    
    //for device right click
    Gtk.Menu deviceMenu;
    Gtk.MenuItem deviceImportToLibrary;
    Gtk.MenuItem deviceEject;
    Gtk.MenuItem deviceAddPlaylist;
    Gtk.MenuItem deviceAddSmartPlaylist;
    Gtk.MenuItem deviceSync;

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

        if (hint == ViewWrapper.Hint.DEVICE_AUDIO) {
            deviceMenu = new Gtk.Menu();
            deviceImportToLibrary = new Gtk.MenuItem.with_label(_("Import to Library"));
            deviceImportToLibrary.activate.connect (() => {device_import_clicked (page_number);});
            deviceMenu.append (deviceImportToLibrary);
            deviceMenu.show_all ();
        }

        if (hint == ViewWrapper.Hint.DEVICE) {
            deviceMenu = new Gtk.Menu();
            deviceEject = new Gtk.MenuItem.with_label (_("Eject"));
            deviceEject.activate.connect (() => {device_eject_clicked (page_number);});
            if (give_more_information is Device) {
                var device = (Device)give_more_information;
                if (device.get_library ().support_playlists ()) {
                    deviceAddPlaylist = new Gtk.MenuItem.with_label (_("New Playlist"));
                    deviceAddPlaylist.activate.connect (() => {device_new_playlist_clicked (page_number);});
                    deviceMenu.append (deviceAddPlaylist);
                }
                if (device.get_library ().support_smart_playlists ()) {
                    deviceAddSmartPlaylist = new Gtk.MenuItem.with_label (_("New Smart Playlist"));
                    deviceAddSmartPlaylist.activate.connect (() => {device_new_smartplaylist_clicked (page_number);});
                    deviceMenu.append (deviceAddSmartPlaylist);
                }
                if (device.read_only() == false) {
                    deviceSync = new Gtk.MenuItem.with_label (_("Sync"));
                    deviceSync.activate.connect (() => {device_sync_clicked (page_number);});
                    deviceMenu.append (deviceSync);
                }
            }
            deviceMenu.append (deviceEject);
            deviceMenu.show_all ();
        }
    }
    
    public override Gtk.Menu? get_context_menu () {
        return deviceMenu;
    }
}

public class Noise.PlayListCategory : Granite.Widgets.SourceList.ExpandableItem,
                                      Granite.Widgets.SourceListSortable
{
    //for playlist right click
    Gtk.Menu playlistMenu;
    Gtk.MenuItem playlistNew;
    Gtk.MenuItem smartPlaylistNew;
    Gtk.MenuItem playlistImport;
    public signal void playlist_import_clicked ();

    public PlayListCategory (string name) {
        base (name);
        
        //playlist right click menu
        playlistMenu = new Gtk.Menu();
        playlistNew = new Gtk.MenuItem.with_label(_("New Playlist"));
        smartPlaylistNew = new Gtk.MenuItem.with_label(_("New Smart Playlist"));
        playlistImport = new Gtk.MenuItem.with_label(_("Import Playlists"));
        
        playlistMenu.append(playlistNew);
        playlistMenu.append(smartPlaylistNew);
        playlistMenu.append(playlistImport);
        playlistMenu.show_all ();
        
        playlistNew.activate.connect(() => {App.main_window.create_new_playlist ();});
        smartPlaylistNew.activate.connect(() => {App.main_window.show_smart_playlist_dialog ();});
        playlistImport.activate.connect(() => {playlist_import_clicked ();});
    }

    public override Gtk.Menu? get_context_menu () {
        return playlistMenu;
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

public class Noise.SourceListRoot : Granite.Widgets.SourceList.ExpandableItem,
                                    Granite.Widgets.SourceListSortable
{
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
