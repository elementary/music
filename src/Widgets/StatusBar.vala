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

public class BeatBox.StatusBar : Gtk.Toolbar {

    public uint total_items {get; private set; default = 0;}
    public uint total_mbs {get; private set; default = 0;}
    public uint total_secs {get; private set; default = 0;}
    public ViewWrapper.Hint media_type {get; private set;}

    private Label status_label;
    private Box left_box;
    private Box right_box;

    private CssProvider style_provider;
    private StyleContext context;

    private string STATUS_TEXT_FORMAT = _("%s, %s, %s");

    private const string STATUSBAR_STYLESHEET = """
        BeatBoxStatusBar {
            border-bottom-width: 0;
            border-right-width: 0;
            border-left-width: 0;

            -GtkWidget-window-dragging: false;
        }

        /* This prevents the huge vertical padding */
        BeatBoxStatusBar .button {
            padding: 0px;
        }
    """;

    public StatusBar () {

        style_provider = new CssProvider ();

        try {
            style_provider.load_from_data (STATUSBAR_STYLESHEET, -1);
        }
        catch (Error err) {
            warning (err.message);
        }

        /* Get rid of the "toolbar" class to avoid inheriting its style,
           since we want the widget to look more like a normal statusbar. */
        get_style_context ().remove_class (STYLE_CLASS_TOOLBAR);

        context = new StyleContext ();
        context.add_provider_for_screen (get_screen (), style_provider, STYLE_PROVIDER_PRIORITY_THEME);

        status_label = new Label ("");
        status_label.set_justify (Justification.CENTER);

        left_box = new Box (Orientation.HORIZONTAL, 0);
        right_box = new Box (Orientation.HORIZONTAL, 0);

        var left_item = new ToolItem ();
        var status_label_item = new ToolItem ();
        var right_item = new ToolItem ();

        left_item.add (left_box);
        status_label_item.add (status_label);
        right_item.add (right_box);

        status_label_item.set_expand (true);

        this.insert (left_item, 0);
        this.insert (status_label_item, 1);
        this.insert (right_item, 2);
    }

    public void insert_widget (Gtk.Widget widget, bool? use_left_side = false) {
        if (use_left_side)
            left_box.pack_start (widget, false, false, 3);
        else
            right_box.pack_start (widget, false, false, 3);
    }

    public void set_files_size (uint total_mbs) {
        this.total_mbs = total_mbs;
        update_label ();
    }

    public void set_total_time (uint total_secs) {
        this.total_secs = total_secs;
        update_label ();
    }

    public void set_total_medias (uint total_medias, ViewWrapper.Hint media_type) {
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
            time_text = _("%s hours").printf ((total_secs/3600).to_string());
        }
        else { // units in days
            time_text = _("%.1f days").printf ((float) (total_secs/(24 * 3600)));
        }

        if (total_mbs < 1000)
            size_text = _("%i MB").printf (total_mbs);
        else
            size_text = _("%.2f GB").printf ((double)total_mbs/1000.0);

        switch (media_type) {
            case ViewWrapper.Hint.MUSIC:
                media_description = total_items > 1 ? _("songs") : _("song");
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
                media_description = total_items > 1 ? _("items") : _("item");
                break;
        }

        medias_text = "%i %s".printf ((int)total_items, media_description);

        status_label.set_text (STATUS_TEXT_FORMAT.printf (medias_text, time_text, size_text));
    }
}

