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

    public override bool filter (string search) {
        return true;
    }
}
