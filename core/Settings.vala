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
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

namespace Noise.Settings {
    public class Main : Granite.Services.Settings {
        public string music_mount_name { get; set; }
        public string music_folder { get; set; }
        public bool shuffle_mode { get; set; }
        public Repeat repeat_mode { get; set; }
        public string path_string { get; set; }
        public string[] plugins_disabled { get; set;}

        private static Main? main_settings = null;

        public static Main get_default () {
            if (main_settings == null)
                main_settings = new Main ();
            return main_settings;
        }

        public bool privacy_mode_enabled () {
            var privacy_settings = new GLib.Settings ("org.gnome.desktop.privacy");
            return !(privacy_settings.get_boolean ("remember-app-usage") ||
                   privacy_settings.get_boolean ("remember-recent-files"));
        }

        private Main ()  {
            base ("io.elementary.music.settings");
            if (music_folder == "") {
                music_folder = GLib.Environment.get_user_special_dir (GLib.UserDirectory.MUSIC);
            }
        }

    }

    public class Equalizer : Granite.Services.Settings {

        public bool equalizer_enabled { get; set; }
        public bool auto_switch_preset { get; set; }
        public string selected_preset { get; set; }
        public string[] custom_presets { get; set;}

        private static Equalizer? equalizer = null;

        public static Equalizer get_default () {
            if (equalizer == null)
                equalizer = new Equalizer ();
            return equalizer;
        }

        private Equalizer () {
            base ("io.elementary.music.equalizer");
        }

        public Gee.Collection<Noise.EqualizerPreset> get_presets () {
            var presets_data = new Gee.TreeSet<string> ();

            if (custom_presets != null) {
                for (int i = 0; i < custom_presets.length; i++) {
                    presets_data.add (custom_presets[i]);
                }
            }

            var rv = new Gee.TreeSet<Noise.EqualizerPreset>();

            foreach (var preset_str in presets_data) {
                rv.add (new Noise.EqualizerPreset.from_string (preset_str));
            }

            return rv.read_only_view;
        }
    }

    public enum Repeat {
        OFF,
        MEDIA,
        ALBUM,
        ARTIST,
        ALL
    }
}
