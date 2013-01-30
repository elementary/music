namespace LastFM {

    public class Settings : Granite.Services.Settings {

        public string session_key { get; set; }
        
        public Settings () {
            base ("org.pantheon.noise.lastfm");
        }
    }
}