/**
* List the music on a device
*/
public class Noise.DeviceMusicView : View {
    public Device device { get; construct; }
    public TreeViewSetup tvs { get; construct; }
    public Library library { get; construct; }

    private MusicListView list_view { get; set; }

    public DeviceMusicView (TreeViewSetup tvs, Device d, Library library) {
        Object (device: d, tvs: tvs, library: library);
    }

    construct {
        title = _("Music");
        id = device.get_unique_identifier () + "/music";
        category = device.get_unique_identifier ();
        icon = new ThemedIcon ("library-music");
        priority = 1;

        list_view = new MusicListView (tvs, device.read_only ());
        list_view.import_requested.connect (import_request);

        library.media_added.connect ((media) => {
            list_view.add_media (media);
        });
        library.media_removed.connect ((media) => {
            list_view.remove_media (media);
        });

        library.file_operations_done.connect (sync_finished);
        list_view.set_media (library.get_medias ());

        add (list_view);
        show_all ();
    }

    public override void update_alert (Granite.Widgets.AlertView alert) {
        alert.icon_name = "dialog-information";
        alert.title = device.getEmptyDeviceTitle ();
        alert.description = device.getEmptyDeviceDescription ();
    }

    private void import_request (Gee.Collection<Media> to_import) {
        if (!library.doing_file_operations ()) {
            libraries_manager.transfer_to_local_library (to_import);
        }
    }

    private void sync_finished () {
        list_view.set_media (library.get_medias ());
    }

    public override bool filter (string search) {
        return true;
    }
}
