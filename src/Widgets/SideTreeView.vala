/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
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

using Gtk;
using Gee;


public class Noise.SideTreeView : Granite.Widgets.SideBar {
    LibraryManager lm;
    LibraryWindow lw;
    
    public TreeIter library_iter {get; private set;}
    public TreeIter library_music_iter {get; private set;}
    public TreeIter library_audiobooks_iter {get; private set;}

    public TreeIter devices_iter {get; private set;}
    public TreeIter devices_cdrom_iter {get; private set;}
    
    public TreeIter network_iter {get; private set;}
    public TreeIter network_devices_iter {get; private set;}

    public TreeIter playlists_iter {get; private set;}
    public TreeIter playlists_queue_iter {get; private set;}
    public TreeIter playlists_history_iter {get; private set;}
    public TreeIter playlists_similar_iter {get; private set;}

    //for device right click
    Gtk.Menu deviceMenu;
    Gtk.MenuItem deviceImportToLibrary;
    Gtk.MenuItem deviceSync;
    Gtk.MenuItem deviceEject;
    
    //for playlist right click
    Gtk.Menu playlistMenu;
    Gtk.MenuItem playlistNew;
    Gtk.MenuItem smartPlaylistNew;
    Gtk.MenuItem playlistEdit;
    Gtk.MenuItem playlistRemove;
    Gtk.MenuItem playlistSave;
    Gtk.MenuItem playlistExport;
    Gtk.MenuItem playlistImport;

    public SideTreeView(LibraryManager lmm, LibraryWindow lww) {
        this.lm = lmm;
        this.lw = lww;
        
        buildUI();
    }

    private void buildUI() {

        deviceImportToLibrary = new Gtk.MenuItem.with_label(_("Import to Library"));
        deviceImportToLibrary.activate.connect (deviceImportToLibraryClicked);

        deviceSync = new Gtk.MenuItem.with_label(_("Sync"));
        deviceSync.activate.connect (deviceSyncClicked);

        deviceEject = new Gtk.MenuItem.with_label(_("Eject"));
        deviceEject.activate.connect (deviceEjectClicked);

        deviceMenu = new Gtk.Menu();
        deviceMenu.append (deviceImportToLibrary);
        deviceMenu.append (deviceSync);
        deviceMenu.append (deviceEject);
        deviceMenu.show_all ();
        
        //playlist right click menu
        playlistMenu = new Gtk.Menu();
        playlistNew = new Gtk.MenuItem.with_label(_("New Playlist"));
        smartPlaylistNew = new Gtk.MenuItem.with_label(_("New Smart Playlist"));
        playlistEdit = new Gtk.MenuItem.with_label(_("Edit"));
        playlistRemove = new Gtk.MenuItem.with_label(_("Remove"));
        playlistSave = new Gtk.MenuItem.with_label(_("Save as Playlist"));
        playlistExport = new Gtk.MenuItem.with_label(_("Export..."));
        playlistImport = new Gtk.MenuItem.with_label(_("Import Playlists"));
        playlistMenu.append(playlistNew);
        playlistMenu.append(smartPlaylistNew);
        playlistMenu.append(playlistEdit);
        playlistMenu.append(playlistRemove);
        playlistMenu.append(playlistSave);
        playlistMenu.append(playlistExport);
        playlistMenu.append(playlistImport);
        playlistNew.activate.connect(playlistMenuNewClicked);
        smartPlaylistNew.activate.connect(smartPlaylistMenuNewClicked);
        playlistEdit.activate.connect(playlistMenuEditClicked);
        playlistRemove.activate.connect(playlistMenuRemoveClicked);
        playlistSave.activate.connect(playlistSaveClicked);
        playlistExport.activate.connect(playlistExportClicked);
        playlistImport.activate.connect(()=>{playlistImportClicked ();});
        playlistMenu.show_all();
        
        this.button_press_event.connect(sideListClick);
        this.row_activated.connect(sideListDoubleClick);
        this.true_selection_change.connect(sideListSelectionChange);
        this.clickable_clicked.connect(clickableClicked);
        this.expand_all();
        
        #if 0
        /* set up drag dest stuff */
        drag_dest_set(this, DestDefaults.ALL, {}, Gdk.DragAction.MOVE);
        Gtk.drag_dest_add_uri_targets(this);
        this.drag_data_received.connect(dragReceived);
        #endif
        addBasicItems ();

        //destroy.connect (on_destroy);
    }

