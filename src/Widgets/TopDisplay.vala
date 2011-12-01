/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

namespace ElementaryWidgets {
	using Gtk;
	
	public class TopDisplay : HBox {
		BeatBox.LibraryManager lm;
		Label label;
		HBox scaleBox;
		Label leftTime;
		Label rightTime;
		HScale scale;
		ProgressBar progressbar;
		Button cancelButton;
		
		public signal void scale_value_changed(ScrollType scroll, double val);
		
		public TopDisplay(BeatBox.LibraryManager lmm) {
			this.lm = lmm;
			
			label = new Label("");
			scale = new HScale.with_range(0, 1, 1);
			leftTime = new Label("0:00");
			rightTime = new Label("0:00");
			progressbar = new ProgressBar();
			cancelButton = new Button();
			
			scaleBox = new HBox(false, 0);
			scaleBox.pack_start(leftTime, false, false, 0);
			scaleBox.pack_start(scale, true, true, 0);
			scaleBox.pack_start(rightTime, false, false, 0);
			
			scale.set_draw_value(false);
			
			label.set_justify(Justification.CENTER);
			label.set_single_line_mode(true);
			label.ellipsize = Pango.EllipsizeMode.END;
			//label.set_markup("<b></b>");
			
			cancelButton.set_image(new Image.from_stock(Gtk.Stock.CANCEL, IconSize.MENU));
			
			cancelButton.set_relief(Gtk.ReliefStyle.NONE);
			
			// all but cancel
			VBox info = new VBox(false, 0);
			info.pack_start(label, false, true, 0);
			info.pack_start(wrap_alignment(progressbar, 0, 5, 0, 5), false, true, 0);
			info.pack_start(wrap_alignment(scaleBox, 0, 5, 0, 5), false, true, 0);
			
			this.pack_start(info, true, true, 0);
			this.pack_end(wrap_alignment(cancelButton, 2, 2, 0, 2), false, false, 0);
			
			this.cancelButton.clicked.connect(cancel_clicked);
			this.scale.button_press_event.connect(scale_button_press);
			this.scale.value_changed.connect(value_changed);
			this.scale.change_value.connect(change_value);
			this.lm.player.current_position_update.connect(player_position_update);
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
		
		/** label functions **/
		public void set_label_text(string text) {
			label.set_text(text);
		}
		
		public void set_label_markup(string markup) {
			label.set_markup(markup);
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
		public void set_scale_sensitivity(bool val) {
			scale.set_sensitive(val);
			scale.set_visible(val);
			leftTime.set_visible(val);
			rightTime.set_visible(val);
		}
		
		// automatically shows/hides progress bar/scale based on progress's value
		public void set_progress_value(double progress) {
			if(progress >= 0.0 && progress <= 1.0) {
				if(!progressbar.visible)
					show_progressbar();
				progressbar.set_fraction(progress);
			}
			else {
				if(!scale.visible)
					show_scale();
			}
		}
		
		/** scale functions **/
		public void set_scale_range(double min, double max) {
			scale.set_range(min, max);
		}
		
		public void set_scale_value(double val) {
			scale.set_value(val);
		}
		
		public double get_scale_value() {
			return scale.get_value();
		}
		
		public virtual bool scale_button_press(Gdk.EventButton event) {
			if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 1) {
				//seek to right position
				//calculate percentage to go to based on location
				Gtk.Allocation extents;
				int point_x = 0;
				int point_y = 0;
				
				scale.get_pointer(out point_x, out point_y);
				scale.get_allocation(out extents);
				
				// get seconds of song
				double songtime = (double)((double)point_x/(double)extents.width) * scale.get_adjustment().upper;
				
				change_value(ScrollType.NONE, songtime);
			}
			
			return false;
		}
		
		public virtual bool scale_button_release(Gdk.EventButton event) {
			
			return false;
		}
		
		public virtual void value_changed() {
			if(!scale.visible)
				return;
			
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
			this.lm.player.current_position_update.disconnect(player_position_update);
			scale.set_value(val);
			scale_value_changed(scroll, val);
			this.lm.player.current_position_update.connect(player_position_update);
			lm.player.setPosition((int64)(val * 1000000000));
			
			return false;
		}
		
		/** other functions **/
		public void show_scale() {
			scaleBox.show();
			progressbar.hide();
			cancelButton.hide();
			
			cancelButton.set_size_request(0,0);
			progressbar.set_size_request(-1, 0);
		}
		
		public void show_progressbar() {
			progressbar.show();
			scaleBox.hide();
			cancelButton.show();
			
			cancelButton.set_size_request(12, 12);
			progressbar.set_size_request(-1, 12);
		}
		
		public virtual void player_position_update(int64 position) {
			double sec = 0.0;
			if(lm.song_info.song != null) {
				sec = ((double)position/1000000000);
				set_scale_value(sec);
			}
		}
		
		public void cancel_clicked() {
			lm.cancel_operations();
		}
	}
}
