/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
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

using Gtk;

public class BeatBox.TopDisplay : Box {
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

        this.orientation = Orientation.HORIZONTAL;

		label = new Label("");
		scale = new HScale.with_range(0, 1, 1);
		leftTime = new Label("0:00");
		rightTime = new Label("0:00");
		progressbar = new ProgressBar();
		cancelButton = new Button();
		
		scaleBox = new HBox(false, 0);

		leftTime.margin_right = rightTime.margin_left = 3;

		scaleBox.pack_start(leftTime, false, false, 0);
		scaleBox.pack_start(scale, true, true, 0);
		scaleBox.pack_start(rightTime, false, false, 0);
		
		scale.set_draw_value(false);
		
		label.set_justify(Justification.CENTER);
		label.set_single_line_mode(false);
		label.ellipsize = Pango.EllipsizeMode.END;
		
		cancelButton.set_image(Icons.PROCESS_STOP.render_image (IconSize.MENU));
		cancelButton.set_relief(Gtk.ReliefStyle.NONE);
		cancelButton.halign = cancelButton.valign = Gtk.Align.CENTER;

		cancelButton.set_tooltip_text (_("Cancel"));

		// all but cancel
		VBox info = new VBox(false, 0);
		info.pack_start(label, false, true, 0);
		info.pack_start(progressbar, false, true, 0);
		info.pack_start(scaleBox, false, true, 0);
		
		this.pack_start(info, true, true, 0);
		this.pack_end(cancelButton, false, false, 0);
		
		this.cancelButton.clicked.connect(cancel_clicked);

		this.scale.button_press_event.connect(scale_button_press);
		this.scale.button_release_event.connect(scale_button_release);
		this.scale.value_changed.connect(value_changed);
		this.scale.change_value.connect(change_value);

		this.lm.player.current_position_update.connect(player_position_update);
		this.lm.media_updated.connect(media_updated);
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
			if(!progressbar.visible) {
				show_progressbar();
				set_label_showing(true);
			}
			
			progressbar.set_fraction(progress);
		}
		else {
			if(!scale.visible) {
				show_scale();
			}
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

    private bool is_seeking = false;
    
	public virtual bool scale_button_press(Gdk.EventButton event) {
		//calculate percentage to go to based on location
		Gtk.Allocation extents;
		int point_x = 0;
		int point_y = 0;
		
		scale.get_pointer(out point_x, out point_y);
		scale.get_allocation(out extents);
		
		// get seconds of media
		double mediatime = (double)((double)point_x/(double)extents.width) * scale.get_adjustment().upper;

        this.lm.player.current_position_update.disconnect(player_position_update);
        is_seeking = true;
		change_value(ScrollType.NONE, mediatime);
		
		return false;
	}
	
	public virtual bool scale_button_release(Gdk.EventButton event) {
		Gtk.Allocation extents;
		int point_x = 0;
		int point_y = 0;
		
		scale.get_pointer(out point_x, out point_y);
		scale.get_allocation(out extents);
		
		// get seconds of media
		double mediatime = (double)((double)point_x/(double)extents.width) * scale.get_adjustment().upper;
        

        is_seeking = false;
		change_value(ScrollType.NONE, mediatime);
		
		return false;
	}
	
	public virtual void value_changed() {
		if(!scale.visible)
			return;

		//make pretty current time
		int seconds = (int)scale.get_value();
		leftTime.set_text (TimeUtils.pretty_time_mins (seconds));
		
		//make pretty remaining time
		seconds = (int)lm.media_info.media.length - (int)scale.get_value();
		rightTime.set_text (TimeUtils.pretty_time_mins (seconds));
	}
		
	public virtual bool change_value(ScrollType scroll, double val) {
        this.lm.player.current_position_update.disconnect(player_position_update);
		scale.set_value(val);
		scale_value_changed(scroll, val);

        if( !is_seeking )
        {
            lm.player.setPosition((int64)(val * 1000000000));
            this.lm.player.current_position_update.connect(player_position_update);
        }
		
		return false;
	}
	
	/** other functions **/
	public void show_scale() {
		scaleBox.set_no_show_all (false);
		scaleBox.show_all ();

		progressbar.set_no_show_all (true);
		progressbar.hide ();
				
		cancelButton.set_no_show_all (true);
		cancelButton.hide ();
	}
	
	public void show_progressbar() {
		scaleBox.set_no_show_all (true);
		scaleBox.hide();

		progressbar.set_no_show_all (false);
		progressbar.show_all ();
				
		cancelButton.set_no_show_all (false);
		cancelButton.show_all ();
	}

	public void hide_scale_and_progressbar() {
		scaleBox.set_no_show_all (true);
		scaleBox.hide();

		progressbar.set_no_show_all (true);
		progressbar.hide ();
				
		cancelButton.set_no_show_all (true);
		cancelButton.hide ();
	}
	
	public virtual void player_position_update(int64 position) {double sec = 0.0;
		if(lm.media_info.media != null) {
			sec = ((double)position/1000000000);
			set_scale_value(sec);
		}
	}
	
	public void cancel_clicked() {
		lm.cancel_operations();
	}
	
	void media_updated (Gee.Collection<int> ids) {
		if (lm.media_info == null)
			return;

		var current_media = lm.media_info.media;

		if (current_media == null)
			return;

		// update current media
		foreach (var id in ids) {
			if (id == current_media.rowid)
				set_scale_range (0.0, (double)current_media.length);
		}
	}
}

