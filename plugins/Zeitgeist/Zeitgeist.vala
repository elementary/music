
namespace Noise.Plugins {

    public class ZeitgeistPlugin : Peas.ExtensionBase, Peas.Activatable {

        public Object object { owned get; construct; }

        Zeitgeist.Log zeitgeist;
        PlaybackManager player;

        Media? current_song = null;

        bool connected = false;

        public void activate () {
            message ("Activating Zeitgeist plugin");

            zeitgeist = Zeitgeist.Log.get_default ();

            Value value = Value (typeof (Object));
            get_property ("object", ref value);
            var plugins = (Noise.Plugins.Interface) value.get_object();

            plugins.register_function (Interface.Hook.WINDOW, () => {
                connected = true;

                player = Noise.App.player;
                player.media_played.connect (media_changed);
            });
        }

        public void deactivate () {
            if (connected)
                player.media_played.disconnect (media_changed);

            connected = false;
        }

        void media_changed (Media played_media) {
            if (current_song != null)
                log_interaction.begin (current_song, Zeitgeist.ZG.LEAVE_EVENT);

            log_interaction.begin (played_media, Zeitgeist.ZG.ACCESS_EVENT);
            current_song = played_media;
        }

        async void log_interaction (Media song, string interpretation) {
            var time = new DateTime.now_local ().to_unix () * 1000;

            FileInfo? info = null;
            try {
                info = yield song.file.query_info_async (FileAttribute.STANDARD_CONTENT_TYPE, 0);
            } catch (Error e) {}

            var subject = new Zeitgeist.Subject ();
            subject.uri = song.uri;
            subject.interpretation = Zeitgeist.NFO.AUDIO;
            subject.manifestation = Zeitgeist.NFO.FILE_DATA_OBJECT;
            subject.origin = song.get_display_location ();
            subject.mimetype = info != null ? info.get_content_type () : null;
            subject.text = "%s - %s - %s".printf (song.get_display_title (),
                    song.get_display_artist (), song.get_display_album ());

            var event = new Zeitgeist.Event ();
            event.timestamp = time;
            event.interpretation = interpretation;
            event.manifestation = Zeitgeist.ZG.USER_ACTIVITY;
            event.actor = "application://noise.desktop";
            event.add_subject (subject);

            try {
                zeitgeist.insert_event_no_reply (event);
            } catch (Error e) {
                warning ("Logging to zeitgeist failed: %s", e.message);
            }
        }

        public void update_state () {
        }
    }
}

[ModuleInit]
public void peas_register_types (TypeModule module) {
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type (typeof (Peas.Activatable),
            typeof (Noise.Plugins.ZeitgeistPlugin));
}
