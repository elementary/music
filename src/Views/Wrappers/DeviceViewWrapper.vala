// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

using Gee;

// TODO: REWRITE TO SUPPORT ANY DEVICE

public class Noise.DeviceViewWrapper : ViewWrapper {
    public Device d { get; private set; }
    
    public DeviceViewWrapper (LibraryWindow lww, TreeViewSetup tvs, Device d) {
        base (lww, tvs.get_hint ());

        list_view = new ListView (this, tvs);
        embedded_alert = new Granite.Widgets.EmbeddedAlert ();
        pack_views ();

        list_view.import_requested.connect (import_request);

        set_device (d);
    }

    protected override void set_no_media_alert () {
        embedded_alert.set_alert (_("Audio CD Invalid"), _("%s could not read the contents of this Audio CD").printf (App.instance.get_name ()), null, true, Gtk.MessageType.ERROR);
    }

    public virtual void set_device (Device device) {
        this.d = device;
        d.sync_finished.connect (sync_finished);

        set_media_async (d.get_medias ());
    }

    void import_request (Gee.LinkedList<Media> to_import) {
        if (!lm.doing_file_operations()) {
            d.transfer_to_library (to_import);
        }
    }
    
    void sync_finished(bool success) {
        if(hint == ViewWrapper.Hint.DEVICE_AUDIO)
            set_media_async (d.get_songs());
#if HAVE_PODCASTS
        else if(hint == ViewWrapper.Hint.DEVICE_PODCAST)
            set_media_async (d.get_podcasts());
#endif
    }


    // FIXME: Only valid for CDROMs
    protected override string get_statusbar_text () {
        if (current_view == ViewType.ALERT || current_view == ViewType.WELCOME || !has_list_view)
            return "";

        uint total_items = 0;
        uint64 total_time = 0;

        foreach (var media in list_view.get_media ()) {
            if (media != null) {
                total_items ++;
                total_time += media.length;
            }
        }

        if (total_items == 0)
            return "";

        string media_description = total_items > 1 ? _("%i tracks") : _("1 track");

        string media_text = media_description.printf ((int)total_items);
        string time_text = TimeUtils.time_string_from_miliseconds (total_time);

        return "%s, %s".printf (media_text, time_text);
    }
}

