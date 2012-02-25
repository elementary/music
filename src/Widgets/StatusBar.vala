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

public class BeatBox.StatusBar : Gtk.Toolbar {

    public string medias_text {get; private set;}
    public string size_text {get; private set;}
    public string time_text {get; private set;}

    bool no_media = false;

    Label status_label;
    Box left_box;
    Box right_box;

    string STATUSBAR_FORMAT = _("%s, %s, %s");

    private const string BASE_STYLESHEET = """
        BeatBoxStatusBar {
            -GtkToolbar-button-relief: GTK_RELIEF_NONE;
        }
    """;

    private const string STYLESHEET = """
        BeatBoxStatusBar {
            padding: 1px;
            -GtkWidget-window-dragging: false;
        }
    """;

    public StatusBar () {
        var base_style_provider = new CssProvider ();
        var style_provider = new CssProvider ();

        try {
            style_provider.load_from_data (STYLESHEET, -1);
        }
        catch (Error err) {
            warning (err.message);
        }

        try {
            base_style_provider.load_from_data (BASE_STYLESHEET, -1);
        }
        catch (Error err) {
            warning (err.message);
        }

        this.get_style_context ().add_provider (style_provider, STYLE_PROVIDER_PRIORITY_THEME);
        this.get_style_context ().remove_class (STYLE_CLASS_TOOLBAR);

        this.get_style_context ().add_provider (base_style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);

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
