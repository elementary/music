/*
 * Copyright (c) 2012 BeatBox Developers
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
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 *              Scott Ringwelski <sgringwe@mtu.edu>
 */

using Gtk;

// FIXME: Improve how we display total time.

public class BeatBox.StatusBar : Granite.Widgets.StatusBar {

    public uint total_items {get; private set; default = 0;}
    public uint total_mbs {get; private set; default = 0;}
    public uint total_secs {get; private set; default = 0;}
    public ViewWrapper.Hint media_type {get; private set;}

    private string STATUS_TEXT_FORMAT = _("%s, %s, %s");

    private bool is_list = false;

    public StatusBar () {
    }

    public void set_files_size (uint total_mbs) {
        this.total_mbs = total_mbs;
        update_label ();
    }

    public void set_total_time (uint total_secs) {
        this.total_secs = total_secs;
        update_label ();
    }

    public void set_total_medias (uint total_medias, ViewWrapper.Hint media_type, bool is_list = true) {
        this.is_list = is_list;
        this.total_items = total_medias;
        this.media_type = media_type;
        update_label ();
    }

    private void update_label () {
        if (total_items == 0) {
            status_label.set_text ("");
            return;
        }

        string time_text = "", media_description = "", medias_text = "", size_text = "";

        if(total_secs < 3600) { // less than 1 hour show in minute units
            time_text = _("%s minutes").printf ((total_secs/60).to_string());
        }
        else if(total_secs < (24 * 3600)) { // less than 1 day show in hour units
            time_text = _("%.1f hours").printf ((float)total_secs / 3600.0);
        }
        else { // units in days
            time_text = _("%.0f days").printf ((float)total_secs / (24.0 * 3600.0));
        }

        if (total_mbs < 1000)
            size_text = _("%i MB").printf (total_mbs);
        else
            size_text = _("%.2f GB").printf ((double)total_mbs/1000.0);

        switch (media_type) {
            case ViewWrapper.Hint.MUSIC:
                if (is_list)
                	media_description = total_items > 1 ? _("songs") : _("song");
                else
                	media_description = total_items > 1 ? _("albums") : _("album");
                break;
            case ViewWrapper.Hint.PODCAST:
                media_description = total_items > 1 ? _("podcasts") : _("podcast");
                break;
            case ViewWrapper.Hint.AUDIOBOOK:
                media_description = total_items > 1 ? _("audiobooks") : _("audiobook");
                break;
            case ViewWrapper.Hint.STATION:
                media_description = total_items > 1 ? _("stations") : _("station");
                break;
            default:
                if (is_list)
                	media_description = total_items > 1 ? _("items") : _("item");
                else
                	media_description = total_items > 1 ? _("albums") : _("album");
                break;
        }

        medias_text = "%i %s".printf ((int)total_items, media_description);

        status_label.set_text (STATUS_TEXT_FORMAT.printf (medias_text, time_text, size_text));
    }
}

