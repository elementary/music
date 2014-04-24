/*-
 * Copyright (c) 2011-2012	   Scott Ringwelski <sgringwe@mtu.edu>
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

public class Noise.NotImportedWindow : Gtk.Window {
    Gee.LinkedList<string> _files;
    string music_folder;

    //for padding around notebook mostly
    private Gtk.Box content;
    private Gtk.Box padding;

    Gtk.CheckButton trashAll;
    Gtk.ScrolledWindow filesScroll;
    Gtk.TreeView filesView;
    Gtk.ListStore filesModel;
    Gtk.Button moveToTrash;

    public NotImportedWindow (Gee.Collection<string> files, string music) {
        _files = new Gee.LinkedList<string> ();
        _files.add_all (files);
        this.music_folder = music;

        this.type_hint = Gdk.WindowTypeHint.DIALOG;
        this.set_modal (true);
        this.set_transient_for (App.main_window);
        this.destroy_with_parent = true;

        set_default_size (475, -1);
        resizable = false;

        content = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        padding = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 20);

        // initialize controls
        var warning = new Gtk.Image.from_icon_name ("dialog-error", Gtk.IconSize.DIALOG);
        var title = new Gtk.Label (_("Unable to import %d items from %s").printf (files.size, music_folder));
        var info = new Gtk.Label (_("%s was unable to import %d items. The files may be damaged.").printf (((Noise.App) GLib.Application.get_default ()).get_name (), files.size));
        trashAll = new Gtk.CheckButton.with_label (_("Move all corrupted files to trash"));
        filesScroll = new Gtk.ScrolledWindow (null, null);
        filesView = new Gtk.TreeView ();
        filesModel = new Gtk.ListStore (2, typeof(bool), typeof(string));
        filesView.set_model (filesModel);
        moveToTrash = new Gtk.Button.with_label (_("Move to Trash"));
        Gtk.Button okButton = new Gtk.Button.with_label (_("Ignore"));

        // pretty up labels
        title.xalign = 0.0f;
        title.set_markup ("<span weight=\"bold\" size=\"larger\">" + Markup.escape_text (_("Unable to import %d items from %s").printf (files.size, music_folder), -1) + "</span>");
        info.xalign = 0.0f;
        info.set_line_wrap (false);

        /* add cellrenderers to columns and columns to treeview */
        var toggle = new Gtk.CellRendererToggle ();
        toggle.toggled.connect ((toggle, path) => {
            var tree_path = new Gtk.TreePath.from_string (path);
            Gtk.TreeIter iter;
            filesModel.get_iter (out iter, tree_path);
            filesModel.set (iter, 0, !toggle.active);

            moveToTrash.set_sensitive (false);
            filesModel.foreach (updateMoveToTrashSensetivity);
        });

        var column = new Gtk.TreeViewColumn ();
        column.title = _("del");
        column.pack_start (toggle, false);
        column.add_attribute (toggle, "active", 0);
        filesView.append_column (column);

        filesView.insert_column_with_attributes (-1, _("File Location"), new Gtk.CellRendererText(), "text", 1, null);
        filesView.headers_visible = false;

        /* fill the treeview */
        foreach (string file in files) {
            Gtk.TreeIter item;
            filesModel.append (out item);

            filesModel.set (item, 0, false, 1, file.replace (music_folder, ""));
        }

        filesScroll.add (filesView);
        filesScroll.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);

        moveToTrash.set_sensitive (false);

        /* set up controls layout */
        var information = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        var information_text = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        information.pack_start (warning, false, false, 10);
        information_text.pack_start (title, false, true, 10);
        information_text.pack_start (info, false, true, 0);
        information.pack_start (information_text, true, true, 10);

        var listBox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        listBox.pack_start (filesScroll, true, true, 5);

        Gtk.Expander exp = new Gtk.Expander (_("Select individual files to move to trash:"));
        exp.add (listBox);
        exp.expanded = false;

        var bottomButtons = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        bottomButtons.set_layout (Gtk.ButtonBoxStyle.END);
        bottomButtons.pack_end (moveToTrash, false, false, 0);
        bottomButtons.pack_end (okButton, false, false, 10);
        bottomButtons.set_spacing (10);

        content.pack_start(information, false, true, 0);
        content.pack_start(UI.wrap_alignment (trashAll, 5, 0, 0, 75), false, true, 0);
        content.pack_start(UI.wrap_alignment (exp, 0, 0, 0, 75), true, true, 0);
        content.pack_start(bottomButtons, false, true, 10);

        padding.pack_start (content, true, true, 10);

        moveToTrash.clicked.connect (moveToTrashClick);
        trashAll.toggled.connect (trashAllToggled);
        okButton.clicked.connect ( () => { this.destroy(); });
        exp.activate.connect ( () => {
            if (exp.get_expanded()) {
                resizable = true;
                set_size_request(475, 180);
                resize(475, 180);
                resizable = false;
            } else {
                set_size_request(475, 350);
            }
        });

        add (padding);
        show_all ();
    }

    public bool updateMoveToTrashSensetivity(Gtk.TreeModel model, Gtk.TreePath path, Gtk.TreeIter iter) {
        bool sel = false;
        model.get(iter, 0, out sel);

        if(sel) {
            moveToTrash.set_sensitive(true);
            return true;
        }

        return false;
    }

    public bool selectAll(Gtk.TreeModel model, Gtk.TreePath path, Gtk.TreeIter iter) {
        filesModel.set(iter, 0, true);

        return false;
    }

    public bool unselectAll(Gtk.TreeModel model, Gtk.TreePath path, Gtk.TreeIter iter) {
        filesModel.set(iter, 0, false);

        return false;
    }

    public virtual void trashAllToggled() {
        if(trashAll.active) {
            filesModel.foreach(selectAll);
            filesView.set_sensitive(false);
            moveToTrash.set_sensitive(true);
        } else {
            filesModel.foreach(unselectAll);
            filesView.set_sensitive(true);
            moveToTrash.set_sensitive(false);
        }
    }

    public bool deleteSelectedItems(Gtk.TreeModel model, Gtk.TreePath path, Gtk.TreeIter iter) {
        bool selected;
        string location;
        filesModel.get(iter, 0, out selected);
        filesModel.get(iter, 1, out location);

        if(selected) {
            try {
                var file = File.new_for_path(music_folder + location);
                file.trash();
            }
            catch(GLib.Error err) {
                warning ("Could not move file %s to recycle: %s\n", location, err.message);
            }
            /*else {
                try {
                    var file = File.new_for_path (location);
                    file.delete();
                }
                catch(GLib.Error err) {
                    warning ("Could not delete file %s: %s\n", location, err.message);
                }
            }*/
        }

        return false;
    }

    public virtual void moveToTrashClick() {
        filesModel.foreach(deleteSelectedItems);
        this.destroy();
    }

    public virtual void ignoreClick() {
        this.destroy();
    }
}