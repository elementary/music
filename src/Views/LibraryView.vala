public class Music.LibraryView : Gtk.Box {
    construct {
        var library_manager = LibraryManager.get_instance ();
        var playback_manager = PlaybackManager.get_default ();

        var selection_model = new Gtk.SingleSelection (library_manager.songs) {
            can_unselect = true,
            autoselect = false
        };

        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect (setup_widget);
        factory.bind.connect (bind_item);

        var list_view = new Gtk.ListView (selection_model, factory) {
            hexpand = true
        };

        append (list_view);

        playback_manager.ask_has_next.connect ((repeat_all) => {
            if (selection_model.selected < selection_model.get_n_items () - 1) {
                selection_model.set_selected (selection_model.selected + 1);
                return true;
            } else if (repeat_all) {
                selection_model.set_selected (0);
                return true;
            }

            return false;
        });

        playback_manager.ask_has_previous.connect (() => {
            if (selection_model.selected > 0) {
                selection_model.set_selected (selection_model.selected - 1);
            } else {
                selection_model.set_selected (selection_model.get_n_items () - 1);
            }

            return true;
        });

        selection_model.selection_changed.connect (() => {
            //TODO: Should clear play queue?
            playback_manager.current_audio = (AudioObject)selection_model.get_selected_item ();
        });

        selection_model.set_selected (Gtk.INVALID_LIST_POSITION);
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
