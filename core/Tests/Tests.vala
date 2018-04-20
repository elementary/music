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
 */


static bool check_list_element_has_suffix (Gee.Collection<string> list, string suffix) {
    bool found = false;
    foreach (var s in list) {
        found = found || s.has_suffix (suffix);
    }
    return found;
}

void add_file_utils_tests () {
    Test.add_func ("/FileUtils/count_music_files", () => {
        var files = new Gee.ArrayList<string> ();
        assert (Noise.FileUtils.count_music_files (File.new_for_path (TEST_DATA_FILE + "/data/count_music_files/"),
                files) == 3);

        assert (check_list_element_has_suffix (files, "tests/data/count_music_files/file1.mp3"));
        assert (check_list_element_has_suffix (files, "tests/data/count_music_files/file1.ogg"));
        assert (check_list_element_has_suffix (files, "tests/data/count_music_files/file1.wav"));
        assert (files[0].has_prefix ("file:///"));

        files.clear();

        assert (Noise.FileUtils.count_music_files (File.new_for_path (TEST_DATA_FILE + "/data/count_music_files_subdir/"),
                files) == 4);

        assert (check_list_element_has_suffix (files, "tests/data/count_music_files_subdir/file1.mp3"));
        assert (check_list_element_has_suffix (files, "tests/data/count_music_files_subdir/file1.ogg"));
        assert (check_list_element_has_suffix (files, "tests/data/count_music_files_subdir/file1.wav"));
        assert (check_list_element_has_suffix (files, "tests/data/count_music_files_subdir/sub/file1.mp3"));

    });

    Test.add_func ("/FileUtils/is_valid_content_type", () => {
        assert (Noise.FileUtils.is_valid_content_type ("audio/mpeg", {"audio/mpeg"}));
    });
}

int main (string[] args) {
    Test.init (ref args);
    add_file_utils_tests ();
    return Test.run ();
}
