/*
 * Copyright (c) 2012 Victor Eduardo <victoreduardm@gmail.com>
 *
 * This is a free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; see the file COPYING.  If not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 */

using Gtk;

public class BeatBox.StatusBar : Gtk.EventBox {

	Label status_label;
    Box left_box;
    Box right_box;

	string STATUSBAR_FORMAT = _("%s, %s, %s");

	string medias_text;
	string size_text;
	string time_text;

    public StatusBar () {
		status_label = new Label ("");
		status_label.set_justify (Justification.CENTER);

		var wrapper_box = new Box (Orientation.HORIZONTAL, 3);
        left_box = new Box (Orientation.HORIZONTAL, 3);
        right_box = new Box (Orientation.HORIZONTAL, 3);

   	    wrapper_box.pack_start(left_box, false, false, 2);
		wrapper_box.pack_start(status_label, true, true, 12);
	    wrapper_box.pack_end(right_box, false, false, 2);

		add (wrapper_box);
    }

    public void insert_widget (Gtk.Widget widget, bool? use_left_side = false) {
        if (use_left_side)
            left_box.pack_start (widget, false, false, 3);
        else
            right_box.pack_start (widget, false, false, 3);
    }

    public void set_files_size (uint total_mbs) {
   		if(total_mbs < 1000)
			size_text = ((float)(total_mbs)).to_string() + " " + _("MB");
		else
			size_text = ((float)(total_mbs/1000.0f)).to_string() + " " + _("GB");

		update_label ();
    }

    public void set_total_time (uint total_time) {
		if(total_time < 3600) { // less than 1 hour show in minute units
			time_text = (total_time/60).to_string() + _(" minutes");
		}
		else if(total_time < (24 * 3600)) { // less than 1 day show in hour units
			time_text = (total_time/3600).to_string() + _(" hours");
		}
		else { // units in days
			time_text = (total_time/(24 * 3600)).to_string() + _(" days");
		}
		
		update_label ();
    }

	public void set_total_medias (uint total_medias, ViewWrapper.Hint media_type) {
		string media_d = "";

		switch (media_type) {
			case ViewWrapper.Hint.MUSIC:
				media_d = _("songs");
				break;
			case ViewWrapper.Hint.PODCAST:
				media_d = _("podcasts");
				break;
			case ViewWrapper.Hint.AUDIOBOOK:
				media_d = _("audiobooks");
				break;
			case ViewWrapper.Hint.STATION:
				media_d = _("stations");
				break;
			case ViewWrapper.Hint.SIMILAR:
				media_d = _("songs");
				break;
			default:
				media_d = _("items");
				break;
		}

		medias_text = "%i %s".printf ((int)total_medias, media_d);
		update_label ();
	}

    private void update_label () {
		status_label.set_text (STATUSBAR_FORMAT.printf (medias_text, time_text, size_text));
    }
}
