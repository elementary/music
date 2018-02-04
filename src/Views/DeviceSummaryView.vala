/**
* Displays a summary of what contains a device
*/
public class Noise.DeviceSummaryView : View {
    public Device device { get; construct; }
    public DevicePreferences preferences { get; construct; }

    public DeviceSummaryView (Noise.Device device, DevicePreferences preferences) {
        Object (
            device: device,
            preferences: preferences
        );
    }

    construct {
        title = device.getDisplayName ();
        id = device.get_unique_identifier () + "/summary";
        category = device.get_unique_identifier ();
        icon = device.get_icon ();

        var grid = new Gtk.Grid ();

        var infobar_label = new Gtk.Label ("");

        var infobar = new Gtk.InfoBar ();
        infobar.hexpand = true;
        infobar.add_button (_("Close"), 0);
        infobar.get_content_area ().add (infobar_label);

        var summary = new DeviceSummaryWidget (device, preferences);

        grid.attach (infobar, 0, 0, 1, 1);

        var custom_view = device.get_custom_view ();
        if (custom_view != null) {
            grid.attach (custom_view, 0, 1, 1, 1);
        } else {
            grid.attach (summary, 0, 1, 1, 1);
        }

        add (grid);
        show_all ();

        infobar.hide ();

        ulong connector = NotificationManager.get_default ().progress_canceled.connect (() => {
            if (device.get_library ().doing_file_operations ()) {
                NotificationManager.get_default ().show_alert (_("Cancelling…"), _("Device operation has been cancelled and will stop after this media."));
            }
        });

        device.device_unmounted.connect (() => {
            message ("device unmounted\n");
            device.disconnect (connector);
        });

        device.infobar_message.connect ((label, message_type) => {
            infobar_label.label = label;
            infobar.message_type = message_type;
            infobar.show_all ();
        });

        infobar.response.connect ((self, response) => {
            infobar.hide ();
        });

        if (preferences.sync_when_mounted) {
            summary.sync_clicked ();
        }
    }

    public override Gtk.Menu? get_sidebar_context_menu (Granite.Widgets.SourceList list, Granite.Widgets.SourceList.Item item) {
        var menu = new Gtk.Menu ();
        var import_to_library = new Gtk.MenuItem.with_label (_("Import to Library"));
        import_to_library.activate.connect (() => {
            libraries_manager.transfer_to_local_library (device.get_library ().get_medias ());
        });
        menu.append (import_to_library);

        var eject = new Gtk.MenuItem.with_label (_("Eject"));
        eject.activate.connect (() => {
            device.eject ();
        });
        menu.append (eject);

        if (device.get_library ().support_playlists ()) {
            var add_playlist = new Gtk.MenuItem.with_label (_("New Playlist"));
            add_playlist.activate.connect (() => {
                App.main_window.create_new_playlist (device.get_library ());
            });
            menu.append (add_playlist);
        }

        if (device.get_library ().support_smart_playlists ()) {
            var add_smart_playlist = new Gtk.MenuItem.with_label (_("New Smart Playlist"));
            add_smart_playlist.activate.connect (() => {});
            menu.append (add_smart_playlist);
        }

        if (device.read_only () == false) {
            var sync = new Gtk.MenuItem.with_label (_("Sync"));
            sync.activate.connect (() => {
                device.synchronize ();
            });
            menu.append (sync);
        }

        menu.show_all ();
        return menu;
    }

    public override bool filter (string search) {
        return true;
    }
}
