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

public class BeatBox.StatusBar : Gtk.Statusbar {

    public string medias_text {get; private set;}
    public string size_text {get; private set;}
    public string time_text {get; private set;}

    bool no_media = false;

    Label status_label;
    Box left_box;
    Box right_box;

    string STATUSBAR_FORMAT = _("%s, %s, %s");

    public StatusBar () {
        // Get rid of the default statusbar items
        foreach (Gtk.Widget widget in get_children ()) {
            widget.set_no_show_all (true);
            widget.set_visible (false);
        }

        status_label = new Label ("");
        status_label.set_justify (Justification.CENTER);

        left_box = new Box (Orientation.HORIZONTAL, 3);
        right_box = new Box (Orientation.HORIZONTAL, 3);

        this.pack_start(left_box, false, false, 2);
        this.pack_start(status_label, true, true, 12);
        this.pack_end(right_box, false, false, 2);
    }

    public void insert_widget (Gtk.Widget widget, bool? use_left_side = false) {
        if (use_left_side)
            left_box.pack_start (widget, false, false, 3);
        else
            right_box.pack_start (widget, false, false, 3);
    }

    public void set_files_size (uint total_mbs) {
        if(total_mbs < 1000)
            size_text = _("%i MB").printf (total_mbs);
        else
            size_text = _("%.2f GB").printf ((float)(total_mbs/1000.0f));

        update_label ();
    }

    public void set_total_time (uint total_time) {
        if(total_time < 3600) { // less than 1 hour show in minute units
            time_text = _("%s minutes").printf ((total_time/60).to_string());
        }
        else if(total_time < (24 * 3600)) { // less than 1 day show in hour units
            time_text = _("%s hours").printf ((total_time/3600).to_string());
        }
        else { // units in days
            time_text = _("%s days").printf ((total_time/(24 * 3600)).to_string());
        }

        update_label ();
    }

    public void set_total_medias (uint total_medias, ViewWrapper.Hint media_type) {
        no_media = total_medias == 0;
        string media_d = "";

        switch (media_type) {
            case ViewWrapper.Hint.MUSIC:
                media_d = total_medias > 1 ? _("songs") : _("song");
                break;
            case ViewWrapper.Hint.PODCAST:
                media_d = total_medias > 1 ? _("podcasts") : _("podcast");
                break;
            case ViewWrapper.Hint.AUDIOBOOK:
                media_d = total_medias > 1 ? _("audiobooks") : _("audiobook");
                break;
            case ViewWrapper.Hint.STATION:
                media_d = total_medias > 1 ? _("stations") : _("station");
                break;
            default:
                media_d = total_medias > 1 ? _("items") : _("item");
                break;
        }

        medias_text = "%i %s".printf ((int)total_medias, media_d);
        update_label ();
    }

    private void update_label () {
        if (no_media)
            status_label.set_text ("");
        else
            status_label.set_text (STATUSBAR_FORMAT.printf (medias_text, time_text, size_text));
    }
}