    /**
     * Adds the different sidebar categories.
     */
    private void addBasicItems() {
        library_iter = addItem(null, null, null, null, _("Library"), null);
        devices_iter = addItem(null, null, null, null, _("Devices"), null);
        network_iter = addItem(null, null, null, null, _("Network"), null);
        playlists_iter = addItem(null, null, null, null, _("Playlists"), null);
    }

#if 0
    private void on_destroy () {
        // Save state
        lw.settings.set_sidebar_library_item_expanded (item_expanded (library_iter));
        lw.settings.set_sidebar_playlists_item_expanded (item_expanded (playlists_iter));
    }
#endif

    /**
     * Adds an item to the sidebar for the ViewWrapper object.
     * It chooses the appropiate category based on the object's hint property.
     *
     * FIXME: Add option to pass an icon (needed by plugins).
     */
    public TreeIter? add_item (ViewWrapper view_wrapper, string name) {
        TreeIter? sidebar_category_iter = null;

        // Decide which category to use
        switch (view_wrapper.hint) {
            case ViewWrapper.Hint.SIMILAR:
            case ViewWrapper.Hint.QUEUE:
            case ViewWrapper.Hint.HISTORY:
                sidebar_category_iter = playlists_iter;
                break;
            case ViewWrapper.Hint.MUSIC:
                sidebar_category_iter = library_iter;
                break;
            case ViewWrapper.Hint.NONE:
                sidebar_category_iter = network_iter;
                break;
            case ViewWrapper.Hint.DEVICE_AUDIO:
            case ViewWrapper.Hint.DEVICE_AUDIOBOOK:
            case ViewWrapper.Hint.NETWORK_DEVICE:
                sidebar_category_iter = network_iter;
                break;
            case ViewWrapper.Hint.CDROM:
                sidebar_category_iter = devices_iter;
                break;
            default:
                sidebar_category_iter = playlists_iter;
                break;
        }

        return addSideItem (sidebar_category_iter, null, view_wrapper, name, view_wrapper.hint);
    }

    /**
     * Adds an item to the sidebar. Unless you need a very exotic view, you shouldn't
     * use this method directly.
     */
    public TreeIter? addSideItem(TreeIter? parent, GLib.Object? o, Widget w, string name, ViewWrapper.Hint hint) {

        if(hint == ViewWrapper.Hint.MUSIC && parent == library_iter) {
            var music_icon = Icons.MUSIC.render (IconSize.MENU, null);
            library_music_iter = addItem(parent, o, w, music_icon, name, null);
            return library_music_iter;
        }
/*
        else if(hint == ViewWrapper.Hint.AUDIOBOOK && parent == library_iter) {
            // FIXME: add icon
            var audiobook_icon = Icons.AUDIOBOOK.render (IconSize.MENU, null);
            library_audiobooks_iter = addItem(parent, o, w, audiobook_icon, name, null);
            return library_audiobooks_iter;
        }
*/
        else if(o is Device && parent == devices_iter) {
            Device d = (Device)o;
            TreeIter? rv;
            Gdk.Pixbuf device_icon = d.get_icon();
            
            if (device_icon == null) {
                device_icon = Icons.AUDIO_DEVICE.render (Gtk.IconSize.MENU, null);
            }

            rv = addItem(parent, o, w, device_icon, name, Icons.EJECT_SYMBOLIC.render(IconSize.MENU, this.get_style_context ()));

            var dvw = new DeviceViewWrapper(lw, new TreeViewSetup(ListColumn.ARTIST, SortType.ASCENDING, ViewWrapper.Hint.DEVICE_AUDIO), d);
            dvw.set_media_async (d.get_medias ());
            lw.view_container.add_view (dvw);
            addItem(rv, o, dvw, Icons.MUSIC.render (IconSize.MENU, null), _("Music"), null);

            return rv;
        }
        else if(o is NetworkDevice && parent == network_devices_iter) {
            NetworkDevice d = (NetworkDevice)o;
            TreeIter? rv;
            Gdk.Pixbuf device_icon = d.get_icon();
            
            if (device_icon == null) {
                device_icon = Icons.NETWORK_DEVICE.render (Gtk.IconSize.MENU, null);
            }

            rv = addItem(parent, o, w, device_icon, name, Icons.EJECT_SYMBOLIC.render(IconSize.MENU, null));

            //var ndvw = new NetworkDeviceViewWrapper(lw, new TreeViewSetup(ListColumn.ARTIST, SortType.ASCENDING, ViewWrapper.Hint.DEVICE_AUDIO), d);
            //ndvw.set_media_async (d.get_medias ());
            //addItem(rv, o, ndvw, Icons.MUSIC.render (IconSize.MENU, null), _("Music"), null);
            //lw.view_container.add_view (ndvw);
            
            return rv;
        }
        /*else if(name == "Music Store" && parent == network_iter) {
            network_store_iter = addItem(parent, o, w, music_icon, name, null);
            return network_store_iter;
        }*/
        else if(hint == ViewWrapper.Hint.SIMILAR && parent == playlists_iter) {
            var smart_playlist_icon = Icons.SMART_PLAYLIST.render (IconSize.MENU, null);
            playlists_similar_iter = addItem(parent, o, w, smart_playlist_icon, name, null);
            return playlists_similar_iter;
        }
        else if(hint == ViewWrapper.Hint.QUEUE && parent == playlists_iter) {
            var music_icon = Icons.MUSIC.render (IconSize.MENU, null);
            playlists_queue_iter = addItem(parent, o, w, music_icon, name, null);
            return playlists_queue_iter;
        }
        else if(hint == ViewWrapper.Hint.HISTORY && parent == playlists_iter) {
            var history_icon = Icons.HISTORY.render (IconSize.MENU, null);
            playlists_history_iter = addItem(parent, o, w, history_icon, name, null);
            return playlists_history_iter;
        }
        else if(hint == ViewWrapper.Hint.SMART_PLAYLIST && parent == playlists_iter) {
            var smart_playlist_icon = Icons.SMART_PLAYLIST.render (IconSize.MENU, null);
            TreeIter smart_playlist_iter = addItem (parent, o, w, smart_playlist_icon, name, null);
            return smart_playlist_iter;
        }
        else if(hint == ViewWrapper.Hint.PLAYLIST && parent == playlists_iter) {
            var playlist_icon = Icons.PLAYLIST.render (IconSize.MENU, null);
            TreeIter playlist_iter = addItem (parent, o, w, playlist_icon, name, null);
            return playlist_iter;
        }
        else {
            sideListSelectionChange();
            return addItem(parent, o, w, null, name, null);
        }
    }
    
