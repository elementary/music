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

public class Noise.DeviceViewWrapper : ViewWrapper {
    public Device d { get; private set; }
    
    public DeviceViewWrapper (TreeViewSetup tvs, Device d, Library library) {
        base (tvs.get_hint (), library);

        list_view = new ListView (this, tvs);
        embedded_alert = new Granite.Widgets.EmbeddedAlert ();
        pack_views ();

        list_view.import_requested.connect (import_request);

        set_device (d);
    }

    protected override void set_no_media_alert () {
        embedded_alert.set_alert (d.getEmptyDeviceTitle(), d.getEmptyDeviceDescription(), null, true, Gtk.MessageType.ERROR);
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

