using Gee;
using Gtk;

public class BeatBox.AlbumListView : Window {
	LibraryManager lm;
	
	Label album_label;
	Label artist_label;
	RatingWidget rating;
	MusicTreeView mtv;
	bool setting_songs;
	
	 private const string WIDGET_STYLESHEET = """
        .AlbumListDialogBase {
			background-color: none;
            background-image: -gtk-gradient (radial, center center, 0,
											 center center, 1,
                                             from (shade (#404040, 1.0)),
                                             to (shade (#232323, 1.0)));
            border-width: 0;
            border-style: none;
            border-radius: 0;
            padding: 0;
        }
        
        .label {
			color: #ffffff;
		}
        
        GtkTreeView {
			color: #ffffff;
			background-color: #3a3a3a;
		}
        
        GtkTreeView row {
			border-width: 0;
            border-style: none;
            border-radius: 0;
            padding: 0;
		}
		
		GtkTreeView row:selected {
			    background-image: -gtk-gradient (linear,
                    left top,
                    left bottom,
                    from (shade (@selected_bg_color, 1.30)),
                    to (shade (@selected_bg_color, 0.98)));
		}
        
        GtkTreeView row:nth-child(even) {
			background-color: #3a3a3a;
        }
        
        GtkTreeView row:nth-child(odd) {
            background-color: #4D4D4D;
        }
        
     """;
	
	public AlbumListView(LibraryManager lm) {
		this.lm = lm;
		
		set_transient_for(lm.lw);
		window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
		//set_keep_above(true);
		set_decorated(false);
		set_has_resize_grip(false);
		set_resizable(false);
		this.destroy_with_parent = true;
		set_title("Album List");
		set_size_request(350, 400);
		
		// apply css styling
		var style_provider = new CssProvider();

        try  {
            style_provider.load_from_data (WIDGET_STYLESHEET, -1);
        } catch (Error e) {
            stderr.printf ("\nAlbumListView: Couldn't load style provider.\n");
        }

        get_style_context().add_class("AlbumListDialogBase");
        get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
        
        // set maximum size
        Gdk.Geometry geom = new Gdk.Geometry();
        geom.max_width = 350;
        geom.max_height = 400;
        set_geometry_hints(null, geom, (Gdk.WindowHints.MAX_SIZE | Gdk.WindowHints.BASE_SIZE));
        		
		// add close button
		var close = new Gtk.Button ();
        close.set_image (new Gtk.Image.from_stock ("gtk-close", Gtk.IconSize.MENU));
		close.hexpand = close.vexpand = false;
		close.halign = Gtk.Align.START;
		close.set_relief(Gtk.ReliefStyle.NONE);
		close.clicked.connect( () =>  { this.hide(); });
		
		// add album artist/album labels
		album_label = new Label("Album");
		artist_label = new Label("Artist");
		album_label.ellipsize = Pango.EllipsizeMode.END;
		artist_label.ellipsize = Pango.EllipsizeMode.END;
		
		// add actual list
		mtv = new MusicTreeView(lm, lm.lw, "Artist", SortType.ASCENDING, ViewWrapper.Hint.ALBUM_LIST, -1);
		mtv.apply_style_to_view(style_provider);
		//mtv.get_style_context().add_class("ListView");
		mtv.vexpand = true;
		
		// add rating
		rating = new RatingWidget(null, true, IconSize.BUTTON);
		
		var all_area = new Box(Orientation.VERTICAL, 0);
		all_area.pack_start(close, false, false, 0);
		all_area.pack_start(album_label, false, true, 0);
		all_area.pack_start(artist_label, false, true, 3);
        all_area.pack_start(mtv, true, true, 6);
        all_area.pack_start(rating, false, true, 12);
        
        add(all_area);
        
        rating.rating_changed.connect(rating_changed);
        this.focus_out_event.connect(focus_out);
	}
	
	public void set_songs_from_media(Media m) {
		setting_songs = true;
		album_label.set_markup("<span size=\"large\" color=\"#ffffff\"><b>" + m.album.replace("&", "&amp;") + "</b></span>");
		artist_label.set_markup("<span color=\"#ffffff\"><b>" + m.album_artist.replace("&", "&amp;") + "</b></span>");
		
		var songs = new LinkedList<int>();
		var albums = new LinkedList<int>();
        lm.do_search("", mtv.get_hint(), "All Genres", m.album_artist, m.album, lm.media_ids(), ref songs, ref albums);
        
        // decide rating. unless all are equal, show 0.
		int overall_rating = -1;
		foreach(int i in songs) {
			if(overall_rating == -1)
				overall_rating = (int)lm.media_from_id(i).rating;
			else if(lm.media_from_id(i).rating != overall_rating) {
				overall_rating = 0;
				break;
			}
		}
		rating.set_rating(overall_rating);
        
		mtv.set_show_next(songs);
		mtv.populate_view();
		setting_songs = false;
	}
	
	void rating_changed(int new_rating) {
		if(setting_songs)
			return;
		
		var updated = new LinkedList<Media>();
		foreach(int i in mtv.get_medias()) {
			lm.media_from_id(i).rating = new_rating;
			updated.add(lm.media_from_id(i));
		}
		
		lm.update_medias(updated, false, true);
	}
	
	bool focus_out(Gdk.EventFocus event) {
		this.hide();
		
		return false;
	}
}
