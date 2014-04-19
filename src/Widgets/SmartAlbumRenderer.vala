#if HAVE_SMART_ALBUM_COLUMN

public class Noise.SmartAlbumRenderer : CellRendererText {

    /* icon property set by the tree column */
    public Gdk.Pixbuf icon { get; set; }
    public Media m;
    public int top; // first row of consecutive songs of album
    public int bottom; // last row of consecutive songs of album
    public int current; // current row of consecutive songs of album

    public SmartAlbumRenderer () {
        //this.icon = new Gdk.Pixbuf();
    }

    public void set_color (Gdk.Color color) {
    	background_gdk = color;
    }

    /* get_size method, always request a 50x50 area */
    public override void get_size (Widget widget, Gdk.Rectangle? cell_area,
                                   out int x_offset, out int y_offset,
                                   out int width, out int height)
    {
        x_offset = 0;
        y_offset = 0;
        width = -1;
        height = -1;
    }

    /* render method */
    public override void render (Cairo.Context ctx, Widget widget,
                                 Gdk.Rectangle background_area,
                                 Gdk.Rectangle cell_area,
                                 CellRendererState flags)
    {
        if (icon != null) {
            var index = current - top;
			Gdk.Pixbuf slice = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, icon.width, background_area.height);
			//slice.fill (0x00000000);
			var remaining_height = (icon.height - (index * background_area.height));
			
			// extra_space is calculated to move the art down to be closer to the text below it. (pixel perfect)
			int extra_space = icon.height;
			int i = 0;
			while(extra_space > 0) {
				extra_space = icon.height - (i * background_area.height);
				++i;
			}
			extra_space /= 2;
			
			if(remaining_height > 0) {
				Gdk.cairo_rectangle (ctx, background_area);
				icon.copy_area (0, (index * background_area.height) + ( (index != 0) ? extra_space : 0), 
								icon.width, (remaining_height < background_area.height) ? remaining_height - extra_space : background_area.height, 
								slice, 0, 0);
				var middle = (background_area.width < icon.width) ? 
								background_area.x : (background_area.x + (background_area.width - icon.width) / 2);
				
				Gdk.cairo_set_source_pixbuf (ctx, slice, middle, background_area.y + ( (index == 0) ? -extra_space : 0));
			}
			else if(-remaining_height < background_area.height) { // first row after image
				markup = String.escape (m.album);
				base.render(ctx, widget, background_area, cell_area, flags);
			}
			else if(-remaining_height < background_area.height * 2) { // second row after image
				markup = "<span size=\"x-small\">" + m.year.to_string() + "</span>";
				base.render(ctx, widget, background_area, cell_area, flags);
			}
			else if(-remaining_height < background_area.height * 3) { // second row after image
				// rating goes here
			}
		}
		else {
			markup = String.escape (m.album);
			base.render(ctx, widget, background_area, cell_area, flags);
		}
		
		ctx.fill();
    }
}

#endif
