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

public class Noise.TopDisplay : Box {
	Noise.LibraryManager lm;
	Gtk.Label label;
	Gtk.Box scaleBox;
	Gtk.Label leftTime;
	Gtk.Label rightTime;
	Gtk.Scale scale;
	Gtk.ProgressBar progressbar;
	Gtk.Button cancelButton;

    private bool is_seeking = false;
	
	public signal void scale_value_changed(ScrollType scroll, double val);
	
	public TopDisplay(Noise.LibraryManager lmm) {
		this.lm = lmm;

        this.orientation = Orientation.HORIZONTAL;

		label = new Label("");
		scale = new Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 1, 1);
		leftTime = new Label("0:00");
		rightTime = new Label("0:00");
		progressbar = new ProgressBar();
		cancelButton = new Button();
		
		scaleBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

		leftTime.margin_right = rightTime.margin_left = 3;

		scaleBox.pack_start(leftTime, false, false, 0);
		scaleBox.pack_start(scale, true, true, 0);
		scaleBox.pack_start(rightTime, false, false, 0);
		
		scale.set_draw_value (false);
		
		label.set_justify(Justification.CENTER);
		label.set_single_line_mode(false);
		label.ellipsize = Pango.EllipsizeMode.END;
		
		cancelButton.set_image(Icons.PROCESS_STOP.render_image (IconSize.MENU));
		cancelButton.set_relief(Gtk.ReliefStyle.NONE);
		cancelButton.halign = cancelButton.valign = Gtk.Align.CENTER;

		cancelButton.set_tooltip_text (_("Cancel"));

		// all but cancel
		var info = new Box(Gtk.Orientation.VERTICAL, 0);
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

		App.player.player.current_position_update.connect(player_position_update);
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
        label.set_visible (val);
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
    
	public virtual bool scale_button_press(Gdk.EventButton event) {
        App.player.player.current_position_update.disconnect(player_position_update);
        is_seeking = true;
		change_value (ScrollType.NONE, get_current_time ());
		
		return false;
	}
	
	public virtual bool scale_button_release(Gdk.EventButton event) {
        is_seeking = false;

		change_value (ScrollType.NONE, get_current_time ());
		
		return false;
	}

    public double get_current_time () {
		Gtk.Allocation extents;
		int point_x = 0;
		int point_y = 0;

		scale.get_pointer (out point_x, out point_y);
		scale.get_allocation (out extents);

		// get miliseconds of media
		// calculate percentage to go to based on location
		return (double)point_x / (double)extents.width * scale.get_adjustment().upper;
    }
	
	public virtual void value_changed() {
		if(!scale.visible)
			return;

		double val = scale.get_value ();
        if (val < 0.0)
            val = 0.0;

		//make pretty current time
		uint elapsed_secs = (uint)val;
		leftTime.set_text (TimeUtils.pretty_length_from_ms (elapsed_secs));

        uint media_duration_secs = (uint)App.player.media_info.media.length;

		//make pretty remaining time
		rightTime.set_text (TimeUtils.pretty_length_from_ms (media_duration_secs - elapsed_secs));
	}

	public virtual bool change_value(ScrollType scroll, double val) {
        App.player.player.current_position_update.disconnect(player_position_update);
		scale.set_value(val);
		scale_value_changed(scroll, val);

        if( !is_seeking )
        {
            App.player.player.setPosition((int64)(val / Numeric.MILI_INV * Numeric.NANO_INV));
            App.player.player.current_position_update.connect(player_position_update);
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
	
	public virtual void player_position_update(int64 position) {
		if(App.player.media_info.media != null) {
    	    double sec = 0.0;

            // convert nanoseconds ot miliseconds
			sec = (double)position / (double)Numeric.NANO_INV * (double)Numeric.MILI_INV;
			set_scale_value(sec);
		}
	}

	public void cancel_clicked() {
		lm.cancel_operations();
	}

    public void set_media (Media current_media) {
        set_scale_range (0.0, (double)(current_media.length));
    }

	void media_updated (Gee.Collection<int> ids) {
		if (App.player.media_info == null)
			return;

		var current_media = App.player.media_info.media;

		if (current_media == null)
			return;

		// update current media
		foreach (var id in ids) {
			if (id == current_media.rowid)
				set_media (current_media);
		}
	}
}
