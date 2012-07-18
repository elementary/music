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

using Gee;

public class BeatBox.NetworkDeviceViewWrapper : ViewWrapper {
    public NetworkDevice d { get; private set; }
    
    public NetworkDeviceViewWrapper (LibraryWindow lww, TreeViewSetup tvs,NetworkDevice d) {
        base (lww, tvs.get_hint ());
        
        this.d = d;

        // Add list view
        list_view = new ListView (this, tvs);

        // Add alert
        embedded_alert = new Granite.Widgets.EmbeddedAlert ();

        // Refresh view layout
        pack_views ();

        /*if (has_list_view)
            list_view.import_requested.connect (import_request);*/

        embedded_alert.set_alert (_("Device unreachable"), _("%s could not acces to this network device").printf (lw.app.get_name ()), null, true, Gtk.MessageType.WARNING);
    }
}

