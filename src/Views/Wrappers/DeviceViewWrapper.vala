// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2017 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

public class Noise.DeviceViewWrapper : ViewWrapper {
    public Device d { get; private set; }
    
    public DeviceViewWrapper (TreeViewSetup tvs, Device d, Library library) {
        base (tvs.hint, library);

        list_view = new ListView (this, tvs);
        embedded_alert = new Granite.Widgets.AlertView ("", "", "");
        pack_views ();

        list_view.import_requested.connect (import_request);

        library.media_added.connect (add_media_async);
        library.media_removed.connect (remove_media_async);
        library.media_updated.connect (update_media_async);
        set_device (d);
    }

    protected override void set_no_media_alert () {
        embedded_alert.icon_name = "dialog-error";
        embedded_alert.title = d.getEmptyDeviceTitle ();
        embedded_alert.description = d.getEmptyDeviceDescription ();
    }

    public virtual void set_device (Device device) {
        this.d = device;
        library.file_operations_done.connect (sync_finished);

        set_media_async.begin (library.get_medias ());
    }

    private void import_request (Gee.Collection<Media> to_import) {
        if (!library.doing_file_operations()) {
            libraries_manager.transfer_to_local_library (to_import);
        }
    }

    private void sync_finished () {
        if (hint == ViewWrapper.Hint.DEVICE_AUDIO)
            set_media_async.begin (library.get_medias ());
    }
}

