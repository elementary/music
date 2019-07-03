// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 *              Scott Ringwelski <sgringwe@mtu.edu>
 */

namespace Noise.FileUtils {

    public const string APP_NAME = "noise";

    public File get_data_directory () {
        string data_dir = Environment.get_user_data_dir ();
        string dir_path = Path.build_path (Path.DIR_SEPARATOR_S, data_dir, APP_NAME);
        return File.new_for_path (dir_path);
    }

    public File get_cache_directory () {
        string data_dir = Environment.get_user_cache_dir ();
        string dir_path = Path.build_path (Path.DIR_SEPARATOR_S, data_dir, APP_NAME);
        return File.new_for_path (dir_path);
    }

    public uint64 get_size (File file, Cancellable? cancellable = null) {
        uint64 size = 0;

        try {
            var info = file.query_info (FileAttribute.STANDARD_SIZE,
                                        FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                                        cancellable);
            size = info.get_attribute_uint64 (FileAttribute.STANDARD_SIZE);
        } catch (Error err) {
            warning ("Could not get size of '%s': %s", file.get_uri (), err.message);
        }

        return size;
    }

    /**
     * Checks whether //dir// is a directory.
     * Does not follow symbolic links.
     */
    public async bool is_directory_async (File dir, Cancellable? cancellable = null) {
        FileInfo? info = null;

        try {
            info = yield dir.query_info_async (FileAttribute.STANDARD_TYPE,
                                               FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                                               Priority.DEFAULT,
                                               cancellable);
        } catch (Error err) {
            warning (err.message);
        }

        return info != null && info.get_file_type () == FileType.DIRECTORY;
    }

    /**
     * Queries whether a content type equals or is a subtype of any other type in
     * an array of content types.
     *
     * @param file_content_type Content type of the file to compare.
     * @param content_types A string array containing the expected content types to compare against.
     * @return whether file_content_type is considered valid.
     */
    public bool is_valid_content_type (string file_content_type, string[]? content_types = null) {
        var considered_content_type = content_types;
        if (content_types == null) {
            considered_content_type = MEDIA_CONTENT_TYPES;
        }

        foreach (var content_type in considered_content_type) {
            if (ContentType.equals (file_content_type, content_type)) {
                return true;
            }
        }

        return false;
    }

    public int count_music_files (File music_folder, Gee.Collection<string> files) {
        FileInfo file_info = null;
        int index = 0;

        try {
            var enumerator = music_folder.enumerate_children(FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE + "," + FileAttribute.STANDARD_CONTENT_TYPE, 0);
            while ((file_info = enumerator.next_file ()) != null) {
                var file = music_folder.get_child (file_info.get_name ());

                if(file_info.get_file_type() == FileType.REGULAR && is_valid_content_type(file_info.get_content_type ())) {
                    index++;
                    files.add (file.get_uri ());
                } else if(file_info.get_file_type() == FileType.DIRECTORY) {
                    index += count_music_files (file, files);
                }
            }
        } catch(Error err) {
            warning("Could not pre-scan music folder. Progress percentage may be off: %s\n", err.message);
        }

        return index;
    }

    public File? get_new_destination(Media s) {
        File dest;

        try {
            File original = File.new_for_uri(s.uri);

            var ext = "";
            if (s.uri.has_prefix("cdda://")) {
                ext = ".mp3";
            } else {
                ext = s.uri.slice (s.uri.last_index_of (".", 0), s.uri.length);
            }

            /* Available translations are $ALBUM $ARTIST $ALBUM_ARTIST $TITLE $TRACK*/
            var main_settings = Settings.Main.get_default ();
            string path = main_settings.path_string;
            if (path == "" || path == null) {
                path = "$ALBUM_ARTIST/$ALBUM/$TRACK - $TITLE";
                main_settings.path_string = "$ALBUM_ARTIST/$ALBUM/$TRACK - $TITLE";
            }

            path = path.replace ("$ALBUM_ARTIST", s.get_display_album_artist ().replace("/", "_"));
            path = path.replace ("$ARTIST", s.get_display_artist ().replace("/", "_"));
            path = path.replace ("$ALBUM", s.get_display_album ().replace("/", "_"));
            path = path.replace ("$TITLE", s.get_display_title ().replace("/", "_"));
            path = path.replace ("$TRACK", s.track.to_string());

            dest = File.new_for_path(Path.build_path("/", main_settings.music_folder, path + ext));

            if (original.get_path ().contains (dest.get_path ())) {
                debug("File is already in correct location\n");
                return null;
            }

            if (dest.query_exists ()) {
                int number = 2;
                while((dest = File.new_for_path(Path.build_path("/", main_settings.music_folder, path + _(" (%d)").printf (number) + ext))).query_exists()) {
                    number++;
                }
            }

            /* make sure that the parent folders exist */
            if(!dest.get_parent().query_exists()) {
                dest.get_parent().make_directory_with_parents(null);
            }
        } catch(Error err) {
            debug("Could not find new destination!: %s\n", err.message);
        }

        return dest;
    }
}
