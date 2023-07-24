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
                //TODO doesn't get emitted
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
}
