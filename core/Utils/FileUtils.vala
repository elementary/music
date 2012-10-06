// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
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

    public const string APP_NAME = "noise"; // TODO: get this info from build system

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

    /**
     * Asynchronously checks whether a file exists or not.
     * It follows symbolic links.
     */
    public async bool query_exists_async (File file_or_dir, Cancellable? cancellable = null) {
        FileInfo? info = null;

        try {
            info = yield file_or_dir.query_info_async (FileAttribute.STANDARD_NAME,
                                                       FileQueryInfoFlags.NONE,
                                                       Priority.DEFAULT,
                                                       cancellable);
        } catch (Error err) {
            if (err is IOError.NOT_FOUND)
                return false;
        }

        return info != null;
    }

    /**
     * Convenience method to get the size of a file or directory (recursively)
     *
     * @param file a {@link GLib.File} representing the file or directory to be queried
     *
     * @return size in bytes of file. It is recommended to use GLib.format_size() in case
     *         you want to convert it to a string representation.
     */
    public async uint64 get_size_async (File file_or_dir, Cancellable? cancellable = null) {
        uint64 size = 0;
        Gee.Collection<File> files;

        if (yield is_directory_async (file_or_dir, cancellable)) {
            yield enumerate_files_async (file_or_dir, null, true, out files, cancellable);
        } else {
            files = new Gee.LinkedList<File> ();
            files.add (file_or_dir);
        }

        foreach (var file in files) {
            if (Utils.is_cancelled (cancellable))
                break;

            try {
                var info = yield file.query_info_async (FileAttribute.STANDARD_SIZE,
                                                        FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                                                        Priority.DEFAULT,
                                                        cancellable);
                size += info.get_attribute_uint64 (FileAttribute.STANDARD_SIZE);
            } catch (Error err) {
                warning ("Could not get size of '%s': %s", file.get_uri (), err.message);
            }
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
     * Enumerates the files contained by folder.
     *
     * @param folder a {@link GLib.File} representing the folder you wish to query
     * @param types a string array containing the formats you want to limit the search to, or null
     *              to allow any file type. e.g. string[] types = {"mp3", "jpg"} [allow-none]
     * @param recursive whether to query the whole directory tree or only immediate children. [allow-none]
     * @param files the data container for the files found. This only includes files, not directories [allow-none]
     * @param cancellable a cancellable object for canceling the operation. [allow-none]
     *
     * @return total number of files found (should be the same as files.size)
     */
    public async uint enumerate_files_async (File folder, string[]? types = null,
                                             bool recursive = true,
                                             out Gee.Collection<File>? files = null,
                                             Cancellable? cancellable = null)
    {
        return_val_if_fail (yield is_directory_async (folder), 0);
        var counter = new FileEnumerator ();
        return yield counter.enumerate_files_async (folder, types, out files, recursive, cancellable);
    }

    /**
     * Queries whether a filename matches a given extension.
     *
     * @param name path, URI or name of the file to verify
     * @param types a string array containing the expected file extensions (without dot).
     *              e.g. [[[ string[] types = { "png", "m4a", "mp3" }; ]]]
     *
     * @return true if the file is considered valid; false otherwise
     */
	public bool is_valid_file_type (string filename, string[] types) {
		var name = filename.down ();

        foreach (var suffix in types) {
            if (name.has_suffix ("." + suffix.down ()))
                return true;
        }

        return false;
	}

    /**
     * A class for counting the number of files contained by a directory, without
     * counting folders.
     */
    private class FileEnumerator {
        private uint file_count = 0;
        private const string ATTRIBUTES = FileAttribute.STANDARD_NAME
                                            + "," + FileAttribute.STANDARD_TYPE;
        private string[]? types = null;
        private Cancellable? cancellable = null;

        /**
         * Enumerates the number of files contained by a directory. By default it
         * operates recursively; that is, it will count all the files contained by
         * the directories descendant from folder. In case you only want the first-level
         * descendants, set recursive to false.
         */
        public async uint enumerate_files_async (File folder, string[]? types,
                                                 out Gee.Collection<File>? files,
                                                 bool recursive = true,
                                                 Cancellable? cancellable = null)
        {
            assert (file_count == 0);

            this.types = types;
            this.cancellable = cancellable;

            files = new Gee.LinkedList<File> ();
            yield enumerate_files_internal_async (folder, files, recursive);
            return file_count;
        }

        private inline bool is_cancelled () {
            return Utils.is_cancelled (cancellable);
        }

        private async void enumerate_files_internal_async (File folder, Gee.Collection<File>? files,
                                                           bool recursive)
        {
            if (is_cancelled ())
                return;

            try {
                var enumerator = yield folder.enumerate_children_async (ATTRIBUTES,
                                                                        FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                                                                        Priority.DEFAULT,
                                                                        cancellable);

                while (!is_cancelled ()) {
                    var enum_files = yield enumerator.next_files_async (1, Priority.DEFAULT, cancellable);
                    FileInfo? file_info = enum_files.nth_data (0);

                    if (file_info == null)
                        break;

                    var file_name = file_info.get_name ();
                    var file_type = file_info.get_file_type ();
                    var file = folder.get_child (file_name);

                    if (file_type == FileType.REGULAR) {
                        if (this.types != null && !is_valid_file_type (file_name, this.types))
                            continue;

	                    file_count++;

                        if (files != null)
    	                    files.add (file);
                    } else if (recursive && file_type == FileType.DIRECTORY) {
	                    yield enumerate_files_internal_async (file, files, true);
                    }
                }
            } catch (Error err) {
                warning ("Could not scan folder: %s", err.message);
            }
        }
    }
}
