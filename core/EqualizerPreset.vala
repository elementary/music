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
 * The Music authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Music. This permission is above and beyond the permissions granted
 * by the GPL license by which Music is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 *              Corentin Noël <corentin@elementary.io>
 */

public class Music.EqualizerPreset : Object {
    public string name { get; construct set; }
    public Gee.ArrayList<int> gains = new Gee.ArrayList<int> ();

    public bool is_default { get; set; default = false; }

    public EqualizerPreset.basic (string name) {
        Object (name: name);
        for (int i = 0; i < 10; i++) {
            gains.add (0);
        }
    }

    public EqualizerPreset.with_gains (string name, int[] items) {
        Object (name: name);
        for (int i = 0; i < 10; i++) {
            gains.add (items[i]);
        }
    }

    public EqualizerPreset.from_string (string data) {
        var vals = data.split ("/", 0);
        Object (name: vals[0]);
        for (int i = 1; i < vals.length; i++) {
            gains.add (int.parse (vals[i]));
        }
    }

    public string to_string () {
        string str_preset = "";

        if (name != null && name != "") {
            str_preset = name;
            for (int i = 0; i < 10; i++) {
                str_preset += "/" + get_gain (i).to_string ();
            }
        }

        return str_preset;
    }

    public void set_gain (int index, int val) {
        if (index > 9) {
            return;
        }

        gains[index] = val;
    }

    public int get_gain (int index) {
        return gains[index];
    }
}