    public virtual bool sideListClick(Gdk.EventButton event) {
        if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) { //secondary click
            // select one based on mouse position
            TreeIter iter;
            TreePath path;
            TreeViewColumn column;
            int cell_x;
            int cell_y;
            
            this.get_path_at_pos((int)event.x, (int)event.y, out path, out column, out cell_x, out cell_y);
            
            if(!filter.get_iter(out iter, path))
                return false;
            
            GLib.Object o;
            filter.get(iter, 0, out o);
            
            TreeIter parent;
            if(filter.iter_parent(out parent, iter)) {
                
                string parent_name;
                filter.get(parent, 4, out parent_name);

                if(parent == convertToFilter(playlists_iter)) {

                    playlistNew.visible = smartPlaylistNew.visible = false;
                    playlistExport.visible = true;
                    playlistExport.set_sensitive(!lm.doing_file_operations());
                    playlistRemove.sensitive = true;
                    playlistRemove.visible = true;                    

                    playlistEdit.visible = true;
                    playlistImport.visible = false;
                    
                    if(iter == convertToFilter(playlists_similar_iter)) {
                        playlistSave.visible = true;
                        playlistMenu.popup (null, null, null, 3, get_current_event_time());
                    }
                    else {
                        playlistSave.visible = false;
                        
                    }

                    // Don't show "edit" for hardcoded playlists
                    if (iter == convertToFilter(playlists_similar_iter) || iter == convertToFilter(playlists_queue_iter) || iter == convertToFilter(playlists_history_iter)) {
                        playlistEdit.visible = false;
                        playlistRemove.visible = false;
                    }
                    else {
                        playlistEdit.visible = true;
                        playlistRemove.visible = true;
                    }

                    playlistMenu.popup (null, null, null, 3, get_current_event_time());
                }
                else if(o is Device) {
                    var iter_f = convertToChild(iter);
                    Widget w = getWidget(iter_f);
                    if(w is Noise.DeviceView) {
                        deviceSync.visible = (o as Device).getContentType() == "cdrom";
                        deviceMenu.popup (null, null, null, Gdk.BUTTON_SECONDARY, Gtk.get_current_event_time ());
                    }
                }
            }
            else {
                if(iter == convertToFilter(playlists_iter)) {
                    playlistRemove.visible = false;
                    playlistExport.visible = false;
                    playlistSave.visible = false;
                    playlistEdit.visible = false;

                    playlistNew.visible = smartPlaylistNew.visible = true;
                    playlistImport.visible = true;
                    playlistImport.set_sensitive(!lm.doing_file_operations());

                    playlistMenu.popup (null, null, null, 3, get_current_event_time());
                    return true;
                }
            }
            
            return false;
        }
        else if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 2) {
            TreeIter iter;
            TreeIter iter_f;
            TreePath path;
            TreeViewColumn column;
            int cell_x;
            int cell_y;
            
            this.get_path_at_pos((int)event.x, (int)event.y, out path, out column, out cell_x, out cell_y);
        
            if(!filter.get_iter(out iter_f, path))
                return false;
                
            iter = convertToChild(iter_f);
            
            Widget w = getWidget(iter);
            if(w is ViewWrapper) {
                (w as ViewWrapper).play_first_media ();
            }
        }
        
        return false;
    }
    
    public virtual void sideListDoubleClick(TreePath path, TreeViewColumn column) {
        TreeIter iter_f;
        TreeIter iter;
        
        if(!filter.get_iter(out iter_f, path))
            return;
            
        iter = convertToChild(iter_f);
            
        Widget w = getWidget(iter);
        if(w is ViewWrapper) {
            (w as ViewWrapper).play_first_media ();
        }
    }

    public void resetView() {
        /* We can't just put setSelectedIter directly, we have to check that this iter is not null */
        TreeIter? selected_iter = null;

        if(App.player.media_info.media == null || App.player.media_info.media.mediatype == MediaType.SONG)
            selected_iter = convertToFilter(library_music_iter);

        if (selected_iter != null)
            setSelectedIter (selected_iter);
        else
            critical ("Couldn't select the good iter for the sidebar. Is it still under construction?");

#if 0
        // Restore state from last session
        expandItem (library_iter, lw.settings.get_sidebar_library_item_expanded ());
        expandItem (playlists_iter, lw.settings.get_sidebar_playlists_item_expanded ());
#endif

        // Emit change signal
        sideListSelectionChange ();
    }

    // Sets the current sidebar item as the active view
    public async void sideListSelectionChange () {
        var w = getSelectedWidget ();
        
        // Switch to that view in the library window
        lw.set_active_view (w);
    }

    //smart playlist context menu
    public void smartPlaylistMenuNewClicked() {
        SmartPlaylistEditor spe = new SmartPlaylistEditor(lw, new SmartPlaylist());
        spe.playlist_saved.connect(smartPlaylistEditorSaved);
    }
    
    void smartPlaylistEditorSaved(SmartPlaylist sp) {
        if(sp.rowid > 0) {
            TreeIter pivot = playlists_history_iter;
                
            do {
                Widget w;
                Object o;
                tree.get(pivot, 1, out w, 0, out o);
                if(o is SmartPlaylist && ((SmartPlaylist)o).rowid == sp.rowid) {
                    removeItem(pivot);
                    TreeIter iter = lw.addSideListItem(sp);
                    
                    lm.save_smart_playlists();
                    
                    // Select it now
                    get_selection().select_iter(convertToFilter(iter));
                    
                    break;
                }
            } while(tree.iter_next(ref pivot));
        }
        else {
            lm.add_smart_playlist(sp); // this queues save_smart_playlists()
            lw.addSideListItem(sp);
            sideListSelectionChange();
        }
    }
    
    //playlist context menu
    public void playlistMenuNewClicked() {
        PlaylistNameWindow pnw = new PlaylistNameWindow(lw, new Playlist());
        pnw.playlist_saved.connect(playlistNameWindowSaved);
    }
    
    void playlistNameWindowSaved(Playlist p) {
        
        if(p.rowid > 0) {
            TreeIter pivot = playlists_history_iter;
            
            do {
                Widget w;
                Object o;
                tree.get(pivot, 1, out w, 0, out o);
                if(o is Playlist && ((Playlist)o).rowid == p.rowid) {
                    removeItem(pivot);
                    TreeIter iter = lw.addSideListItem(p);
                    
                    // Select it now
                    get_selection().select_iter(convertToFilter(iter));
                    
                    break;
                }
            } while(tree.iter_next(ref pivot));
        }
        else {
            lm.add_playlist(p);
            lw.addSideListItem(p);
            sideListSelectionChange();
        }
    }
    
    public void playlistMenuEditClicked() {
        TreeSelection selected = this.get_selection();
        selected.set_mode(SelectionMode.SINGLE);
        TreeModel model;
        TreeIter iter;
        selected.get_selected (out model, out iter);
        
        Widget o;
        filter.get(iter, 1, out o);
        
        if (o is ViewWrapper) {
            var vw = o as ViewWrapper;
        
            if(vw.hint == ViewWrapper.Hint.PLAYLIST) {
                PlaylistNameWindow pnw = new PlaylistNameWindow(lw, lm.playlist_from_id (vw.relative_id));
                pnw.playlist_saved.connect(playlistNameWindowSaved);
            }
            else if(vw.hint == ViewWrapper.Hint.SMART_PLAYLIST) {
                SmartPlaylistEditor spe = new SmartPlaylistEditor(lw, lm.smart_playlist_from_id (vw.relative_id));
                spe.playlist_saved.connect(smartPlaylistEditorSaved);
            }
        }
    }
    
    void playlistMenuRemoveClicked() {
        TreeIter iter, iter_f;
        TreeSelection selected = this.get_selection();
        selected.set_mode(SelectionMode.SINGLE);
        TreeModel model;
        selected.get_selected (out model, out iter_f);
        
        //GLib.Object o;
        Widget w;
        //filter.get(iter_f, 0, out o, 1, out w);
        filter.get(iter_f, 1, out w);

        if (w is ViewWrapper) {
            var vw = w as ViewWrapper;
        
            if(vw.hint == ViewWrapper.Hint.PLAYLIST)
                lm.remove_playlist (vw.relative_id);
            else if(vw.hint == ViewWrapper.Hint.SMART_PLAYLIST)
                lm.remove_smart_playlist (vw.relative_id);
        }
        
        iter = convertToChild(iter_f);
        
        removeItem(iter);
        resetView();
    }
    
    // removes all normal playlists from the side list, as well as LM
    public void removeAllStaticPlaylists() {
        TreeIter? pivot = playlists_history_iter;
        var toRemove = new Gee.LinkedList<int>();
        
        // keep taking from bottom until all playlists are gone
        var n = tree.iter_n_children (playlists_iter) - 1;
        if (n < 1)
            return;

        tree.iter_nth_child(out pivot, playlists_iter, n);
        
        if (pivot == null)
            return;
        
        do {
            Widget o;
            
            tree.get(pivot, 1, out o);
            if(o is ViewWrapper && (o as ViewWrapper).hint == ViewWrapper.Hint.PLAYLIST) {
                toRemove.add((o as ViewWrapper).relative_id);
                removeItem(pivot);
            }
            else {
                break;
            }
            
        } while(tree.iter_nth_child(out pivot, playlists_iter, tree.iter_n_children(playlists_iter) - 1));
        
        foreach(int i in toRemove) {
            lm.remove_playlist(i);
        }
    }
    
    /* Devices */
    
    void clickableClicked(TreeIter iter) {
        GLib.Object o;
        filter.get(iter, 0, out o);
        
        if(o is Device) {
            if (((Device)o).is_syncing ()) {
                lw.doAlert(_("This device is syncing"), _("Please wait until the current sync is finished to do this action."));
            } else if (((Device)o).is_transferring()) {
                lw.doAlert(_("This device is in transfer"), _("Please wait until the current transfer is finished to do this action."));
            } else {
                (o as Device).eject ();
            }
        }
    }
    
    /* device stuff */
    public void deviceAdded(GLib.Object d) {
        lw.addSideListItem(d);
        sideListSelectionChange ();
    }
    
    public void deviceRemoved(Device d) {
        TreeIter pivot;
        if(!tree.iter_children(out pivot, devices_iter))
            return;
            
        bool was_selected = false;
        
        do {
            GLib.Object o;
            tree.get(pivot, 0, out o);
            if(o is Device && ((Device)o).get_path() == d.get_path()) {
                if(get_selection().iter_is_selected(convertToFilter(pivot)))
                    was_selected = true;
                
                removeItem(pivot);
                
                break;
            }
        } while(tree.iter_next(ref pivot));
        
        if(was_selected)
            resetView();
    }
    
    // device menu
    void deviceImportToLibraryClicked() {
        TreeIter iter = getSelectedIter();
        Widget w = getSelectedWidget();
        
        GLib.Object o;
        filter.get(iter, 0, out o);
        
        if(o is Device) {
            ((DeviceView)w).showImportDialog();
        }
    }
    
    void deviceSyncClicked() {
        TreeIter iter = getSelectedIter();
        Widget w = getSelectedWidget();
        
        GLib.Object o;
        filter.get(iter, 0, out o);
        
        if(o is Device) {
            ((DeviceView)w).syncClicked();
        }
    }
    
    void deviceEjectClicked() {
        TreeIter iter = getSelectedIter();
        
        clickableClicked (iter);
    }
    
    // can only be done on similar medias
    public void playlistSaveClicked() {
        TreeSelection selected = this.get_selection();
        selected.set_mode(SelectionMode.SINGLE);
        TreeModel model;
        TreeIter iter;
        selected.get_selected (out model, out iter);
        
        Widget w;
        filter.get(iter, 1, out w);
        
/*        if(w is SimilarViewWrapper) {
            ((SimilarViewWrapper)w).save_playlist();
        }*/
    }
    
    void playlistExportClicked() {
        TreeIter iter, iter_f;
        TreeSelection selected = this.get_selection();
        selected.set_mode(SelectionMode.SINGLE);
        TreeModel model;
        selected.get_selected (out model, out iter_f);
        
        Widget o;
        filter.get(iter_f, 1, out o);
        
        iter = convertToChild(iter_f);
        
        Playlist p;
        if(o is ViewWrapper && (o as ViewWrapper).hint == ViewWrapper.Hint.PLAYLIST) {
            p = lm.playlist_from_id ((o as ViewWrapper).relative_id);
        }
        else {
            p = new Playlist();
            
            if(o is ViewWrapper && (o as ViewWrapper).hint == ViewWrapper.Hint.SMART_PLAYLIST) {
                var smart_playlist = lm.smart_playlist_from_id ((o as ViewWrapper).relative_id);
                p.add_media (smart_playlist.analyze(lm, lm.media ()));
                    
                p.name = smart_playlist.name;
            }
            else {
                var to_add = new LinkedList<Media>();
                foreach(Media m in ((ViewWrapper)o).list_view.get_media ()) {
                    to_add.add (m);
                }
                p.add_media (to_add);
                
                /*if(iter == playlists_similar_iter)
                    p.name = (App.player.media_info.media != null) ? ("Similar to " + App.player.media_info.media.title) : "Similar list";
                else */if(iter == playlists_queue_iter)
                    p.name = Time.local(time_t()).format(_("Play Queue (%Y-%b-%e %l:%M %p)"));
                else if(iter == playlists_history_iter)
                    p.name = Time.local(time_t()).format(_("Play History (%Y-%b-%e %l:%M %p)"));
                else
                    p.name = _("Unknown playlist");
            }
        }
        
        if(p == null)
            return;
        
        string file = "";
        string name = "";
        string extension = "";
        var file_chooser = new FileChooserDialog (_("Export Playlist"), lw,
                                  FileChooserAction.SAVE,
                                  Gtk.Stock.CANCEL, ResponseType.CANCEL,
                                  Gtk.Stock.SAVE, ResponseType.ACCEPT);
        
        // filters for .m3u and .pls
        var m3u_filter = new FileFilter();
        m3u_filter.add_pattern("*.m3u");
        m3u_filter.set_filter_name("MPEG Version 3.0 Extended (*.m3u)");
        file_chooser.add_filter(m3u_filter);
        
        var pls_filter = new FileFilter();
        pls_filter.add_pattern("*.pls");
        pls_filter.set_filter_name("Shoutcast Playlist Version 2.0 (*.pls)");
        file_chooser.add_filter(pls_filter);
        
        file_chooser.do_overwrite_confirmation = true;
        file_chooser.set_current_name(p.name + ".m3u");
        
        // set original folder. if we don't, then file_chooser.get_filename() starts as null, which is bad for signal below.
        if(File.new_for_path(Settings.Main.instance.music_folder).query_exists())
            file_chooser.set_current_folder(Settings.Main.instance.music_folder);
        else
            file_chooser.set_current_folder(Environment.get_home_dir());
            
        
        // listen for filter change
        file_chooser.notify["filter"].connect( () => {
            if(file_chooser.get_filename() == null) // happens when no folder is chosen. need way to get textbox text, rather than filename
                return;
            
            if(file_chooser.filter == m3u_filter) {
                message ("changed to m3u\n");
                var new_file = file_chooser.get_filename().replace(".pls", ".m3u");
                
                if(new_file.slice(new_file.last_index_of(".", 0), new_file.length).length == 0) {
                    new_file += ".m3u";
                }
                
                file_chooser.set_current_name(new_file.slice(new_file.last_index_of("/", 0) + 1, new_file.length));
            }
            else {
                message ("changed to pls\n");
                var new_file = file_chooser.get_filename().replace(".m3u", ".pls");
                
                if(new_file.slice(new_file.last_index_of(".", 0), new_file.length).length == 0) {
                    new_file += ".pls";
                }
                
                file_chooser.set_current_name(new_file.slice(new_file.last_index_of("/", 0) + 1, new_file.length));
            }
        });
        
        if (file_chooser.run () == ResponseType.ACCEPT) {
            file = file_chooser.get_filename();
            extension = file.slice(file.last_index_of(".", 0), file.length);
            
            if(extension.length == 0 || extension[0] != '.') {
                extension = (file_chooser.filter == m3u_filter) ? ".m3u" : ".pls";
                file += extension;
            }
            
            name = file.slice(file.last_index_of("/", 0) + 1, file.last_index_of(".", 0));
            message ("name is %s extension is %s\n", name, extension);
        }
        
        file_chooser.destroy ();
        
        string original_name = p.name;
        if(file != "") {
            var f = File.new_for_path(file);
            
            string folder = f.get_parent().get_path();
            p.name = name; // temporary to save
            
            if(file.has_suffix(".m3u"))
                p.save_playlist_m3u(lm, folder);
            else
                p.save_playlist_pls(lm, folder);
        }
        
        p.name = original_name;
    }
    
    void playlistImportClicked(string title = _("Playlist")) {
        var files = new SList<string> ();
        string[] names = {};    
        var path = new LinkedList<string> ();
        var stations = new LinkedList<Media> ();
        LinkedList<string>[] paths = {};
        LinkedList<string>[] filtered_paths = {};
        bool success = false;
        int i = 0;
        
        if(lm.doing_file_operations())
            return;

        var file_chooser = new FileChooserDialog (_("Import %s").printf (title), lw,
                                  FileChooserAction.OPEN,
                                  Gtk.Stock.CANCEL, ResponseType.CANCEL,
                                  Gtk.Stock.OPEN, ResponseType.ACCEPT);
        file_chooser.set_select_multiple (true);
        
        // filters for .m3u and .pls
        var m3u_filter = new FileFilter();
        m3u_filter.add_pattern("*.m3u");
        m3u_filter.set_filter_name("MPEG Version 3.0 Extended (*.m3u)");
        file_chooser.add_filter(m3u_filter);
        
        var pls_filter = new FileFilter();
        pls_filter.add_pattern("*.pls");
        pls_filter.set_filter_name("Shoutcast Playlist Version 2.0 (*.pls)");
        file_chooser.add_filter(pls_filter);
        
        if (file_chooser.run () == ResponseType.ACCEPT) {
            files = file_chooser.get_filenames();
            files.foreach ( (file)=> {
                names += file.slice(file.last_index_of("/", 0) + 1, file.last_index_of(".", 0));
            });
        }
        
        file_chooser.destroy ();
        
        files.foreach ( (file)=> {
            if(file != "") {
                path = new LinkedList<string> ();
                if(file.has_suffix(".m3u")) {
                    success = Playlist.parse_paths_from_m3u(lm, file, ref path, ref stations);
                    paths += path;
                }
                else if(file.has_suffix(".pls")) {
                    success = Playlist.parse_paths_from_pls(lm, file, ref path, ref stations);
                    paths += path;
                }
                else {
                    success = false;
                    lw.doAlert("Invalid Playlist", "Unrecognized playlist file. Import failed.");
                    return;
                }
            }
            i++;
        });
        
        foreach (LinkedList l in paths)
            if (l.size > 0)
                filtered_paths += l;
        
        if(success) {
            if(filtered_paths.length > 0) {
                debug ("I was called");
                lm.fo.import_from_playlist_file_info(names, filtered_paths);
                    lw.update_sensitivities();
                }
        }
    }



}
