public class Music.LibraryManager : Object {
    public ListStore songs { get; construct; }

    // private List<FileMonitor> directory_monitors;
    // private Queue<File> unchecked_directories;
    // private HashTable<string, uint> position_by_uri;
    // private bool is_scanning = false;

    private static GLib.Once<LibraryManager> instance;
    public static unowned LibraryManager get_instance () {
        return instance.once (() => { return new LibraryManager (); });
    }

    construct {
        songs = new ListStore (typeof (AudioObject));

        try {
            var tracker_connection = Tracker.Sparql.Connection.bus_new ("org.freedesktop.Tracker3.Miner.Files", null, null);

            var tracker_statement = tracker_connection.query_statement (
                """SELECT nie:url(?u) WHERE { ?u a nfo:FileDataObject ; nfo:fileName "dicht & ergreifend - Zipfeschwinga.mp3" }"""
            );

            print ("execute");
            var cursor = tracker_statement.execute (null);

            print ("finish execute");

            int i = 0;
            while (cursor.next ()) {
                print ("Result [%i]: %s\n", i++, cursor.get_string (0));
            }
            print ("finished");

            cursor.close ();
            tracker_connection.close ();
        } catch (Error e) {
            warning (e.message);
        }
        // directory_monitors = new List<FileMonitor> ();
        // unchecked_directories = new Queue<File> ();
        // unchecked_directories.push_tail (File.new_for_path (Environment.get_user_special_dir (UserDirectory.MUSIC)));
        // position_by_uri = new HashTable<string, uint> (str_hash, str_equal);

        // detect_audio_files.begin ();
    }

    // private void on_directory_change (File file, File? other_file, FileMonitorEvent event_type) {
    //     uint position = Gtk.INVALID_LIST_POSITION;
    //     if (file.get_uri () in position_by_uri) {
    //         position = position_by_uri[file.get_uri ()];
    //     }

    //     switch (event_type) {
    //         case DELETED:
    //             if (position != Gtk.INVALID_LIST_POSITION) {
    //                 songs.remove (position);
    //             }
    //             break;

    //         case CHANGES_DONE_HINT:
    //             if (position != Gtk.INVALID_LIST_POSITION) {
    //                 songs.remove (position);
    //             }

    //             FileInfo file_info;
    //             try {
    //                 file_info = file.query_info ("standard::*", NONE);
    //             } catch (Error e) {
    //                 warning (e.message);
    //                 return;
    //             }

    //             if (file_info.get_file_type () == FileType.DIRECTORY) {
    //                 unchecked_directories.push_tail (file);
    //                 detect_audio_files.begin ();
    //             } else if (is_file_valid (file)) {
    //                 songs.append (new AudioObject.from_file (file));
    //             }

    //             break;

    //         default:
    //             break;
    //     }
    // }

    // public async void detect_audio_files () {
    //     if (is_scanning) {
    //         return;
    //     }

    //     is_scanning = true;

    //     while (!unchecked_directories.is_empty ()) {
    //         var directory = unchecked_directories.pop_head ();

    //         try {
    //             var directory_monitor = directory.monitor (NONE);
    //             directory_monitor.changed.connect (on_directory_change);
    //             directory_monitors.append (directory_monitor);
    //         } catch (Error e) {
    //             warning ("Failed to monitor directory %s: %s", directory.get_path (), e.message);
    //         }

    //         try {
    //             var enumerator = directory.enumerate_children (
    //                 "standard::*",
    //                 FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
    //                 null
    //             );

    //             FileInfo info = null;
    //             while ((info = enumerator.next_file (null)) != null) {
    //                 var file = directory.resolve_relative_path (info.get_name ());
    //                 if (info.get_file_type () == FileType.DIRECTORY) {
    //                     unchecked_directories.push_tail (file);
    //                     continue;
    //                 } else {
    //                     if (is_file_valid (file)) {
    //                         songs.append (new AudioObject.from_file (file));
    //                         position_by_uri[file.get_uri ()] = songs.get_n_items () - 1;
    //                     }
    //                 }
    //             }
    //         } catch (Error e) {
    //             warning ("Failed to get children of directory %s: %s", directory.get_path (), e.message);
    //         }
    //     }

    //     is_scanning = false;
    // }

    // private bool is_file_valid (File file) {
    //     return file.query_exists () && "audio" in ContentType.guess (file.get_uri (), null, null);
    // }
}
