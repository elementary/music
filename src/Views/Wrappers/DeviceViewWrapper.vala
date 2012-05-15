/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

using Gee;

public class BeatBox.DeviceViewWrapper : ViewWrapper {
	public Device d;
	
	public DeviceViewWrapper(LibraryWindow lww, TreeViewSetup tvs, Device d) {
		base (lww, tvs, -1);

		// TODO: Add import_requested
		if (has_list_view)
			list_view.import_requested.connect (import_request);

		this.d = d;
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

