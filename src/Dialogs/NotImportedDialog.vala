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
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 */

/* Merely a place holder for multiple pieces of information regarding
 * the current media playing. Mostly here because of dependence. */

public class Noise.NotImportedDialog : Gtk.Dialog {
    Gee.LinkedList<string> _files;
    string music_folder;

    Gtk.ListStore filesModel;
    Gtk.Button moveToTrash;

    public NotImportedDialog (Gee.Collection<string> files, string music) {
        _files = new Gee.LinkedList<string> ();
        _files.add_all (files);
        this.music_folder = music;

        this.set_modal (true);
        this.set_transient_for (App.main_window);
        this.destroy_with_parent = true;
        this.deletable = false;

        var warning = new Gtk.Image.from_icon_name ("dialog-error", Gtk.IconSize.DIALOG);

        var title = new Gtk.Label (_("Issues while importing from %s").printf (music_folder));
        title.halign = Gtk.Align.START;
        title.hexpand = true;
        title.get_style_context ().add_class (Granite.STYLE_CLASS_PRIMARY_LABEL);

        string secondary_text = ngettext (
            "Unable to import %d item. The file may be damaged.",
            "Unable to import %d items. The files may be damaged.",
            files.size
        ).printf (files.size);

        var info = new Gtk.Label (secondary_text);
        info.halign = Gtk.Align.START;

        var trashAll = new Gtk.CheckButton.with_label (_("Move all corrupted files to trash"));
        trashAll.valign = Gtk.Align.CENTER;

        /* add cellrenderers to columns and columns to treeview */
        var toggle = new Gtk.CellRendererToggle ();

        var column = new Gtk.TreeViewColumn ();
        column.title = _("del");
        column.pack_start (toggle, false);
        column.add_attribute (toggle, "active", 0);

        filesModel = new Gtk.ListStore (2, typeof (bool), typeof (string));

        var filesView = new Gtk.TreeView ();
        filesView.set_model (filesModel);
        filesView.append_column (column);
        filesView.insert_column_with_attributes (-1, _("File Location"), new Gtk.CellRendererText (), "text", 1, null);
        filesView.headers_visible = false;

        /* fill the treeview */
        foreach (string file in files) {
            Gtk.TreeIter item;
            filesModel.append (out item);
            filesModel.set (item, 0, false, 1, Uri.unescape_string (file.replace ("file://" + music_folder, "")));
        }

        var files_scrolled = new Gtk.ScrolledWindow (null, null);
        files_scrolled.add (filesView);
        files_scrolled.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        files_scrolled.expand = true;
        files_scrolled.margin = 6;

        var expander = new Gtk.Expander (_("Select individual files to move to trash:"));
        expander.add (files_scrolled);
        expander.expanded = false;

        moveToTrash = new Gtk.Button.with_label (_("Move to Trash"));
        moveToTrash.sensitive = false;

        var okButton = new Gtk.Button.with_label (_("Ignore"));

        var bottomButtons = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        bottomButtons.set_layout (Gtk.ButtonBoxStyle.END);
        bottomButtons.pack_end (moveToTrash, false, false, 0);
        bottomButtons.pack_end (okButton, false, false, 0);
        bottomButtons.spacing = 12;

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.row_spacing = 6;
        grid.margin = 12;
        grid.margin_bottom = 0;
        grid.expand = true;
        grid.attach (warning, 0, 0, 1, 2);
        grid.attach (title, 1, 0, 1, 1);
        grid.attach (info, 1, 1, 1, 1);
        grid.attach (trashAll, 0, 2, 2, 1);
        grid.attach (expander, 0, 3, 2, 1);
        grid.attach (bottomButtons, 0, 4, 2, 1);
        get_content_area ().add (grid);

        moveToTrash.clicked.connect (moveToTrashClick);

        toggle.toggled.connect ((toggle, path) => {
            var tree_path = new Gtk.TreePath.from_string (path);
            Gtk.TreeIter iter;
            filesModel.get_iter (out iter, tree_path);
            filesModel.set (iter, 0, !toggle.active);

            moveToTrash.set_sensitive (false);
            filesModel.foreach (updateMoveToTrashSensetivity);
        });

        trashAll.toggled.connect (() => {
            if (trashAll.active) {
                filesModel.foreach (selectAll);
                filesView.set_sensitive (false);
                moveToTrash.set_sensitive (true);
            } else {
                filesModel.foreach (unselectAll);
                filesView.set_sensitive (true);
                moveToTrash.set_sensitive (false);
            }
        });

        okButton.clicked.connect (() => {
            this.destroy ();
        });

        expander.activate.connect (() => {
            if (expander.get_expanded ()) {
                expander.set_size_request (-1, -1);
            } else {
                expander.set_size_request (-1, 120);
            }
        });

        show_all ();
    }

    public bool updateMoveToTrashSensetivity (Gtk.TreeModel model, Gtk.TreePath path, Gtk.TreeIter iter) {
        bool sel = false;
        model.get (iter, 0, out sel);

        if (sel) {
            moveToTrash.set_sensitive (true);
            return true;
        }

        return false;
    }

    public bool selectAll (Gtk.TreeModel model, Gtk.TreePath path, Gtk.TreeIter iter) {
        filesModel.set (iter, 0, true);
        return false;
    }

    public bool unselectAll (Gtk.TreeModel model, Gtk.TreePath path, Gtk.TreeIter iter) {
        filesModel.set (iter, 0, false);
        return false;
    }

    public bool deleteSelectedItems (Gtk.TreeModel model, Gtk.TreePath path, Gtk.TreeIter iter) {
        bool selected;
        string location;
        filesModel.get (iter, 0, out selected);
        filesModel.get (iter, 1, out location);

        if (selected) {
            try {
                var file = File.new_for_path (music_folder + location);
                file.trash ();
            } catch (GLib.Error err) {
                warning ("Could not move file %s to recycle: %s\n", location, err.message);
            }
        }

        return false;
    }

    public virtual void moveToTrashClick () {
        filesModel.foreach (deleteSelectedItems);
        this.destroy ();
    }

    public virtual void ignoreClick () {
        this.destroy ();
    }
}
