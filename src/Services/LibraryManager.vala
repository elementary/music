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
        new Thread<void*> (null, () => {
            try {
                var tracker_statement = tracker_connection.query_statement (
                    """
                        SELECT ?urn ?url ?title ?artist ?duration
                        WHERE {
                            GRAPH tracker:Audio {
                                SELECT ?song AS ?urn ?url ?title ?artist ?duration
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
                    create_audio_object (cursor, false);
                }

                cursor.close ();
            } catch (Error e) {
                warning (e.message);
            }

            Idle.add (get_audio_files.callback);
            return null;
        });

        yield;
    }

    private void on_tracker_event (string? service, string? graph, GenericArray<Tracker.NotifierEvent> events) {
        foreach (var event in events) {
            var type = event.get_event_type ();
            switch (type) {
                case DELETE:
                    break;

                case CREATE:
                    query_update_audio_object (event.get_urn (), false);
                    break;

                case UPDATE:
                    query_update_audio_object (event.get_urn (), true);
                    break;
            }
        }
    }

    private void query_update_audio_object (string urn, bool update) {
        try {
            var tracker_statement = tracker_connection.query_statement (
                """
                    SELECT ~urn ?url ?title ?artist ?duration
                    WHERE {
                        GRAPH tracker:Audio {
                            SELECT ~urn ?url ?title ?artist ?duration
                            WHERE {
                                ~urn a nmm:MusicPiece ;
                                     nie:isStoredAs ?url .
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
                create_audio_object (cursor, update);
            }

            cursor.close ();
        } catch (Error e) {
            warning (e.message);
        }
    }

    private void create_audio_object (Tracker.Sparql.Cursor cursor, bool update = false) {
        var urn = cursor.get_string (0);

        AudioObject? audio_object = songs_by_urn[urn];

        uint position = Gtk.INVALID_LIST_POSITION;
        bool found = false;

        if (audio_object == null) {
            audio_object = new AudioObject ();
        } else if (!update) {
            return;
        } else {
            found = songs.find_with_equal_func (audio_object, equal_func, out position);
        }

        audio_object.uri = cursor.get_string (1);

        if (cursor.is_bound (2)) {
            audio_object.title = cursor.get_string (2);
        } else {
            audio_object.title = audio_object.uri; //TODO: Try basename, only then use URI
        }

        if (cursor.is_bound (3)) {
            audio_object.artist = cursor.get_string (3);
        }

        if (cursor.is_bound (4)) {
            audio_object.duration = cursor.get_integer (4);
        }

        if (found) {
            songs.items_changed (position, 1, 1);
        } else {
            songs.append (audio_object);
            songs_by_urn[urn] = audio_object;
        }
    }

    private static bool equal_func (Object a, Object b) {
        return ((AudioObject) a).uri == ((AudioObject) b).uri;
    }
}
