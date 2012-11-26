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

/**
 * SourceList item. It stores the number of the corresponding page in the notebook widget.
 */
public class Noise.SourceListItem : Granite.Widgets.SourceList.Item {
    
    public signal void playlist_edit_clicked (int page_number);
    public signal void playlist_remove_clicked (int page_number);
    public signal void playlist_save_clicked (int page_number);
    public signal void playlist_export_clicked (int page_number);
    public int page_number { get; set; default = -1; }
    public ViewWrapper.Hint hint;
    
    //for playlist right click
    Gtk.Menu playlistMenu;
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
            playlistRemove = new Gtk.MenuItem.with_label(_("Remove"));
            playlistExport = new Gtk.MenuItem.with_label(_("Export..."));
            playlistMenu.append(playlistRemove);
            playlistMenu.append(playlistExport);
            playlistMenu.show_all ();
            playlistRemove.activate.connect(() => {playlist_remove_clicked (page_number);});
            playlistExport.activate.connect(() => {playlist_export_clicked (page_number);});
        }
        if (hint == ViewWrapper.Hint.SMART_PLAYLIST) {
            playlistMenu = new Gtk.Menu();
            playlistEdit = new Gtk.MenuItem.with_label(_("Edit"));
            playlistRemove = new Gtk.MenuItem.with_label(_("Remove"));
            playlistExport = new Gtk.MenuItem.with_label(_("Export..."));
            playlistMenu.append(playlistEdit);
            playlistMenu.append(playlistRemove);
            playlistMenu.append(playlistExport);
            playlistMenu.show_all ();
            playlistEdit.activate.connect(() => {playlist_edit_clicked (page_number);});
            playlistRemove.activate.connect(() => {playlist_remove_clicked (page_number);});
            playlistExport.activate.connect(() => {playlist_export_clicked (page_number);});
        }
        if (hint == ViewWrapper.Hint.READ_ONLY_PLAYLIST) {
            playlistMenu = new Gtk.Menu();
            playlistSave = new Gtk.MenuItem.with_label(_("Save as Playlist"));
            playlistMenu.append(playlistSave);
            playlistExport = new Gtk.MenuItem.with_label(_("Export..."));
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
}

public class Noise.SourceListExpandableItem : Granite.Widgets.SourceList.ExpandableItem {
    public int page_number { get; set; default = -1; }
    public ViewWrapper.Hint hint;
    
    //for device right click
    Gtk.Menu deviceMenu;
    Gtk.MenuItem deviceImportToLibrary;
    Gtk.MenuItem deviceEject;

    public signal void device_import_clicked (int page_number);
    public signal void device_eject_clicked (int page_number);

    public SourceListExpandableItem (int page_number, string name, ViewWrapper.Hint hint, GLib.Icon icon, GLib.Icon? activatable_icon = null) {
        base (name);
        this.page_number = page_number;
        this.icon = icon;
        this.hint = hint;
        if (activatable_icon != null)
            this.activatable = activatable_icon;

        if (hint == ViewWrapper.Hint.DEVICE_AUDIO) {
            deviceMenu = new Gtk.Menu();
            deviceImportToLibrary = new Gtk.MenuItem.with_label(_("Import to Library"));
            deviceMenu.append (deviceImportToLibrary);
            deviceImportToLibrary.activate.connect (() => {device_import_clicked (page_number);});
            deviceMenu.show_all ();
        }

        if (hint == ViewWrapper.Hint.DEVICE) {
            deviceMenu = new Gtk.Menu();
            deviceEject = new Gtk.MenuItem.with_label(_("Eject"));
            deviceEject.activate.connect (() => {device_eject_clicked (page_number);});
            deviceMenu.append (deviceEject);
            deviceMenu.show_all ();
        }
    }
    
    public override Gtk.Menu? get_context_menu () {
        if (deviceMenu != null) {
            if (deviceMenu.get_attach_widget () != null)
                deviceMenu.detach ();
            return deviceMenu;
        }
        return null;
    }
    
}

public class Noise.PlayListCategory : Granite.Widgets.SourceList.ExpandableItem {
    
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
        
        playlistNew.activate.connect(App.main_window.create_new_playlist);
        smartPlaylistNew.activate.connect(() => {App.main_window.show_smart_playlist_dialog ();});
        playlistImport.activate.connect(() => {playlist_import_clicked ();});
    }
    
    public override Gtk.Menu? get_context_menu () {
        if (playlistMenu != null) {
            if (playlistMenu.get_attach_widget () != null)
                playlistMenu.detach ();
            return playlistMenu;
        }
        return null;
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
    
    public signal void playlist_edit_clicked (int page_number);
    public signal void playlist_remove_clicked (int page_number);
    public signal void playlist_save_clicked (int page_number);
    public signal void playlist_export_clicked (int page_number);
    public signal void playlist_import_clicked ();
    
    public signal void device_import_clicked (int page_number);
    public signal void device_eject_clicked (int page_number);

    public SourceListView () {
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
    public Granite.Widgets.SourceList.Item add_item (int page_number,
                        string name,
                        ViewWrapper.Hint hint,
                        GLib.Icon icon,
                        GLib.Icon? activatable_icon = null,
                        SourceListExpandableItem? into_expandable = null) {
        
        // Initialize all widgets
        var sourcelist_item = new SourceListItem (page_number, name, hint, icon, activatable_icon);
        var expandable_item = new SourceListExpandableItem (page_number, name, hint, icon, activatable_icon);
        
        if (hint == ViewWrapper.Hint.DEVICE) {
            expandable_item.collapsible = false;
            expandable_item.icon = icon;
            if (activatable_icon != null)
                expandable_item.activatable = activatable_icon;
        }
        
        // Connect to signals
        sourcelist_item.edited.connect ((new_name) => {this.edited (sourcelist_item.page_number, new_name);});
        expandable_item.action_activated.connect ((sl) => {this.item_action_activated (sourcelist_item.page_number);});
        sourcelist_item.playlist_edit_clicked.connect ((pn) => {playlist_edit_clicked (pn);});
        sourcelist_item.playlist_remove_clicked.connect ((pn) => {playlist_remove_clicked (pn);});
        sourcelist_item.playlist_save_clicked.connect ((pn) => {playlist_save_clicked (pn);});
        sourcelist_item.playlist_export_clicked.connect ((pn) => {playlist_export_clicked (pn);});
        
        expandable_item.device_import_clicked.connect ((pn) => {device_import_clicked (pn);});
        expandable_item.device_eject_clicked.connect ((pn) => {device_eject_clicked (pn);});
    
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
                    into_expandable.add (sourcelist_item);
                }
                break;
            case ViewWrapper.Hint.READ_ONLY_PLAYLIST:
                if (into_expandable == null) {
                    sourcelist_item.editable = false;
                    playlists_category.add (sourcelist_item);
                } else {
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
    }
    
    // removes the device from menu
    public Gee.LinkedList<int> remove_device (int page_number) {
        var pages = new Gee.LinkedList<int>();
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
    
    public void enumerate_children_pages (SourceListExpandableItem exp_item, ref Gee.LinkedList<int> pages) {
        foreach (var views in ((SourceListExpandableItem)exp_item).children) {
            if (views is SourceListExpandableItem) {
                pages.add (((SourceListExpandableItem)views).page_number);
                enumerate_children_pages ((SourceListExpandableItem)views, ref pages);
            } else if (views is SourceListItem) {
                pages.add (((SourceListItem)views).page_number);
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
