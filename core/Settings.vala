namespace Noise {

    public enum Position {
        AUTOMATIC = 0,
        LEFT      = 2,
        TOP       = 1
	}

    public enum WindowState {
        NORMAL = 0,
        MAXIMIZED = 1,
        FULLSCREEN = 2
    }
    
    public class SavedState : Granite.Services.Settings {

        public bool sidebar_library_item_expanded { get; set; }
        public bool sidebar_playlists_item_expanded { get; set; }
        public int window_width { get; set; }
        public int window_height { get; set; }
        public WindowState window_state { get; set; }
        public int sidebar_width { get; set; }
        public int more_width { get; set; }
        public bool more_visible { get; set; }
        public int view_mode { get; set; }
        public int miller_width { get; set; }
        public int miller_height { get; set; }
        public bool miller_columns_enabled { get; set; }
        public string[] music_miller_visible_columns { get; set; }
        public string[] generic_miller_visible_columns { get; set; }
        public Position miller_columns_position { get; set; }

        public SavedState () {
            base ("org.pantheon.noise.SavedState");
        }
        
    }

    public class Settings : Granite.Services.Settings {

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
        
        public Settings ()  {
            base ("org.pantheon.noise.Settings");
        }
    }

    public class Equalizer : Granite.Services.Settings {

        public bool equalizer_enabled { get; set; }
        public bool auto_switch_preset { get; set; }
        public string selected_preset { get; set; }
        public string[] custom_presets { get; set;}
        
        public Equalizer () {
            base ("org.pantheon.noise.Equalizer");
        }
        
        public Gee.Collection<BeatBox.EqualizerPreset> getPresets () {

            var presets_data = new Gee.LinkedList<string> ();
            
            if (custom_presets != null) {
                for (int i = 0; i < custom_presets.length; i++) {
                    presets_data.add (custom_presets[i]);
                }
            }
            
            var rv = new Gee.LinkedList<BeatBox.EqualizerPreset>();
            
            foreach (var preset_str in presets_data) {
                rv.add (new BeatBox.EqualizerPreset.from_string (preset_str));
            }
            
            return rv;
        }
    }
}