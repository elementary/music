public class Music.LibraryManager : Object {
    public ListStore songs { get; construct; }

    private Tracker.Sparql.Connection tracker_connection;

    private static GLib.Once<LibraryManager> instance;
    public static unowned LibraryManager get_instance () {
        return instance.once (() => { return new LibraryManager (); });
    }

    construct {
        songs = new ListStore (typeof (AudioObject));

        try {
            tracker_connection = Tracker.Sparql.Connection.bus_new ("org.freedesktop.Tracker3.Miner.Files", null, null);

            var notifier = tracker_connection.create_notifier ();
            if (notifier != null) {
                notifier.events.connect (on_tracker_event);
            }

            get_audio_files.begin ();
        } catch (Error e) {
            warning (e.message);
        }
    }

    private async void get_audio_files () {
        try {
            var tracker_statement = tracker_connection.query_statement (
                """
                    SELECT ?url ?title ?artist ?duration
                    WHERE {
                        GRAPH tracker:Audio {
                            SELECT ?url ?title ?artist ?duration
                            WHERE {
                                ?song a nmm:MusicPiece ;
                                        nie:isStoredAs ?url .
                                OPTIONAL {
                                    ?song nie:title ?title
                                } .
                                OPTIONAL {
                                    ?song nmm:artist [ nmm:artistName ?artist ] ;
                                } .
                                OPTIONAL {
                                    ?song nfo:duration ?duration ;
                                } .
                            }
                        }
                    }
                """
            );

            var cursor = tracker_statement.execute (null);

            while (cursor.next ()) {
                var audio_object = new AudioObject (cursor.get_string (0));

                if (cursor.is_bound (1)) {
                    audio_object.title = cursor.get_string (1);
                } else {
                    audio_object.title = audio_object.uri;
                }

                if (cursor.is_bound (2)) {
                    audio_object.artist = cursor.get_string (2);
                }

                if (cursor.is_bound (3)) {
                    audio_object.duration = cursor.get_integer (3);
                }

                songs.append (audio_object);
            }

            cursor.close ();
        } catch (Error e) {
            warning (e.message);
        }
    }

    private void on_tracker_event (string service, string graph, GenericArray<Tracker.NotifierEvent> events) {
        print (service);
        print (graph);
        foreach (var event in events) {
            var type = event.get_event_type ();
            switch (type) {
                case DELETE:
                    print ("FILE DELETED");
                    break;

                case CREATE:
                    print ("FILE CREATED");
                    break;

                case UPDATE:
                    print ("FILE UPDATED");
                    break;
            }
        }
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
