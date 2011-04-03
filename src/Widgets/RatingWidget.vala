using Gtk;
using Gdk;

public class BeatBox.RatingWidget : EventBox {
	private int rating;
	
	private Pixbuf _canvas;
	private Pixbuf not_starred;
	private Pixbuf starred;
	
	public signal void rating_changed(int new_rating);
	
	public RatingWidget() {
		// make the background white
		Gdk.Color c = Gdk.Color();
		Gdk.Color.parse("#FFFFFF", out c);
		modify_bg(StateType.NORMAL, c);
		
		starred = this.render_icon("starred", IconSize.SMALL_TOOLBAR, null);
		not_starred = this.render_icon("not-starred", IconSize.SMALL_TOOLBAR, null);
		
		width_request  = starred.width * 5;
		height_request = starred.height;
		_canvas = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, width_request, height_request);
		
		set_rating(0);
		updateRating(0);
		
		//motion_notify_event.connect(mouseOver);
		button_press_event.connect(buttonPress);
		expose_event.connect(exposeEvent);
	}
	
	public void set_rating(int new_rating) {
		if(rating == new_rating)
			return;
			
		rating = new_rating;
		updateRating(rating);
		rating_changed(rating);
	}
	
	public int get_rating() {
		return rating;
	}
	
	/* just draw new rating */
	public override bool motion_notify_event(EventMotion event) {
		int new_rating = 0;
		
		int buffer = (this.allocation.width - width_request)/2;
		if(event.x - buffer > 5)
			new_rating = (int)((event.x - buffer + 18) / 18);
		else
			new_rating = 0;
		
		updateRating(new_rating);
		set_rating(new_rating);
		
		return true;
	}
	
	/* draw new rating AND update rating */
	public virtual bool buttonPress(Gdk.EventButton event) {
		int new_rating = 0;
		
		int buffer = (this.allocation.width - width_request)/2;
		if(event.x - buffer > 5)
			new_rating = (int)((event.x - buffer + 18) / 18);
		else
			new_rating = 0;
		
		updateRating(new_rating);
		set_rating(new_rating);
		
		return true;
	}
	
	public void updateRating(int fake_rating) {
			_canvas.fill((uint) 0xffffff00);
			
			/* generate the canvas image */
			for (int i = 0; i < 5; i++) {
				if (i < fake_rating) {
					starred.copy_area(0, 0, starred.width, starred.height, _canvas, i * starred.width, 0);
				}
				else {
					not_starred.copy_area(0, 0, not_starred.width, not_starred.height, _canvas, i * not_starred.width, 0);
				}
			}

			queue_draw();
		}
	
	/** @override on_expose_event to paint our own custom widget **/
	public virtual bool exposeEvent(EventExpose event) {
		event.window.draw_pixbuf(
				style.bg_gc[0], _canvas,
				0, 0, (event.area.width - width_request)/2, 0, width_request, height_request,
				Gdk.RgbDither.NONE, 0, 0
			);
			
		return true;
	}
}
