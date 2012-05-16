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

public class BeatBox.DeviceViewWrapper : ViewWrapper {
    public Device d { get; private set; }
    
    public DeviceViewWrapper(LibraryWindow lww, TreeViewSetup tvs, Device d) {
        base (lww, tvs, -1);

            // Add list view
            list_view = new ListView (this, tvs);

            // Add alert
            embedded_alert = new Granite.Widgets.EmbeddedAlert();

        // Refresh view layout
        pack_views ();

        // TODO: Add import_requested
        if (has_list_view)
            list_view.import_requested.connect (import_request);

        set_device (d);
    }
    
    public virtual void set_device (Device device) {
        this.d = device;
        d.sync_finished.connect (sync_finished);
    }

    void import_request(LinkedList<Media> to_import) {
        if (!lm.doing_file_operations()) {
            d.transfer_to_library (to_import);
        }
    }
    
    void sync_finished(bool success) {
        if(hint == ViewWrapper.Hint.DEVICE_AUDIO)
            set_media (d.get_songs());
#if HAVE_PODCASTS
        else if(hint == ViewWrapper.Hint.DEVICE_PODCAST)
            set_media (d.get_podcasts());
#endif
    }

    protected override bool check_have_media () {
        debug ("check_have_media");

        bool have_media = media_count > 0;

        if (have_media) {
            select_proper_content_view ();
            return true;
        }

        // show alert if there's no media
        if (has_embedded_alert) {
            if (hint == Hint.CDROM) {
                embedded_alert.set_alert (_("Audio CD Invalid"), _("%s could not read the contents of this Audio CD").printf (lw.app.get_name ()), null, true, Granite.AlertLevel.WARNING);

                // Switch to alert box
                set_active_view (ViewType.ALERT);
            }
        }

        return false;
    }
}

