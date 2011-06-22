using Gtk;
using Gee;

public class Store.ReleaseRotator : HBox {
	Store.StoreView parent;
	LinkedList<Store.Release> releases;
	int index;
	bool cancelOld;
	
	private Image albumArt;
	private Gtk.Label albumName;
	private Gtk.Label albumArtist;
	private Gtk.Label releaseDate;
	
	public ReleaseRotator(Store.StoreView view) {
		parent = view;
		releases = new LinkedList<Store.Release>();
		index = 0;
		cancelOld = false;
		
		buildUI();
		switchReleases();
	}
	
	public void setReleases(LinkedList<Store.Release> rels) {
		this.releases = rels;
		cancelOld = true;
		switchReleases();
	}
	
	public void buildUI() {
		VBox topInfo = new VBox(false, 0);
		albumArt = new Image();
		albumName = new Gtk.Label("");
		albumArtist = new Gtk.Label("");
		releaseDate = new Gtk.Label("");
		
		albumName.xalign = 0.0f;
		albumArtist.xalign = 0.0f;
		releaseDate.xalign = 0.0f;
		
		albumName.ellipsize = Pango.EllipsizeMode.END;
		albumArtist.ellipsize = Pango.EllipsizeMode.END;
		releaseDate.ellipsize = Pango.EllipsizeMode.END;
		
		topInfo.pack_start(wrap_alignment(albumName, 0, 0, 10, 0), false, true, 0);
		topInfo.pack_start(wrap_alignment(albumArtist, 0, 0, 10, 0), false, true, 0);
		topInfo.pack_start(wrap_alignment(releaseDate, 0, 0, 10, 0), false, true, 0);
		
		pack_start(wrap_alignment(albumArt, 0, 10, 0, 0), false, true, 0);
		pack_start(topInfo, true, true, 0);
		
		show_all();
	}
	
	public static Gtk.Alignment wrap_alignment (Gtk.Widget widget, int top, int right, int bottom, int left) {
		var alignment = new Gtk.Alignment(0.0f, 0.0f, 1.0f, 1.0f);
		alignment.top_padding = top;
		alignment.right_padding = right;
		alignment.bottom_padding = bottom;
		alignment.left_padding = left;
		
		alignment.add(widget);
		return alignment;
	}
	
	public bool switchReleases() {
		if(releases.size == 0) {
			Timeout.add(5000, switchReleases);
			return false;
		}
		if(cancelOld) {
			cancelOld = false;
			return false;
		}
		
		if(index + 1 >= releases.size)
			index = 0;
		else
			++index;
		
		Release release = releases.get(index);
		albumName.set_markup("<span weight=\"bold\" font=\"40\">" + release.title.replace("&", "&amp;") + "</span>");
		albumArtist.set_markup("<span font=\"24\">" + release.artist.name.replace("&", "&amp;") + "</span>");
		releaseDate.set_markup("<span font=\"14\">Released " + release.releaseDate.substring(0, 10).replace("-", "/") + "</span>");
		
		if(release.image == null)
			release.image = Store.store.getPixbuf(release.imagePath, 200, 200);
		
		if(release.image != null) {
			albumArt.set_from_pixbuf(release.image);
		}
		
		Timeout.add(5000, switchReleases);
		
		return false;
	}
}
