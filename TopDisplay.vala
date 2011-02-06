namespace ElementaryWidgets {
	using Gtk;
	
	public class TopDisplay : VBox {
		Label label;
		HBox scaleBox;
		Label leftTime;
		Label rightTime;
		HScale scale;
		ProgressBar progressbar;
		
		public signal void scale_value_changed(ScrollType scroll, double val);
		
		public TopDisplay() {
			label = new Label("");
			scale = new HScale.with_range(0, 1, 1);
			leftTime = new Label("0:00");
			rightTime = new Label("0:00");
			progressbar = new ProgressBar();
			
			scaleBox = new HBox(false, 1);
			scaleBox.pack_start(leftTime, false, false, 0);
			scaleBox.pack_start(scale, true, true, 0);
			scaleBox.pack_start(rightTime, false, false, 0);
			
			scale.set_draw_value(false);
			
			label.set_justify(Justification.CENTER);
			label.set_single_line_mode(true);
			//label.set_markup("<b></b>");
			
			this.pack_start(label, false, true, 0);
			this.pack_start(progressbar, false, true, 0);
			this.pack_start(scaleBox, false, true, 0);
			
			this.scale.value_changed.connect(value_changed);
			this.scale.change_value.connect(change_value);
			
			show_all();
		}
		/** label functions **/
		public void set_label_text(string text) {
			label.set_text(text);
		}
		
		public string get_label_text() {
			return label.get_text();
		}
		
		public void set_label_showing(bool val) {
			if(val)
				label.show();
			else
				label.hide();
		}
		
		/** progressbar functions **/
		public void set_progress_value(double progress) {
			progressbar.set_fraction(progress);
		}
		
		/** scale functions **/
		public void set_scale_range(double min, double max) {
			scale.set_range(min, max);
		}
		
		public void set_scale_value(double val) {
			scale.set_value(val);
		}
		
		public virtual void value_changed() {
			//make pretty current time
			int minute = 0;
			int seconds = (int)scale.get_value();
			
			while(seconds >= 60) {
				++minute;
				seconds -= 60;
			}
			
			leftTime.set_text(minute.to_string() + ":" + ((seconds < 10 ) ? "0" + seconds.to_string() : seconds.to_string()));
			
			//make pretty remaining time
			minute = 0;
			seconds = (int)scale.get_adjustment().upper - (int)scale.get_value();
			
			while(seconds >= 60) {
				++minute;
				seconds -= 60;
			}
			
			rightTime.set_text(minute.to_string() + ":" + ((seconds < 10 ) ? "0" + seconds.to_string() : seconds.to_string()));
		}
		
		public virtual bool change_value(ScrollType scroll, double val) {
			scale_value_changed(scroll, scale.get_value());
			scale.set_value(val);
			return true;
		}
		
		/** other functions **/
		public void show_scale() {
			scaleBox.show();
			progressbar.hide();
		}
		
		public void show_progressbar() {
			progressbar.show();
			scaleBox.hide();
		}
		
		
	}
}
