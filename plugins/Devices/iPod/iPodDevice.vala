/*-
 * Copyright (c) 2011-2012       Corentin Noël <tintou@mailoo.org>
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

public class Noise.Plugins.iPodDevice : GLib.Object, Noise.Device {
    Noise.DevicePreferences pref;
    GPod.iTunesDB db;
    public Mount mount;
    GLib.Icon icon;
    public bool is_supported = true;
    bool is_new = false;
    iPodLibrary library;

    public iPodDevice (Mount mount) {
        this.mount = mount;
        is_new = mount.get_default_location ().get_parse_name ().has_prefix ("afc://");
        var device_manager = DeviceManager.get_default ();
        pref = device_manager.get_device_preferences (get_unique_identifier ());
        icon = new Icon (is_new ? "phone" : "multimedia-player").gicon;
        if (pref == null) {
            pref = new Noise.DevicePreferences (get_unique_identifier ());
            device_manager.add_device_preferences (pref);
        }
    }

    public Noise.DevicePreferences get_preferences () {
        return pref;
    }

    public bool start_initialization () {
        try {
            db = GPod.iTunesDB.parse (mount.get_default_location ().get_path ());
            if (db.device.get_ipod_info ().ipod_model == GPod.iPodModel.INVALID || db.device.get_ipod_info ().ipod_model == GPod.iPodModel.UNKNOWN) {
                is_supported = false;
            }

            library = new iPodLibrary (db, this);
            libraries_manager.add_library (library);
        } catch (Error err) {
            critical ("Error parsing db at %s: %s\n", get_uri (), err.message);
            return false;
        }

        return true;
    }

    public void finish_initialization () {
        library.finish_initialization_async.begin ();
    }

    public string getEmptyDeviceTitle () {
        return _("Empty device!");
    }

    public string getEmptyDeviceDescription () {
        return _("This device does not contain any music.");
    }

    public string getContentType () {
        if (is_new)
            return "ipod-new";
        else
            return "ipod-old";
    }

    public string getDisplayName () {
        return db.playlist_mpl ().name;
    }

    public void setDisplayName (string name) {
        db.playlist_mpl ().name = name;
        try {
            mount.get_default_location ().set_display_name (name);
        } catch (GLib.Error err) {
            critical ("Could not set iPod Mount Display Name: %s\n", err.message);
        }
        DeviceManager.get_default ().device_name_changed (this);
    }
    
    public string get_fancy_description () {
        
        GPod.iPodGeneration enum_gen = db.device.get_ipod_info ().ipod_generation;
        switch (enum_gen) {
            case GPod.iPodGeneration.FIRST:
                return "iPod 1G";
            case GPod.iPodGeneration.SECOND:
                return "iPod 2G";
            case GPod.iPodGeneration.THIRD:
                return "iPod 3G";
            case GPod.iPodGeneration.FOURTH:
                return "iPod 4G";
            case GPod.iPodGeneration.PHOTO:
                return "iPod photo";
            case GPod.iPodGeneration.VIDEO_1:
                return "iPod video";
            case GPod.iPodGeneration.VIDEO_2:
                return "iPod video 2G";
            case GPod.iPodGeneration.MOBILE:
                return "iPod mobile";
            case GPod.iPodGeneration.MINI_1:
                return "iPod mini";
            case GPod.iPodGeneration.MINI_2:
                return "iPod mini 2G";
            case GPod.iPodGeneration.SHUFFLE_1:
                return "iPod shuffle";
            case GPod.iPodGeneration.SHUFFLE_2:
                return "iPod shuffle 2G";
            case GPod.iPodGeneration.SHUFFLE_3:
                return "iPod shuffle 3G";
            case GPod.iPodGeneration.SHUFFLE_4:
                return "iPod shuffle 4G";
            case GPod.iPodGeneration.NANO_1:
                return "iPod nano";
            case GPod.iPodGeneration.NANO_2:
                return "iPod nano 2G";
            case GPod.iPodGeneration.NANO_3:
                return "iPod nano 3G";
            case GPod.iPodGeneration.NANO_4:
                return "iPod nano 4G";
            case GPod.iPodGeneration.NANO_5:
                return "iPod nano 5G";
            case GPod.iPodGeneration.NANO_6:
                return "iPod nano 6G";
            case GPod.iPodGeneration.CLASSIC_1:
                return "iPod classic";
            case GPod.iPodGeneration.CLASSIC_2:
                return "iPod classic 2G";
            case GPod.iPodGeneration.CLASSIC_3:
                return "iPod classic 3G";
            case GPod.iPodGeneration.TOUCH_1:
                return "iPod touch 1G";
            case GPod.iPodGeneration.TOUCH_2:
                return "iPod touch 2G";
            case GPod.iPodGeneration.TOUCH_3:
                return "iPod touch 3G";
            case GPod.iPodGeneration.TOUCH_4:
                return "iPod touch 4G";
            case GPod.iPodGeneration.IPHONE_1:
                return "iPhone";
            case GPod.iPodGeneration.IPHONE_2:
                return "iPhone 2G";
            case GPod.iPodGeneration.IPHONE_3:
                return "iPhone 3G(S)";
            case GPod.iPodGeneration.IPHONE_4:
                return "iPhone 4(S)";
            case GPod.iPodGeneration.IPAD_1:
                return "iPad";
            default:
                return "";
        }
    }

    public void set_mount (Mount mount) {
        this.mount = mount;
    }

    public Mount? get_mount () {
        return mount;
    }

    public string get_uri () {
        return mount.get_default_location ().get_uri ();
    }

    public void set_icon (GLib.Icon icon) {
        this.icon = icon;
    }

    public GLib.Icon get_icon () {
        return icon;
    }

    public uint64 get_capacity () {
        uint64 rv = 0;
        try {
            var file_info = File.new_for_uri (get_uri ()).query_filesystem_info ("filesystem::*", null);
            rv = file_info.get_attribute_uint64 (GLib.FileAttribute.FILESYSTEM_SIZE);
        } catch (Error err) {
            critical ("Error calculating capacity of iPod: %s\n", err.message);
        }

        return rv;
    }
    
    public string get_fancy_capacity () {
        return GLib.format_size (get_capacity ());
    }
    
    public uint64 get_used_space () {
        return get_capacity () - get_free_space ();
    }
    
    public uint64 get_free_space () {
        uint64 rv = 0;
        try {
            var file_info = File.new_for_uri (get_uri ()).query_filesystem_info ("filesystem::*", null);
            rv = file_info.get_attribute_uint64 (GLib.FileAttribute.FILESYSTEM_FREE);
        } catch (Error err) {
            critical("Error calculating free space on iPod: %s\n", err.message);
        }

        return rv;
    }

    public void unmount () {
        mount.unmount_with_operation.begin (GLib.MountUnmountFlags.NONE, null);
    }

    public void eject () {
        if (mount.can_eject ()) {
            mount.get_volume ().get_drive ().eject_with_operation.begin (GLib.MountUnmountFlags.NONE, null);
        }
    }

    public void synchronize () {
        // TODO: IMPLEMENT THIS !
    }

    public bool only_use_custom_view () {
        return false;
    }

    public Gtk.Widget? get_custom_view () {
        return null;
    }

    public bool read_only () {
        return false;
    }

    public Noise.Library get_library () {
        return library;
    }
}
