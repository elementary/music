public class Music.LibraryView : Gtk.Box {
    construct {
        var library_manager = LibraryManager.get_instance ();

        var selection_model = new Gtk.SingleSelection (library_manager.songs);

        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect (setup_widget);
        factory.bind.connect (bind_item);

        var list_view = new Gtk.ListView (selection_model, factory) {
            hexpand = true
        };

        append (list_view);
    }

    private void setup_widget (Object obj) {
        var list_item = (Gtk.ListItem) obj;

        list_item.child = new TrackRow ();
    }

    private void bind_item (Object obj) {
        var list_item = (Gtk.ListItem) obj;

        var audio_object = (AudioObject)list_item.item;

        ((TrackRow)list_item.child).bind_audio_object (audio_object);
    }
}
