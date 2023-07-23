public class Music.LibraryManager : Object {
    public ListStore songs { get; construct; }

    private static GLib.Once<LibraryManager> instance;
    public static unowned LibraryManager get_instance () {
        return instance.once (() => { return new LibraryManager (); });
    }

    construct {
        songs = new ListStore (typeof (AudioObject));
        detect_audio_files.begin ();
    }

    public async void detect_audio_files () throws Error {
        File directory = File.new_for_path (Environment.get_user_special_dir (UserDirectory.MUSIC));
        var enumerator = directory.enumerate_children (
            "standard::*",
            FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
            null
        );

        FileInfo info = null;
        while ((info = enumerator.next_file (null)) != null) {
            var file = directory.resolve_relative_path (info.get_name ());
            if (info.get_file_type () == FileType.DIRECTORY) {
                continue;
            } else {
                if (file.query_exists () && "audio" in ContentType.guess (file.get_uri (), null, null)) {
                    var audio_object = new AudioObject (file.get_uri ());

                    string? basename = file.get_basename ();

                    if (basename != null) {
                        audio_object.title = basename;
                    } else {
                        audio_object.title = audio_object.uri;
                    }

                    songs.append (audio_object);
                }
            }
        }
    }
}
