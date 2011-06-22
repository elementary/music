using Gtk;
using Gee;

public class Store.HomeView : ScrolledWindow {
	Store.store store;
	Store.StoreView parent;
	
	HBox allItems;
	Store.ObjectList tagList;
	Store.ObjectList artistList;
	Store.TrackList trackList;
	Store.ReleaseRotator releaseRotator;
	Store.IconView topRock;
	
	public HomeView(StoreView storeView, Store.store store) {
		this.parent = storeView;
		this.store = store;
		
		buildUI();
	}
	
	public void buildUI() {
		allItems = new HBox(false, 0);
		VBox leftItems = new VBox(false, 0);
		VBox centerItems = new VBox(false, 0);
		
		tagList = new ObjectList(parent, "Popular Genres");
		artistList = new ObjectList(parent, "Top Artists");
		trackList = new TrackList(parent, "Artist", false);
		releaseRotator = new ReleaseRotator(parent);
		topRock = new IconView(parent);
		
		/* category labels */
		var genresLabel = new Gtk.Label("");
		var artistsLabel = new Gtk.Label("");
		var tracksLabel = new Gtk.Label("");
		var rockLabel = new Gtk.Label("");
		
		genresLabel.xalign = 0.0f;
		artistsLabel.xalign = 0.0f;
		tracksLabel.xalign = 0.0f;
		rockLabel.xalign = 0.0f;
		
		genresLabel.set_markup("<span weight=\"bold\" size=\"larger\">Popular Genres</span>");
		artistsLabel.set_markup("<span weight=\"bold\" size=\"larger\">Top Artists</span>");
		tracksLabel.set_markup("<span weight=\"bold\" size=\"larger\">Top Tracks</span>");
		rockLabel.set_markup("<span weight=\"bold\" size=\"larger\">New Rock Releases</span>");
		
		leftItems.pack_start(wrap_alignment(genresLabel, 20, 0, 0, 20), false, true, 0);
		leftItems.pack_start(wrap_alignment(tagList, 10, 10, 30, 20), false, true, 0);
		leftItems.pack_start(wrap_alignment(artistsLabel, 10, 0, 0, 20), false, true, 0);
		leftItems.pack_start(wrap_alignment(artistList, 10, 10, 10, 20), false, true, 0);
		
		centerItems.pack_start(wrap_alignment(releaseRotator, 0, 0, 40, 0), false, true, 0);
		centerItems.pack_start(wrap_alignment(tracksLabel, 0, 0, 0, 0), false, true, 0);
		centerItems.pack_start(wrap_alignment(trackList, 10, 0, 0, 0), false, true, 0);
		centerItems.pack_start(wrap_alignment(rockLabel, 40, 0, 0, 0), false, true, 0);
		centerItems.pack_start(wrap_alignment(topRock, 10, 0, 0, 0), false, true, 0);
		
		allItems.pack_start(leftItems, false, true, 0);
		allItems.pack_start(wrap_alignment(centerItems, 20, 20, 10, 10), true, true, 0);
		
		releaseRotator.set_size_request(-1, 200);
		tagList.set_size_request(200, 250);
		artistList.set_size_request(200, 450);
		trackList.set_size_request(-1, 300);
		topRock.set_size_request(-1, 200);
		
		add_with_viewport(allItems);
		
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
	
	public void populate() {
		try {
			Thread.create<void*>(getartists_thread_function, false);
			Thread.create<void*>(getreleases_thread_function, false);
			Thread.create<void*>(gettracks_thread_function, false);
			Thread.create<void*>(gettoprock_thread_function, false);
			Thread.create<void*>(getgenres_thread_function, false);
			parent.max = 6;
			parent.index = 0;
			parent.progressNotification();
		}
		catch(GLib.ThreadError err) {
			stdout.printf("ERROR: Could not create thread to get populate ArtistView: %s \n", err.message);
		}
	}
	
	public void* getartists_thread_function () {
		var tops = new LinkedList<Artist>();
		
		foreach(var art in store.topArtists("week", null, null, 1))
			tops.add(art);
		
		++parent.index;
		
		Idle.add( () => { 
			foreach(var art in tops)
				artistList.addItem(art);
				
			++parent.index;
			return false;
		});
		
		return null;
	}
	
	public void* getreleases_thread_function () {
		var tops = new LinkedList<Release>();
		
		foreach(var rel in store.topReleases("week", null, null, 1)) {
			rel.image = Store.store.getPixbuf(rel.imagePath, 200, 200);
			tops.add(rel);
			
			// get off to a start
			if(tops.size == 1)
				releaseRotator.setReleases(tops);
		}
		
		++parent.index;
		
		releaseRotator.setReleases(tops);
		
		return null;
	}
	
	public void* gettracks_thread_function () {
		var tops = new LinkedList<Track>();
		
		foreach(var track in store.topTracks("week", null, 1))
			tops.add(track);
		
		++parent.index;
		
		Idle.add( () => { 
			foreach(var track in tops)
				trackList.addItem(track);
				
			++parent.index;
			return false;
		});
		
		return null;
	}
	
	public void* gettoprock_thread_function () {
		var rock = new LinkedList<Release>();
		
		foreach(var rel in store.topReleases("week", null, "rock", 1)) {
			rel.image = Store.store.getPixbuf(rel.imagePath, 100, 100);
			rock.add(rel);
		}
		
		++parent.index;
		
		Idle.add( () => { 
			foreach(var rel in rock)
				topRock.addItem(rel);
				
			++parent.index;
			return false;
		});
		
		return null;
	}
	
	public void* getgenres_thread_function () {
		var gens = new LinkedList<Tag>();
		
		gens.add( new Tag.with_values("pop", "Pop", "") );
		gens.add( new Tag.with_values("rock", "Rock", "") );
		gens.add( new Tag.with_values("electronic", "Electronic", "") );
		gens.add( new Tag.with_values("jazz", "Jazz", "") );
		gens.add( new Tag.with_values("alternative-indie", "Alternative/Indie", "") );
		gens.add( new Tag.with_values("country", "Country", "") );
		gens.add( new Tag.with_values("grunge", "Grunge", "") );
		gens.add( new Tag.with_values("2000s", "2000's", "") );
		gens.add( new Tag.with_values("reggae", "Reggae", "") );
		gens.add( new Tag.with_values("new-age", "New Age", "") );
		gens.add( new Tag.with_values("instrumental", "Instrumental", "") );
		gens.add( new Tag.with_values("soundtrack", "Soundtrack", "") );
		
		++parent.index;
		
		Idle.add( () => { 
			foreach(var tag in gens)
				tagList.addItem(tag);
				
			++parent.index;
			return false;
		});
		
		return null;
	}
	
}
