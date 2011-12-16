public class BeatBox.DevicePreferences : GLib.Object {
	public string id { get; construct set; }
	
	public bool sync_when_mounted { get; set; }
	public int last_sync_time { get; set; }
	
	public bool sync_music { get; set; default=true; }
	public bool sync_podcasts { get; set; default=false; }
	public bool sync_audiobooks { get; set; default=false; }
	
	public bool sync_all_music { get; set; default=true;}
	public bool sync_all_podcasts { get; set; default=true; }
	public bool sync_all_audiobooks { get; set; default=true; }
	
	public string music_playlist { get; set; }
	public string podcast_playlist { get; set; } // must only contain podcasts. if not, will ignore others
	public string audiobook_playlist { get; set; } // must only contain audiobooks. if not, will ignore others
	
	public DevicePreferences(string id) {
		this.id = id;
	}
}
