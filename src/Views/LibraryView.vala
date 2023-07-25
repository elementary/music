public class Music.LibraryView : Gtk.Box {
    private Gtk.Stack placeholder_stack;
    private Gtk.SingleSelection selection_model;

    construct {
        var library_manager = LibraryManager.get_instance ();
        var playback_manager = PlaybackManager.get_default ();

        var placeholder = new Granite.Placeholder (_("No Songs found")) {
            description = _("Audio files in your Music directory will appear here"),
            icon = new ThemedIcon ("folder-music")
        };

        // var sort_model = new Gtk.SortListModel (library_manager.songs, new Gtk.CustomSorter (sort_func));

        selection_model = new Gtk.SingleSelection (library_manager.songs) {
            can_unselect = true,
            autoselect = false
        };

        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect (setup_widget);
        factory.bind.connect (bind_item);

        var list_view = new Gtk.ListView (selection_model, factory) {
            hexpand = true
        };

        var scrolled_window = new Gtk.ScrolledWindow () {
            child = list_view
        };

        placeholder_stack = new Gtk.Stack ();
        placeholder_stack.add_named (scrolled_window, "list-view");
        placeholder_stack.add_named (placeholder, "placeholder");

        append (placeholder_stack);

        selection_model.items_changed.connect (update_stack);

        selection_model.selection_changed.connect (() => {
            //TODO: Should clear play queue?
            playback_manager.current_audio = (AudioObject)selection_model.get_selected_item ();
        });

        selection_model.set_selected (Gtk.INVALID_LIST_POSITION);
        update_stack ();

        playback_manager.ask_has_next.connect ((repeat_all) => {
            if (selection_model.get_n_items () == 0) {
                return false;
            }

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
            if (selection_model.get_n_items () == 0) {
                return false;
            }

            if (selection_model.selected > 0) {
                selection_model.set_selected (selection_model.selected - 1);
            } else {
                selection_model.set_selected (selection_model.get_n_items () - 1);
            }

            return true;
        });
    }

    // private static int sort_func<null> (Object a, Object b) {
    //     var audio_object_a = (AudioObject)a;
    //     var audio_object_b = (AudioObject)b;
    //     return audio_object_a.title.collate (audio_object_b.title);
    // }

    private void update_stack () {
        placeholder_stack.visible_child_name = selection_model.get_n_items () > 0 ? "list-view" : "placeholder";
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
