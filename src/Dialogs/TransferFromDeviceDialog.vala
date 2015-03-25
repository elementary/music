/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originaly Written by Scott Ringwelski for BeatBox Music Player
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

/* Merely a place holder for multiple pieces of information regarding
 * the current media playing. Mostly here because of dependence. */

using Gtk;

public class Noise.TransferFromDeviceDialog : Window {
    Gee.TreeSet<Media> medias = new Gee.TreeSet<Media> ();
    Device d;

    //for padding around notebook mostly
    private Gtk.Box content;
    private Gtk.Box padding;

    Gtk.CheckButton transferAll;
    Gtk.ScrolledWindow mediasScroll;
    Gtk.TreeView mediasView;
    Gtk.ListStore mediasModel;
    Gtk.Button transfer;

    Gtk.Menu viewMenu;
    Gtk.MenuItem selectItem;
    Gtk.MenuItem selectAlbum;
    Gtk.MenuItem selectArtist;

    Gee.TreeSet<Media> to_transfer = new Gee.TreeSet<Media> ();

    public TransferFromDeviceDialog(Device d, Gee.Collection<Media> _medias) {
        this.medias.add_all (_medias);
        this.d = d;

        this.set_title(_("Import from Device"));

        // set the size based on saved gconf settings
        //this.window_position = WindowPosition.CENTER;
        this.type_hint = Gdk.WindowTypeHint.DIALOG;
        this.set_modal(true);
        this.set_transient_for (App.main_window);
        this.destroy_with_parent = true;

        set_default_size (550, -1);
        resizable = false;

        content = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        padding = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 20);

        // initialize controls
        var warning = new Gtk.Image.from_stock ("dialog-question", Gtk.IconSize.DIALOG);
        var title = new Gtk.Label (_("Import media from %s").printf (d.getDisplayName ()));
        var info = new Gtk.Label (_("The following files were found on %s, but are not in your library. Check all the files you would like to import.").printf (d.getDisplayName ()));
        transferAll = new Gtk.CheckButton.with_label (_("Import all media"));
        mediasScroll = new Gtk.ScrolledWindow (null, null);
        mediasView = new Gtk.TreeView ();
        mediasModel = new Gtk.ListStore(5, typeof(bool), typeof(int), typeof(string), typeof(string), typeof(string));
        mediasView.set_model(mediasModel);
        transfer = new Button.with_label(_("Import"));
        Button cancel = new Button.with_label(_("Don't Import"));

        // pretty up labels
        title.halign = Gtk.Align.START;

        // be a bit explicit to make translations better
        string title_text = "";
        if (medias.size > 1) {
            title_text = _("Import %i items from %s").printf (medias.size, d.getDisplayName ());
        }
        else {
            var m = this.medias.first ();
            title_text = _("Import %s from %s").printf (m.title, d.getDisplayName ());
        }

        string MARKUP_TEMPLATE = "<span weight=\"bold\" size=\"larger\">%s</span>";		
        var title_string = MARKUP_TEMPLATE.printf (String.escape (title_text));
        title.set_markup (title_string);

        info.halign = Gtk.Align.START;
        info.set_line_wrap(true);

        /* add cellrenderers to columns and columns to treeview */
        var toggle = new CellRendererToggle ();
        toggle.toggled.connect ((toggle, path) => {
            var tree_path = new TreePath.from_string (path);
            TreeIter iter;
            mediasModel.get_iter (out iter, tree_path);
            mediasModel.set (iter, 0, !toggle.active);

            transfer.set_sensitive(false);
            mediasModel.foreach(updateTransferSensetivity);
        });

        var column = new TreeViewColumn ();
        column.title = "";
        column.pack_start (toggle, false);
        column.add_attribute (toggle, "active", 0);
        mediasView.append_column(column);

        mediasView.insert_column_with_attributes(-1, _("ID"), new CellRendererText(), "text", 1, null);
        mediasView.insert_column_with_attributes(-1, _("Title"), new CellRendererText(), "text", 2, null);
        mediasView.insert_column_with_attributes(-1, _("Artist"), new CellRendererText(), "text", 3, null);
        mediasView.insert_column_with_attributes(-1, _("Album"), new CellRendererText(), "text", 4, null);
        mediasView.headers_visible = true;

        for(int i = 0; i < 5; ++i) {
            mediasView.get_column(i).sizing = Gtk.TreeViewColumnSizing.FIXED;
            mediasView.get_column(i).resizable = true;
            mediasView.get_column(i).reorderable = false;
            mediasView.get_column(i).clickable = false;
        }

        mediasView.get_column(1).visible = false;

        mediasView.get_column(0).fixed_width = 25;
        mediasView.get_column(1).fixed_width = 10;
        mediasView.get_column(2).fixed_width = 300;
        mediasView.get_column(3).fixed_width = 125;
        mediasView.get_column(4).fixed_width = 125;

