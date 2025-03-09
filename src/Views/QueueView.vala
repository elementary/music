public class Music.QueueView : Granite.Bin {
    construct {
        var playback_manager = PlaybackManager.get_default ();

        var start_window_controls = new Gtk.WindowControls (Gtk.PackType.START);

        var queue_placeholder = new Granite.Placeholder (_("Queue is Empty")) {
            description = _("Audio files opened from Files will appear here"),
            icon = new ThemedIcon ("playlist-queue")
        };

        var queue_listbox = new Gtk.ListBox () {
            hexpand = true,
            vexpand = true
        };
        queue_listbox.bind_model (playback_manager.queue_liststore, create_queue_row);
        queue_listbox.set_placeholder (queue_placeholder);

        var scrolled = new Gtk.ScrolledWindow () {
            child = queue_listbox
        };

        var add_button_label = new Gtk.Label (_("Open Files…"));

        var add_button_box = new Gtk.Box (HORIZONTAL, 0);
        add_button_box.append (new Gtk.Image.from_icon_name ("document-open-symbolic"));
        add_button_box.append (add_button_label);

        var add_button = new Gtk.Button () {
            child = add_button_box,
        };
        add_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        add_button_label.mnemonic_widget = add_button;

        var action_bar = new Gtk.ActionBar ();
        action_bar.pack_start (add_button);

        var toolbar_view = new Adw.ToolbarView () {
            bottom_bar_style = RAISED,
            content = scrolled
        };
        toolbar_view.add_bottom_bar (action_bar);

        var drop_target = new Gtk.DropTarget (typeof (Gdk.FileList), Gdk.DragAction.COPY);
        scrolled.add_controller (drop_target);

        var error_toast = new Granite.Toast ("");

        var queue_overlay = new Gtk.Overlay () {
            child = toolbar_view
        };
        queue_overlay.add_overlay (error_toast);

        var queue_handle = new Gtk.WindowHandle () {
            child = queue_overlay,
            hexpand = true
        };

        hexpand = true;
        vexpand = true;
        child = queue_handle;

        drop_target.drop.connect ((target, value, x, y) => {
            if (value.type () == typeof (Gdk.FileList)) {
                File[] files;
                SList<File> file_list = null;
                foreach (unowned var file in (SList<File>) value.get_boxed ()) {
                    var file_type = file.query_file_type (FileQueryInfoFlags.NONE);
                    if (file_type == FileType.DIRECTORY) {
                        prepend_directory_files (file, ref file_list);
                    } else {
                        file_list.prepend (file);
                    }
                }

                file_list.reverse ();
                foreach (unowned var file in file_list) {
                    files += file;
                }

                playback_manager.queue_files (files);

                return true;
            }

            return false;
        });

        playback_manager.invalids_found.connect ((count) => {
            error_toast.title = ngettext (
                "%d invalid file was not added to the queue",
                "%d invalid files were not added to the queue",
                count).printf (count);
            error_toast.send_notification ();
        });

        queue_listbox.row_activated.connect ((row) => {
            playback_manager.current_audio = ((TrackRow) row.child).audio_object;
        });
    }

    //Array concatenation not permitted for parameters so use a list instead
    private void prepend_directory_files (GLib.File dir, ref SList<File> file_list) {
        try {
            var enumerator = dir.enumerate_children (
                "standard::*",
                FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                null
            );

            FileInfo info = null;
            while ((info = enumerator.next_file (null)) != null) {
                var child = dir.resolve_relative_path (info.get_name ());
                if (info.get_file_type () == FileType.DIRECTORY) {
                    prepend_directory_files (child, ref file_list);
                } else {
                    file_list.prepend (child);
                }
            }
        } catch (Error e) {
            warning ("Error while enumerating children of %s: %s", dir.get_uri (), e.message);
        }
    }

    private Gtk.Widget create_queue_row (GLib.Object object) {
        unowned var audio_object = (AudioObject) object;
        var track_row = new TrackRow ();
        track_row.bind_audio_object (audio_object);
        return track_row;
    }

}
