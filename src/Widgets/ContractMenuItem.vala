/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
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
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>,
 *              Corentin Noël <corentin@elementary.io>,
 *              Lucas Baudin <xapantu@gmail.com>,
 *              ammonkey <am.monkeyd@gmail.com>,
 *              Victor Martinez <victoreduardm@gmail.com>,
 *              Sergey Davidoff <shnatsel@gmail.com>
 */

public class Noise.ContractMenuItem : Gtk.MenuItem {
    public Granite.Services.Contract contract { get; construct set; }
    public Gee.Collection<Media> medias { get; construct set; }

    public ContractMenuItem (Granite.Services.Contract contract, Gee.Collection<Noise.Media> medias) {
        Object (contract: contract, medias: medias, label: contract.get_display_name ());
    }

    public override void activate () {
        File[] files = {};
        foreach (Media m in medias) {
            files += m.file;
            debug ("Added file to pass to Contractor: %s", m.uri);
        }

        try {
            debug ("Executing contract \"%s\"", contract.get_display_name ());
            contract.execute_with_files (files);
        } catch (Error err) {
            warning ("Error executing contract \"%s\": %s",
                     contract.get_display_name (), err.message);
        }
    }
}
