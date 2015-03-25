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

public class Noise.SyncWarningDialog : Gtk.Window {
    Device d;
    Gee.TreeSet<Media> to_sync = new Gee.TreeSet<Media> ();
    Gee.TreeSet<Media> to_remove = new Gee.TreeSet<Media> ();
    
    private Gtk.Box content;
    private Gtk.Box padding;
    
    Gtk.Button importMedias;
    Gtk.Button sync;
    Gtk.Button cancel;
    
    public SyncWarningDialog(Device d, Gee.Collection<Media> to_sync, Gee.Collection<Media> removed) {
        this.d = d;
        this.to_sync.add_all (to_sync);
        this.to_remove.add_all (removed);

        // set the size based on saved gconf settings
        //this.window_position = WindowPosition.CENTER;
        this.type_hint = Gdk.WindowTypeHint.DIALOG;
        this.set_modal(true);
        this.set_transient_for(App.main_window);
        this.destroy_with_parent = true;
        
        set_default_size(475, -1);
        resizable = false;
        
        content = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
        padding = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 20);
        
        // initialize controls
        Gtk.Image warning = new Gtk.Image.from_icon_name ("dialog-error", Gtk.IconSize.DIALOG);
        Gtk.Label title = new Gtk.Label("");
        Gtk.Label info = new Gtk.Label("");
        importMedias = new Gtk.Button.with_label(_("Import media to Library"));
        sync = new Gtk.Button.with_label(_("Continue Syncing"));
        cancel = new Gtk.Button.with_label(_("Stop Syncing"));
        
        // pretty up labels
        title.halign = Gtk.Align.START;
        info.halign = Gtk.Align.START;

        info.set_line_wrap (true);
        var info_text = _("If you continue to sync, media will be removed from %s since they are not on the sync list. Would you like to import them to your library first?").printf ("<b>" + String.escape (d.getDisplayName ()) + "</b>");
        info.set_markup (info_text);

        // be a bit explicit to make translations better
        string title_text = "";
        if (to_remove.size > 1) {
            title_text = _("Sync will remove %i items from %s").printf (to_remove.size, d.getDisplayName ());
        }
        else {
            title_text = _("Sync will remove 1 item from %s").printf (d.getDisplayName ());
        }

        string MARKUP_TEMPLATE = "<span weight=\"bold\" size=\"larger\">%s</span>";        
        var title_string = MARKUP_TEMPLATE.printf (Markup.escape_text (title_text, -1));        
        title.set_markup (title_string);

        importMedias.set_sensitive(!libraries_manager.local_library.doing_file_operations());
        sync.set_sensitive(!libraries_manager.local_library.doing_file_operations());
        
        /* set up controls layout */
        var information = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var information_text = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        information.pack_start(warning, false, false, 10);
        information_text.pack_start(title, false, true, 10);
        information_text.pack_start(info, false, true, 0);
        information.pack_start(information_text, true, true, 10);
        
        var bottomButtons = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
        bottomButtons.set_layout(Gtk.ButtonBoxStyle.END);
        bottomButtons.pack_end(importMedias, false, false, 0);
        bottomButtons.pack_end(sync, false, false, 0);
        bottomButtons.pack_end(cancel, false, false, 10);
        bottomButtons.set_spacing(10);
        
        content.pack_start(information, false, true, 0);
        content.pack_start(bottomButtons, false, true, 10);
        
        padding.pack_start(content, true, true, 10);
        
        importMedias.clicked.connect(importMediasClicked);
        sync.clicked.connect(syncClicked);
        cancel.clicked.connect( () => { 
            this.destroy(); 
        });
        
        libraries_manager.local_library.file_operations_started.connect(file_operations_started);
        libraries_manager.local_library.file_operations_done.connect(file_operations_done);
        
        add(padding);
        show_all();
    }

    public void importMediasClicked() {
        libraries_manager.transfer_to_local_library (to_remove);
        // TODO: After transfer, do sync
        
        this.destroy();
    }
    
    public void syncClicked() {
        d.synchronize ();
        
        this.destroy();
    }
    
    public void file_operations_done() {
        importMedias.set_sensitive(true);
        sync.set_sensitive(true);
    }
    
    public void file_operations_started() {
        importMedias.set_sensitive(false);
        sync.set_sensitive(false);
    }
    
}
