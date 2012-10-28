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
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

public class Noise.NetworkDeviceViewWrapper : ViewWrapper {
    public NetworkDevice d { get; private set; }
    
    public NetworkDeviceViewWrapper (LibraryWindow lww, TreeViewSetup tvs, NetworkDevice d) {
        base (lww, tvs.get_hint ());
        
        this.d = d;

        list_view = new ListView (this, tvs);
        embedded_alert = new Granite.Widgets.EmbeddedAlert ();
        pack_views ();

        /*if (has_list_view)
            list_view.import_requested.connect (import_request);*/
    }

    protected override void set_no_media_alert () {
        embedded_alert.set_alert (_("Device unreachable"), _("%s could not access to this network device").printf (App.instance.get_name ()), null, true, Gtk.MessageType.WARNING);
    }
}