        //view.get_selection().set_mode(SelectionMode.MULTIPLE);

        /* fill the treeview */
        var medias_sorted = new Gee.LinkedList<Media>();
        foreach(var m in medias)
            medias_sorted.add(m);
        medias_sorted.sort(mediaCompareFunc);

        foreach(var s in medias_sorted) {
            TreeIter item;
            mediasModel.append(out item);

            mediasModel.set(item, 0, false, 1, s.rowid, 2, s.title, 3, s.artist, 4, s.album);
        }

        mediasScroll.add(mediasView);
        mediasScroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);

        transfer.set_sensitive(false);

        /* set up controls layout */
        var information = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        var information_text = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        information.pack_start(warning, false, false, 10);
        information_text.pack_start(title, false, true, 10);
        information_text.pack_start(info, false, true, 0);
        information.pack_start(information_text, true, true, 10);

        var listBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        listBox.pack_start(mediasScroll, true, true, 5);

        Expander exp = new Expander(_("Select individual media to import:"));
        exp.add(listBox);
        exp.expanded = false;

        var bottomButtons = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        bottomButtons.set_layout (Gtk.ButtonBoxStyle.END);
        bottomButtons.pack_end (cancel, false, false, 10);
        bottomButtons.pack_end (transfer, false, false, 0);
        bottomButtons.set_spacing (10);

        content.pack_start(information, false, true, 0);
        content.pack_start(UI.wrap_alignment (transferAll, 5, 0, 0, 75), false, true, 0);
        content.pack_start(UI.wrap_alignment (exp, 0, 0, 0, 75), true, true, 0);
        content.pack_start(bottomButtons, false, true, 10);

        padding.pack_start(content, true, true, 10);

        viewMenu = new Gtk.Menu();
        selectItem = new Gtk.MenuItem.with_label(_("Check Item"));
        selectAlbum = new Gtk.MenuItem.with_label(_("Check Album"));
        selectArtist = new Gtk.MenuItem.with_label(_("Check Artist"));

        transfer.clicked.connect(transferClick);
        transferAll.toggled.connect(transferAllToggled);
        //mediasView.button_press_event.connect(mediasViewClick);
        cancel.clicked.connect( () => { this.destroy(); });
        exp.activate.connect( () => {
            if(exp.get_expanded()) {
                resizable = true;
                set_size_request(550, 180);
                resize(475, 180);
                resizable = false;
            }
            else
                set_size_request(550, 500);
        });

        add(padding);
        show_all();
    }

    public static int mediaCompareFunc(Media a, Media b) {
        if(a.artist == b.artist) {
            if(a.album == b.album)
                return (int)a.track - (int)b.track;
            else
                return (a.album > b.album) ? 1 : -1;

        }
        else
            return (a.artist > b.artist) ? 1 : -1;
    }

    public static Gtk.Alignment wrap_alignment (Gtk.Widget widget, int top, int right, int bottom, int left) {
        var alignment = new Gtk.Alignment(0.0f, 0.0f, 1.0f, 1.0f);
        alignment.top_padding = top;
        alignment.right_padding = right;
        alignment.bottom_padding = bottom;
        alignment.left_padding = left;

        alignment.add(widget);
        return alignment;
    }

    public bool updateTransferSensetivity(TreeModel model, TreePath path, TreeIter iter) {
        bool sel = false;
        model.get(iter, 0, out sel);

        if(sel) {
            transfer.set_sensitive(true);
            return true;
        }

        return false;
    }

    public bool selectAll(TreeModel model, TreePath path, TreeIter iter) {
        mediasModel.set(iter, 0, true);

        return false;
    }

    public bool unselectAll(TreeModel model, TreePath path, TreeIter iter) {
        mediasModel.set(iter, 0, false);

        return false;
    }

    public virtual void transferAllToggled() {
        if(transferAll.active) {
            mediasModel.foreach(selectAll);
            mediasView.set_sensitive(false);
            transfer.set_sensitive(true);
        } else {
            mediasModel.foreach(unselectAll);
            mediasView.set_sensitive(true);
            transfer.set_sensitive(false);
        }
    }

    public bool createTransferList(TreeModel model, TreePath path, TreeIter iter) {
        Media? m = null;
        bool selected = false;
        mediasModel.get(iter, 0, out selected, 1, out m);

        if(m != null && selected) {
        to_transfer.add(m);
        }

        return false;
    }

    public virtual void transferClick() {
        to_transfer.clear();
        mediasModel.foreach(createTransferList);

        if(libraries_manager.local_library.doing_file_operations()) {
            NotificationManager.get_default ().show_alert (_("Cannot Import"), _("Noise is already doing file operations. Please wait until those finish to import from %d").printf( d.getDisplayName()));
        } else {
            libraries_manager.transfer_to_local_library (to_transfer);
            this.destroy();
        }
    }

    public virtual void cancelClick() {
        this.destroy();
    }
}
