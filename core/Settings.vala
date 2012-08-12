// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers
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
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

namespace Noise.Settings {

    public class SavedState : Granite.Services.Settings {
        private static SavedState? _instance;
        public static SavedState instance {
            get {
                if (_instance == null)
                    _instance = new SavedState ();
                 return _instance;
            }
        }

        public int window_width { get; set; }
        public int window_height { get; set; }
        public int window_state { get; set; }
        public int sidebar_width { get; set; }
        public int more_width { get; set; }
        public bool more_visible { get; set; }
        public int view_mode { get; set; }
        public int column_browser_width { get; set; }
        public int column_browser_height { get; set; }
        public bool column_browser_enabled { get; set; }
        public string[] column_browser_visible_columns { get; set; }
        public int column_browser_position { get; set; }

        public SavedState () {
            base ("org.pantheon.noise.SavedState");
        }
    }

    public class Main : Granite.Services.Settings {
        private static Main? _instance;
        public static Main instance {
            get {
                if (_instance == null)
                    _instance = new Main ();
                 return _instance;
            }
        }

        public string music_mount_name { get; set; }
        public string music_folder { get; set; }
        public bool update_folder_hierarchy { get; set; }
        public bool write_metadata_to_file { get; set; }
        public bool copy_imported_music { get; set; }
        public bool download_new_podcasts { get; set; }
        public int last_media_playing { get; set; }
        public int last_media_position { get; set; }
        public int shuffle_mode { get; set; }
        public int repeat_mode { get; set; }
        public string search_string { get; set; }
        public string[] plugins_enabled { get; set;}
        
        public Main ()  {
            base ("org.pantheon.noise.Settings");
        }
    }

    public class Equalizer : Granite.Services.Settings {
        private static Equalizer? _instance;
        public static Equalizer instance {
            get {
                if (_instance == null)
                    _instance = new Equalizer ();
                 return _instance;
            }
        }

        public bool equalizer_enabled { get; set; }
        public bool auto_switch_preset { get; set; }
        public string selected_preset { get; set; }
        public string[] custom_presets { get; set;}
        
        public Equalizer () {
            base ("org.pantheon.noise.Equalizer");
        }
        
        public Gee.Collection<Noise.EqualizerPreset> getPresets () {

            var presets_data = new Gee.LinkedList<string> ();
            
            if (custom_presets != null) {
                for (int i = 0; i < custom_presets.length; i++) {
                    presets_data.add (custom_presets[i]);
                }
            }
            
            var rv = new Gee.LinkedList<Noise.EqualizerPreset>();
            
            foreach (var preset_str in presets_data) {
                rv.add (new Noise.EqualizerPreset.from_string (preset_str));
            }
            
            return rv;
        }
    }
}
