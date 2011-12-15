using Gee;

public class BeatBox.SpaceWidget : Gtk.DrawingArea {
	Pango.Layout layout;
	
	HashMap<int, SpaceWidgetItem> items;
	
	double total_size;
	double BAR_SIDE_RADIUS = 30.0;
	
	public SpaceWidget(double size) {
		items = new HashMap<int, SpaceWidgetItem>();
		total_size = size;
	}
	
	public int add_item(string name, double size, int red, int green, int blue) {
		SpaceWidgetItem item = new SpaceWidgetItem(name, size, red, green, blue);
		items.set(items.size, item);
		
		return items.size;
	}
	
	public void update_item_size(int index, double size) {
		items.get(index).set_size(size);
	}
	
	public void remove_item(int index) {
		items.unset(index);
	}
	
	public override bool draw(Cairo.Context cr) {
		// blue = 0,0,205
		// orange = 255,140,0
		// firebrick red = 178,34,34
		double width = (double)get_allocated_width ();
        double height = (double)get_allocated_height ();
        double y = height - 20;
        double x = BAR_SIDE_RADIUS;
        
        // start with rounded left side
        cr.set_source_rgba(0.5, 0.5, 0.5, 1);
        cr.move_to(BAR_SIDE_RADIUS, height);
        cr.curve_to((BAR_SIDE_RADIUS/3), height, (BAR_SIDE_RADIUS/3), y, BAR_SIDE_RADIUS, y);
        
        // add in all of the sections
        double right_side = BAR_SIDE_RADIUS;
        bool is_first = true;
        foreach(int i in items.keys) {
			SpaceWidgetItem item = items.get(i);
			
			double item_width = (item.size / total_size) * width;
			double new_right = right_side + item_width;
			
			if(!is_first)
				cr.move_to(right_side, y);
			
			cr.set_source_rgba(0.5, 0.5, 0.5, 1);
			cr.line_to(new_right, y);
			cr.line_to(new_right, height);
			cr.line_to(right_side, height);
			cr.close_path();
			cr.stroke_preserve();
			cr.set_source_rgba(item.r, item.g, item.b, 1);
			cr.fill_preserve();
			cr.stroke();
			
			right_side = new_right;
			is_first = false;
		}
        
		// finish off the right side
		cr.set_source_rgba(0.5, 0.5, 0.5, 1);
		cr.move_to(right_side, y);
        cr.line_to(width - BAR_SIDE_RADIUS, y);
        cr.curve_to(width - (BAR_SIDE_RADIUS/3), y, width - (BAR_SIDE_RADIUS/3), height, width - BAR_SIDE_RADIUS, height);
        cr.line_to(right_side, height);
        cr.close_path();
		cr.stroke_preserve();
		cr.set_source_rgba(255, 255, 255, 1); // fill 'free space' with white
		cr.fill_preserve();
		cr.stroke();
		
		// TODO: Add legend at top
		
		
		//NOTE: i'm saving this as a reference
        // And draw the text in the middle of the allocated space
        /*int fontw, fonth;
        this.layout.get_pixel_size (out fontw, out fonth);
        cr.move_to ((width - fontw) / 2,
                    (height - fonth) / 2);
        Pango.cairo_update_layout (cr, this.layout);
        Pango.cairo_show_layout (cr, this.layout);*/
        return true;
    }
    
    /*
     * This method gets called by Gtk+ when the actual size is known
     * and the widget is told how much space could actually be allocated.
     * It is called every time the widget size changes, for example when the
     * user resizes the window.
     */
    public override void size_allocate (Gtk.Allocation allocation) {
        // The base method will save the allocation and move/resize the
        // widget's GDK window if the widget is already realized.
        base.size_allocate (allocation);

        // Move/resize other realized windows if necessary
    }
}

private class BeatBox.SpaceWidgetItem : GLib.Object {
	public string name;
	public double size;
	public int r; public int g; public int b;
	
	public SpaceWidgetItem(string name, double size, int r, int g, int b) {
		this.name = name;
		this.size = size;
		this.r = r;
		this.g = g;
		this.b = b;
	}
	
	public void set_size(double s) {
		size = s;
	}
}
