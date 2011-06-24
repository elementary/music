using Gtk;
using Gdk;

public class Store.TagLabel : EventBox {
	
	private Gtk.Label _label; // actual label. wrapped around eventbox for click catching
	public string label {
		get { return _label.label; }
		set { _label.label = value; }
	}
	public GLib.Object obj;
	public bool hover_change;
	
	public Color foreground; // text color and hover color
	public Color background; // default background color
	public Color secondary; // new text color on hover
	
	public TagLabel (string label, Color foreground, Color background, Color secondary, GLib.Object obj, bool hover_change) {
		
		this._label = new Gtk.Label (label);
		this.foreground = foreground;
		this.background = background;
		this.secondary = secondary;
		this.obj = obj;
		this.hover_change = hover_change;
		
		// EventBox properties
		set_visible_window (false);
		events |= Gdk.EventMask.POINTER_MOTION_MASK
		       |  Gdk.EventMask.LEAVE_NOTIFY_MASK;
			   
		_label.modify_fg (StateType.NORMAL, (hover_change) ? foreground : secondary);
		_label.modify_fg (StateType.PRELIGHT, secondary);
		
		add (wrap_alignment (_label, 5, 5, 5, 5));
		
		// Signals and callbacks
		expose_event.connect (on_expose_event);
		
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
	
	protected override bool motion_notify_event (EventMotion event) {
		set_state (StateType.PRELIGHT);
		return true;
	}
	
	protected override bool leave_notify_event (EventCrossing event) {
		set_state (StateType.NORMAL);
		return true;
	}
	
	private bool on_expose_event (Widget widget, EventExpose event) {
	
		var cr = cairo_create (event.window);
		
		Allocation size;
		widget.get_allocation (out size);
		
		if (get_state () == StateType.PRELIGHT || !hover_change)
			cr.set_source_rgb (foreground.red / (double) uint16.MAX, foreground.green / (double) uint16.MAX, foreground.blue / (double) uint16.MAX);
		else
			cr.set_source_rgb (background.red / (double) uint16.MAX, background.green / (double) uint16.MAX, background.blue / (double) uint16.MAX);
			
		cr.rectangle (size.x, size.y, size.width, size.height);
		cr.fill ();
		
		return false;
	}
	
}
