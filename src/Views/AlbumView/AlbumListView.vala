using Gee;
using Gtk;

public class BeatBox.AlbumListView : Granite.Widgets.PopOver {
	LibraryManager lm;
	MusicTreeView mtv;
	
	public AlbumListView(LibraryManager lm) {
		this.lm = lm;
		
		set_transient_for(lm.lw);
		window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
		//set_parent_pop(lm.lw);
		//set_keep_above(true);
		set_title("Album List");
		
		var close = new Gtk.Button ();
        close.set_image (new Gtk.Image.from_stock ("gtk-close", Gtk.IconSize.MENU));
		close.hexpand = close.vexpand = false;
		close.halign = Gtk.Align.START;
		close.set_relief(Gtk.ReliefStyle.NONE);
		close.clicked.connect( () =>  { this.hide(); });
		
		mtv = new MusicTreeView(lm, lm.lw, "Artist", SortType.ASCENDING, ViewWrapper.Hint.ALBUM_LIST, -1);
		mtv.vexpand = true;
		mtv.set_size_request(325, 300);
		
		var all_area = get_content_area () as Gtk.Box;
		all_area.pack_start(close, false, true, 0);
        all_area.pack_start(mtv, true, true, 0);
        
        this.focus_out_event.connect(focus_out);
	}
	
	public void set_songs_from_media(Media m) {
		var songs = new LinkedList<int>();
		var albums = new LinkedList<int>();
        lm.do_search("", mtv.get_hint(), "All Genres", m.album_artist, m.album, lm.media_ids(), ref songs, ref albums);
		mtv.set_show_next(songs);
		mtv.populate_view();
	}
	
	public void focus_list() {
		show();
		present();
		//mtv.grab_focus();
	}
	
	bool focus_out(Gdk.EventFocus event) {
		this.hide();
		
		return false;
	}
}
