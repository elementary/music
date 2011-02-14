using Gtk;
using Gee;

public class BeatBox.SimilarSongsView : ScrolledWindow {
	private BeatBox.LibraryManager _lm;
	private BeatBox.LibraryWindow _lw;
	private TreeView view;
	private ListStore model;
	private LinkedList<Song> songs;
	
	public SimilarSongsView(BeatBox.LibraryManager lm, BeatBox.LibraryWindow lw) {
		_lm = lm;
		_lw = lw;
		songs = new LinkedList<Song>();
		
		view = new TreeView();
		
		/* id is always first and is stored as an int. Then the rest are (1)
		 * strings (for simplicity), and include:
		 * #, track, title, artist, album, genre, comment, year, rating, (9)
		 * bitrate, play count, last played, date added, file name, (5)
		 * bpm, length, file size, (3) */
		model = new ListStore(2, typeof(BeatBox.Song), typeof(string), -1);
		
		TreeViewColumn col = new TreeViewColumn();
		col.title = "song";
		col.visible = false;
		view.insert_column(col, 0);
		
		view.insert_column_with_attributes(-1, "More", new CellRendererText(), "markup", 1, null);
		//view.get_column(1).set_alignment((float)0.5);
		
		view.set_model(model);
		view.set_grid_lines(TreeViewGridLines.HORIZONTAL);
		
		this.add(view);
		this.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		
		view.row_activated.connect(viewDoubleClick);
	}
	
	public void populateView(Collection<Song> nSongs) {
		songs.clear();
		model.clear();
		
		foreach(Song s in nSongs) {
			songs.add(s);
			
			TreeIter iter;
			model.append(out iter);
			model.set(iter, 0, s, 1, "<b>" + s.title + "</b>" + " by\n" + "<b>" + s.artist + "</b>");
		}
	}
	
	public virtual void viewDoubleClick(TreePath path, TreeViewColumn column) {
		TreeIter item;
		
		// get db's rowid of row clicked
		model.get_iter(out item, path);
		Song s;
		model.get(item, 0, out s);
		
		if(s != null && s.lastfm_url != null && s.lastfm_url != "")
			GLib.AppInfo.launch_default_for_uri (s.lastfm_url, null);
	}
}
