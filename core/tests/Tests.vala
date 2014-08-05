/*-
 * Copyright (c) 2014 elementary Developers
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
