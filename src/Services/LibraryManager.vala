public class Music.LibraryManager : Object {
    public ListStore songs { get; construct; }

    private Tracker.Sparql.Connection tracker_connection;
    private Tracker.Notifier notifier;
    private HashTable<string, AudioObject> songs_by_id;

    private static GLib.Once<LibraryManager> instance;
    public static unowned LibraryManager get_instance () {
        return instance.once (() => { return new LibraryManager (); });
    }

    construct {
        songs = new ListStore (typeof (AudioObject));
        songs_by_id = new HashTable<string, AudioObject> (str_hash, str_equal);

        try {
            tracker_connection = Tracker.Sparql.Connection.bus_new ("org.freedesktop.Tracker3.Miner.Files", null, null);

            notifier = tracker_connection.create_notifier ();
            if (notifier != null) {
                notifier.events.connect (on_tracker_event);
            }
        } catch (Error e) {
            warning (e.message);
        }
    }

    public async void get_audio_files () {
        try {
            // There currently is a bug in tracker that from a flatpak large queries will stall indefinitely.
            // Therefore we query all ID's and do separate queries for the details of each ID
            // This will cost us quite a bit of performance which shoudln't be visible thought
            // as it only leads to the library filling bit by bit but doesn't block anything
            // Tested with Ryzen 5 3600 and about 600 Songs it took 1/2 second to fully load
            var tracker_statement_id = tracker_connection.query_statement (
                """
                    SELECT tracker:id(?urn)
                    WHERE {
                        GRAPH tracker:Audio {
                            SELECT ?song AS ?urn
                            WHERE {
                                ?song a nmm:MusicPiece .
                            }
                        }
                    }
                """
            );

            var id_cursor = yield tracker_statement_id.execute_async (null);

            while (yield id_cursor.next_async ()) {
                yield query_update_audio_object (id_cursor.get_integer (0), false);
            }

            id_cursor.close ();

            // This would be the actual query:

            // var tracker_statement = tracker_connection.query_statement (
            //     """
            //         SELECT ?url ?title ?artist ?duration
            //         WHERE {
            //             GRAPH tracker:Audio {
            //                 SELECT ?url ?title ?artist ?duration
            //                 WHERE {
            //                     ?song a nmm:MusicPiece ;
            //                           nie:isStoredAs ?url .
            //                     OPTIONAL {
            //                         ?song nie:title ?title
            //                     } .
            //                     OPTIONAL {
            //                         ?song nmm:artist [ nmm:artistName ?artist ] ;
            //                     } .
            //                     OPTIONAL {
            //                         ?song nfo:duration ?duration ;
            //                     } .
            //                 }
            //             }
            //         }
            //     """
            // );
        } catch (Error e) {
            warning (e.message);
        }
    }

    private void on_tracker_event (string? service, string? graph, GenericArray<Tracker.NotifierEvent> events) {
        foreach (var event in events) {
            var type = event.get_event_type ();
            switch (type) {
                case DELETE:
                    var id = event.get_id ().to_string ();
                    var audio_object = songs_by_id[id];

                    if (audio_object != null) {
                        songs_by_id.remove (id);

                        uint position = Gtk.INVALID_LIST_POSITION;
                        if (songs.find_with_equal_func (audio_object, equal_func, out position)) {
                            songs.remove (position);
                        }
                    }
                    break;

                case CREATE:
                    query_update_audio_object.begin (event.get_id (), false);
                    break;

                case UPDATE:
                    query_update_audio_object.begin (event.get_id (), true);
                    break;
            }
        }
    }

    private async void query_update_audio_object (int64 id, bool update) {
        try {
            var tracker_statement = tracker_connection.query_statement (
                """
                    SELECT ?url ?title ?artist ?duration
                    WHERE {
                        GRAPH tracker:Audio {
                            SELECT ?song ?url ?title ?artist ?duration
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
                                FILTER(tracker:id (?song) = ~id)
                            }
                        }
                    }
                """
            );

            tracker_statement.bind_int ("id", id);

            var cursor = yield tracker_statement.execute_async (null);

            while (cursor.next ()) {
                create_audio_object (id, cursor, update);
            }

            cursor.close ();
        } catch (Error e) {
            warning (e.message);
        }
    }

    private void create_audio_object (int64 _id, Tracker.Sparql.Cursor cursor, bool update = false) {
        var id = _id.to_string (); //TODO: Maybe use the int64 directly as key

        AudioObject? audio_object = songs_by_id[id];

        uint position = Gtk.INVALID_LIST_POSITION;
        bool found = false;

        if (audio_object == null) {
            audio_object = new AudioObject ();
        } else if (!update) {
            return;
        } else {
            found = songs.find_with_equal_func (audio_object, equal_func, out position);
        }

        audio_object.uri = cursor.get_string (0);

        if (cursor.is_bound (1)) {
            audio_object.title = cursor.get_string (1);
        } else {
            audio_object.title = audio_object.uri; //TODO: Try basename, only then use URI
        }

        if (cursor.is_bound (2)) {
            audio_object.artist = cursor.get_string (2);
        }

        if (cursor.is_bound (3)) {
            audio_object.duration = cursor.get_integer (3);
        }

        if (found) {
            songs.items_changed (position, 1, 1);
        } else {
            songs.insert_sorted (audio_object, compare_func);
            songs_by_id[id] = audio_object;
        }
    }

    private static int compare_func (Object a, Object b) {
        return ((AudioObject) a).title.collate (((AudioObject) b).title);
    }

    private static bool equal_func (Object a, Object b) {
        return ((AudioObject) a).uri == ((AudioObject) b).uri;
    }
}
