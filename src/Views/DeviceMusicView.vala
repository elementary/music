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
 * Authored by: Baptiste Gelez <baptiste@gelez.xyz>
 */

/**
* List the music on a device
*/
public class Noise.DeviceMusicView : View {
    public Device device { get; construct; }
    public TreeViewSetup tvs { get; construct; }
    public Library library { get; construct; }

    private MusicListView list_view { get; set; }

    public DeviceMusicView (TreeViewSetup tvs, Device d, Library library) {
        print ("constructor device music view\n\n");        
        Object (device: d, tvs: tvs, library: library);
    }

    construct {
        print ("construct device music view\n\n");
        title = _("Music");
        id = device.get_unique_identifier () + "/music";
        category = device.get_unique_identifier ();
        icon = new ThemedIcon ("library-music");
        priority = 1;

        list_view = new MusicListView (tvs, library, device.read_only ());
        list_view.import_requested.connect (import_request);

        library.media_added.connect ((media) => {
            list_view.add_media (media);
        });
        library.media_removed.connect ((media) => {
            list_view.remove_media (media);
        });

        library.file_operations_done.connect (sync_finished);
        list_view.set_media (library.get_medias ());
        print ("%d media on device\n\n", library.get_medias ().size);

        add (list_view);
        show_all ();
    }

    public override void update_alert (Granite.Widgets.AlertView alert) {
        alert.icon_name = "dialog-information";
        alert.title = device.getEmptyDeviceTitle ();
        alert.description = device.getEmptyDeviceDescription ();
    }

    private void import_request (Gee.Collection<Media> to_import) {
        if (!library.doing_file_operations ()) {
            libraries_manager.transfer_to_local_library (to_import);
        }
    }

    private void sync_finished () {
        list_view.set_media (library.get_medias ());
    }

    public override bool filter (string search) {
        return true;
    }

    public override Gtk.Menu? get_sidebar_context_menu (Granite.Widgets.SourceList list, Granite.Widgets.SourceList.Item item) {
        var menu = new Gtk.Menu ();
        var import_to_library = new Gtk.MenuItem.with_label (_("Import to Library"));
        import_to_library.activate.connect (() => {
            libraries_manager.transfer_to_local_library (device.get_library ().get_medias ());
        });
        menu.append (import_to_library);

        var eject = new Gtk.MenuItem.with_label (_("Eject"));
        eject.activate.connect (() => {
            device.eject ();
        });
        menu.append (eject);

        if (device.get_library ().support_playlists ()) {
            var add_playlist = new Gtk.MenuItem.with_label (_("New Playlist"));
            add_playlist.activate.connect (() => {
                App.main_window.create_new_playlist (device.get_library ());
            });
            menu.append (add_playlist);
        }

        if (device.get_library ().support_smart_playlists ()) {
            var add_smart_playlist = new Gtk.MenuItem.with_label (_("New Smart Playlist"));
            add_smart_playlist.activate.connect (() => {});
            menu.append (add_smart_playlist);
        }

        if (device.read_only () == false) {
            var sync = new Gtk.MenuItem.with_label (_("Sync"));
            sync.activate.connect (() => {
                device.synchronize ();
            });
            menu.append (sync);
        }

        menu.show_all ();
        return menu;
    }
}
