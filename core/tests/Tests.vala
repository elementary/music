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

 
void add_file_utils_tests () {
    Test.add_func ("/FileUtils/count_music_files", () => {
        assert (Noise.FileUtils.count_music_files (File.new_for_path ("../tests/data/count_music_files/"),
                new Gee.ArrayList<string>()) == 3);
    });
}

void main (string[] args) {
    Test.init (ref args);
    add_file_utils_tests ();
    Test.run ();
}