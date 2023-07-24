public class Music.LibraryManager : Object {
    public ListStore songs { get; construct; }

    private Tracker.Sparql.Connection tracker_connection;
    private Tracker.Notifier notifier;
    private HashTable<string, AudioObject> songs_by_urn;

    private static GLib.Once<LibraryManager> instance;
    public static unowned LibraryManager get_instance () {
        return instance.once (() => { return new LibraryManager (); });
    }

    construct {
        songs = new ListStore (typeof (AudioObject));
        songs_by_urn = new HashTable<string, AudioObject> (str_hash, str_equal);

        try {
            tracker_connection = Tracker.Sparql.Connection.bus_new ("org.freedesktop.Tracker3.Miner.Files", null, null);

            notifier = tracker_connection.create_notifier ();
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
                    SELECT ?url ?title ?artist ?duration ?id
                    WHERE {
                        GRAPH tracker:Audio {
                            SELECT ?url ?title ?artist ?duration ?song AS ?id
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

                songs_by_urn[cursor.get_string (4)] = audio_object;

                songs.append (audio_object);
            }

            cursor.close ();
        } catch (Error e) {
            warning (e.message);
        }
    }

    private void on_tracker_event (string? service, string? graph, GenericArray<Tracker.NotifierEvent> events) {
        foreach (var event in events) {
            if (event.get_urn () == null) {
                continue;
            }

            var type = event.get_event_type ();
            switch (type) {
                case DELETE:
                    var audio_object = songs_by_urn[event.get_urn ()];
                    if (audio_object != null) {
                        uint position = Gtk.INVALID_LIST_POSITION;
                        if (songs.find_with_equal_func (audio_object, equal_func, out position)) {
                            songs.remove (position);
                        }
                    }
                    break;

                case CREATE:
                    update_audio_object (event.get_urn ());
                    break;

                case UPDATE:
                    update_audio_object (event.get_urn ());
                    break;
            }
        }
    }

    private void update_audio_object (string urn) {
        try {
            var tracker_statement = tracker_connection.query_statement (
                """
                    SELECT ?url ?title ?artist ?duration
                    WHERE {
                        GRAPH tracker:Audio {
                            SELECT ?url ?title ?artist ?duration
                            WHERE {
                                ~urn nie:isStoredAs ?url .
                                OPTIONAL {
                                    ~urn nie:title ?title
                                } .
                                OPTIONAL {
                                    ~urn nmm:artist [ nmm:artistName ?artist ] ;
                                } .
                                OPTIONAL {
                                    ~urn nfo:duration ?duration ;
                                } .
                            }
                        }
                    }
                """
            );

            tracker_statement.bind_string ("urn", urn);

            var cursor = tracker_statement.execute (null);

            while (cursor.next ()) {
                uint position = Gtk.INVALID_LIST_POSITION;
                bool found = false;
                AudioObject audio_object;

                if (!(urn in songs_by_urn)) {
                    audio_object = new AudioObject (cursor.get_string (0));
                } else {
                    audio_object = songs_by_urn[urn];
                    found = songs.find_with_equal_func (audio_object, equal_func, out position);

                    audio_object.uri = cursor.get_string (0);
                }

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

                if (found) {
                    songs.items_changed (position, 1, 1);
                } else {
                    songs.append (audio_object);
                }
            }

            cursor.close ();
        } catch (Error e) {
            warning (e.message);
        }
    }

    private static bool equal_func (Object a, Object b) {
        return ((AudioObject) a).uri == ((AudioObject) b).uri;
    }
}
