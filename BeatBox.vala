using Gtk;
/** Runs the program
 * 
 */
public class BeatBox.Beatbox : GLib.Object {
	private static LibraryWindow _program;
	private static DataBaseManager dbm;
	private static StreamPlayer _player;
	
	private const string STOCK_MUSIC_LIBRARY = "folder-music";
	private const string STOCK_MEDIA_QUEUE = "media-audio";
	private const string STOCK_MEDIA_ALREADY_PLAYED = "emblem-urgent";
	private const string STOCK_PLAYLIST = "playlist";
	private const string STOCK_PLAYLIST_AUTOMATIC = "playlist-automatic";
	private const string STOCK_SONG_STARRED = "starred";
	private const string STOCK_SONG_NOT_STARRED = "not-starred";
	
	const Gtk.StockItem[] stock_items = {
		{ STOCK_MUSIC_LIBRARY, null, 0, 0 },
		{ STOCK_MEDIA_QUEUE, null, 0, 0 },
		{ STOCK_MEDIA_ALREADY_PLAYED, null, 0, 0 },
		{ STOCK_PLAYLIST, N_("_Playlist"), 0, 0 },
		{ STOCK_PLAYLIST_AUTOMATIC, N_("_Smart Playlist"), 0, 0 },
		{ STOCK_SONG_STARRED, null, 0, 0 },
		{ STOCK_SONG_NOT_STARRED, null, 0, 0 }
    };
	
	public static int main(string[] args) {
		Gtk.init(ref args);
		Gdk.threads_init();
		
		add_stock_images();
		
		stdout.printf("Creating streamplayer\n");
		_player = new BeatBox.StreamPlayer(args);
		
		stdout.printf("Creating database manager\n");
		dbm = new DataBaseManager(true, true);
		
		stdout.printf("Loading database\n");
		dbm.load_db();
		
		stdout.printf("Creating User Interface\n");
		_program = new BeatBox.LibraryWindow(dbm, _player);
        
        Gtk.main ();
		
        return 0;
	}
	
	public static void add_stock_images() {
		var iFactory = new Gtk.IconFactory();
		
		//add beatbox's items
		foreach(StockItem stockItem in stock_items) {
			var iconSet = new IconSet();
			var iconSource = new IconSource();
			
			if(stockItem.translation_domain != null) {
				iconSource.set_icon_name(stockItem.translation_domain);
				stockItem.translation_domain = null;
                iconSet.add_source(iconSource);
			}
			iconSource.set_icon_name(stockItem.stock_id);
			iconSet.add_source(iconSource);
			iFactory.add(stockItem.stock_id, iconSet);
		}
		
		Gtk.Stock.add(stock_items);
		iFactory.add_default();
	}
	
	
}
