// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2017 elementary LLC. (https://elementary.io)
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
    public class SavedState : Granite.Services.Settings {

        public int window_width { get; set; }
        public int window_height { get; set; }
        public WindowState window_state { get; set; }
        public int sidebar_width { get; set; }
        public int more_width { get; set; }
        public bool more_visible { get; set; }
        public int view_mode { get; set; }
        public int column_browser_width { get; set; }
        public int column_browser_height { get; set; }
        public bool column_browser_enabled { get; set; }
        public bool show_album_art_in_list_view { get; set; }
        public string[] column_browser_visible_columns { get; set; }
        public int column_browser_position { get; set; }

        private static SavedState? saved_state = null;

        public static SavedState get_default () {
            if (saved_state == null)
                saved_state = new SavedState ();
            return saved_state;
        }

        private SavedState () {
            base ("org.pantheon.noise.saved-state");
        }
    }

    public class Main : Granite.Services.Settings {

        public string music_mount_name { get; set; }
        public string music_folder { get; set; }
        public bool update_folder_hierarchy { get; set; }
        public bool write_metadata_to_file { get; set; }
        public bool copy_imported_music { get; set; }
        public bool close_while_playing { get; set; }
        public int64 last_media_playing { get; set; }
        public string last_playlist_playing { get; set; }
        public int last_media_position { get; set; }
        public Shuffle shuffle_mode { get; set; }
        public Repeat repeat_mode { get; set; }
        public string search_string { get; set; }
        public string path_string { get; set; }
        public string[] plugins_disabled { get; set;}
        public string[] minimize_while_playing_shells { get; set; }

        private static Main? main_settings = null;

        public static Main get_default () {
            if (main_settings == null)
                main_settings = new Main ();
            return main_settings;
        }

        public bool privacy_mode_enabled () {
            var privacy_settings = new GLib.Settings ("org.gnome.desktop.privacy");
            return privacy_settings.get_boolean ("remember-app-usage") ||
                   privacy_settings.get_boolean ("remember-recent-files");
        }

        private Main ()  {
            base ("org.pantheon.noise.settings");
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
            base ("org.pantheon.noise.equalizer");
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

    public enum Shuffle {
        OFF,
        ALL
    }

    public enum Repeat {
        OFF,
        MEDIA,
        ALBUM,
        ARTIST,
        ALL
    }

    public enum WindowState {
        NORMAL,
        MAXIMIZED,
        FULLSCREEN
    }
}
