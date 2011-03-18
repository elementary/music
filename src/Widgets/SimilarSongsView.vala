using Gtk;
using Gee;

public class BeatBox.SimilarSongsView : TreeView {
	private BeatBox.LibraryManager _lm;
	private BeatBox.LibraryWindow _lw;
	private ListStore model;
	private LinkedList<Song> songs;
	
	private LinkedList<string> urlsToOpen;//queue for opening urls
	
	public SimilarSongsView(BeatBox.LibraryManager lm, BeatBox.LibraryWindow lw) {
		_lm = lm;
		_lw = lw;
		songs = new LinkedList<Song>();
		urlsToOpen = new LinkedList<string>();
		
		/* id is always first and is stored as an int. Then the rest are (1)
		 * strings (for simplicity), and include:
		 * #, track, title, artist, album, genre, comment, year, rating, (9)
		 * bitrate, play count, last played, date added, file name, (5)
		 * bpm, length, file size, (3) */
		model = new ListStore(2, typeof(BeatBox.Song), typeof(string), -1);
		
		TreeViewColumn col = new TreeViewColumn();
		col.title = "song";
		col.visible = false;
		insert_column(col, 0);
		
		insert_column_with_attributes(-1, "Similar Songs", new CellRendererText(), "markup", 1, null);
		get_column(1).sizing = Gtk.TreeViewColumnSizing.FIXED;
		get_column(1).set_alignment((float)0.5);
		
		set_model(model);
		//set_grid_lines(TreeViewGridLines.HORIZONTAL);
		
		row_activated.connect(viewDoubleClick);
	}
	
	public void populateView(Collection<Song> nSongs) {
		songs.clear();
		model.clear();
		
		int count = 0;
		foreach(Song s in nSongs) {
			songs.add(s);
			
			TreeIter iter;
			model.append(out iter);
			
			var title_fixed = s.title.replace("&", "&amp;");
			var artist_fixed = s.artist.replace("&", "&amp;");
			
			model.set(iter, 0, s, 1, "<b>" + title_fixed + "</b>" + " \n" + artist_fixed );
			++count;
			
			if(count >= 16)
				return;
		}
	}
	
	public virtual void viewDoubleClick(TreePath path, TreeViewColumn column) {
		TreeIter item;
		
		// get db's rowid of row clicked
		model.get_iter(out item, path);
		Song s;
		model.get(item, 0, out s);
		
		if(s != null && s.lastfm_url != null && s.lastfm_url != "")
			urlsToOpen.offer(s.lastfm_url);
		
		try {
			Thread.create<void*>(openurl_thread_function, false);
		}
		catch(GLib.ThreadError err) {
			stdout.printf("ERROR: Could not create thread to open %s: %s \n", s.lastfm_url, err.message);
		}
	}
	
	public void* openurl_thread_function () {	
		if(urlsToOpen.peek() != null) {
			try {
				GLib.AppInfo.launch_default_for_uri (urlsToOpen.poll(), null);
			}
			catch(GLib.Error err) {
				stdout.printf("Could not open url in Last FM: %s\n", err.message);
			}
		}
		
		return null;
	}
}
