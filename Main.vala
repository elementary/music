using Thread;
using Gtk;
/** Runs the program
 * 
 */
public class BeatBox.Main : GLib.Object {
	private static LibraryWindow _program;
	private static DataBaseManager dbm;
	private static StreamPlayer _player;
	
	public static int main(string[] args) {
		Gtk.init(ref args);
		Gdk.threads_init();
		
		stdout.printf("Creating streamplayer\n");
		_player = new BeatBox.StreamPlayer(args);
		
		stdout.printf("Creating database manager\n");
		dbm = new DataBaseManager(_player, true, true);
		
		stdout.printf("Loading database\n");
		dbm.load_db();
		
		stdout.printf("Creating User Interface\n");
		_program = new BeatBox.LibraryWindow(dbm, _player);
        
        Gtk.main ();
		
        return 0;
	}
}
