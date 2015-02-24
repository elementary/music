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

public class Noise.Plugins.CDRomDevice : GLib.Object, Noise.Device {
    Mount mount;
    GLib.Icon icon;
    string display_name = "";
    
    CDRipper ripper;
    Noise.Media media_being_ripped;
    int current_list_index;
    
    bool _is_transferring;
    bool user_cancelled;
    
    string current_operation;
    double current_song_progress;
    int index;
    int total;
    
    Gee.LinkedList<Noise.Media> medias;
    Gee.LinkedList<Noise.Media> list;
    CDPlayer cdplayer;
    
    CDView cdview;
    
    public signal void current_importation (int current_list_index);
    public signal void stop_importation ();
    
    public CDRomDevice(Mount mount) {
        this.mount = mount;
        this.icon = new Icon ("media-cdrom-audio").gicon;
        this.display_name = mount.get_name();
        
        list = new Gee.LinkedList<Noise.Media>();
        medias = new Gee.LinkedList<Noise.Media>();
        
        cdview = new CDView (this);
        cdplayer = new CDPlayer (mount);
        Noise.App.player.add_playback (cdplayer);
    }
    
    public Noise.DevicePreferences get_preferences() {
        return new Noise.DevicePreferences(get_unique_identifier());
    }
    
    public bool start_initialization() {
        return true;
    }
    
    public void finish_initialization() {
        NotificationManager.get_default ().progress_canceled.connect(cancel_transfer);
        
        finish_initialization_async.begin ();
    }
    
    async void finish_initialization_async () {
        medias = CDDA.getMediaList (mount.get_default_location ());
        if(medias.size > 0) {
            setDisplayName(medias.get(0).album);
        }

        Idle.add (() => {
            initialized (this);
            return false;
        });
    }
    
    public string getEmptyDeviceTitle() {
        return _("Audio CD Invalid");
    }
    
    public string getEmptyDeviceDescription() {
        return _("Impossible to read the contents of this Audio CD");
    }
    
    public string getContentType() {
        return "cdrom";
    }
    
    public string getDisplayName() {
        if (display_name == "" || display_name == null)
            return mount.get_name ();
        else
            return display_name;
    }
    
    public void setDisplayName(string name) {
        display_name = name;
    }
    
    public string get_fancy_description() {
        return "";
    }
    
    public void set_mount(Mount mount) {
        this.mount = mount;
    }
    
    public Mount? get_mount() {
        return mount;
    }
    
    public string get_uri() {
        return mount.get_default_location().get_uri();
    }
    
    public void set_icon(GLib.Icon icon) {
        this.icon = icon;
    }
    
    public GLib.Icon get_icon() {
        return icon;
    }
    
    public uint64 get_capacity() {
        return 0;
    }
    
    public string get_fancy_capacity() {
        return "";
    }
    
    public uint64 get_used_space() {
        return 0;
    }
    
    public uint64 get_free_space() {
        return 0;
    }

    private bool ejecting = false;
    private bool unmounting = false;

    public void unmount() {
        unmount_async.begin ();
    }

    private async void unmount_async () {
        if (unmounting)
            return;

        unmounting = true;

        try {
            yield mount.unmount_with_operation (MountUnmountFlags.FORCE, null);
        } catch (Error err) {
            warning ("Could not unmmount CD: %s", err.message);
        }

        unmounting = false;
    }

    public void eject() {
        eject_async.begin ();
    }

    private async void eject_async () {
        if (ejecting)
            return;

        ejecting = true;

        try {
            yield mount.eject_with_operation (MountUnmountFlags.FORCE, null);
        } catch (Error err) {
            warning ("Could not eject CD: %s", err.message);
        }

        ejecting = false;
    }
    
    public bool only_use_custom_view () {
        return true;
    }
    
    public Gtk.Widget? get_custom_view() {
        return cdview;
    }
    
    public bool read_only() {
        return true;
    }
    
    public bool supports_podcasts() {
        return false;
    }
    
    public bool supports_audiobooks() {
        return false;
    }
    
    public Noise.Library get_library () {
        return libraries_manager.local_library;
    }
    
    public Gee.Collection<Noise.Media> get_medias() {
        return medias;
    }
    
    public bool sync_medias (Gee.Collection<Noise.Media> list) {
        message ("Burning not supported on CDRom's.\n");
        return false;
    }
    
    public void synchronize () {
        
    }
    
    public bool will_fit(Gee.Collection<Noise.Media> list) {
        return false;
    }
    
    public bool transfer_all_to_library() {
        return transfer_to_library (medias);
    }
    
    public bool transfer_to_library(Gee.Collection<Noise.Media> trans_list) {
        this.list.clear ();
        this.list.add_all (trans_list);
        if(list.size == 0)
            list = medias;
        
        // do checks to make sure we can go on
        if(!GLib.File.new_for_path (Settings.Main.get_default ().music_folder).query_exists ()) {
            NotificationManager.get_default ().show_alert (_("Could not find Music Folder"), _("Please make sure that your music folder is accessible and mounted before importing the CD."));
            return false;
        }
        
        
        if(list.size == 0) {
            infobar_message (_("The Application could not find any songs on the CD. No songs can be imported"), Gtk.MessageType.ERROR);
            return false;
        }
        
        ripper = new CDRipper(mount, medias.size);
        if(!ripper.initialize()) {
            warning ("Could not create CD Ripper\n");
            return false;
        }
        current_importation (1);
        
        current_list_index = 0;
        Noise.Media s = list.get(current_list_index);
        media_being_ripped = s;
        s.showIndicator = true;
        
        // initialize gui feedback
        index = 0;
        total = list.size;
        current_operation = get_track_status (s);

        _is_transferring = true;

        Timeout.add (500, () => {NotificationManager.get_default ().update_progress (current_operation, current_song_progress);return false;});

        user_cancelled = false;

        ripper.progress_notification.connect( (progress) => {
            current_song_progress = progress;
            libraries_manager.progress = progress;
        });
        
        // connect callbacks
        ripper.media_ripped.connect(mediaRipped);
        ripper.error.connect(ripperError);
        
        // start process
        ripper.ripMedia(s.track, s);

        // this spins the spinner for the current media being imported
        Timeout.add (100, () => {
            if (media_being_ripped != s || media_being_ripped == null)
                return false;

            var wrapper = App.main_window.view_container.get_current_view () as DeviceViewWrapper;

            if (wrapper != null) {
                if (wrapper.d == this)
                    wrapper.list_view.queue_draw ();
            }

            return true;
        });

        return false;
    }
    
    public void mediaRipped(Noise.Media s) {
        s.showIndicator = false;
        
        // Create a copy and add it to the library
        Noise.Media lib_copy = s.copy();
        lib_copy.isTemporary = false;
        lib_copy.unique_status_image = null;
        var copied_list = new Gee.ArrayList<Media> ();
        copied_list.add (lib_copy);
        
        // update media in cdrom list to show as completed
        s.unique_status_image = Icons.PROCESS_COMPLETED.gicon;

        if(GLib.File.new_for_uri(lib_copy.uri).query_exists()) {
            try {
                lib_copy.file_size = (int)(GLib.File.new_for_uri(lib_copy.uri).query_info("*", FileQueryInfoFlags.NONE).get_size());
            }
            catch(Error err) {
                lib_copy.file_size = 5; // best guess
                warning("Could not get ripped media's file_size: %s\n", err.message);
            }
        }
        else {
            warning("Just-imported song from CD could not be found at %s\n", lib_copy.uri);
            //s.file_size = 5; // best guess
        }
        
        libraries_manager.transfer_to_local_library (copied_list);
        
        // do it again on next track
        if(current_list_index < (list.size - 1) && !user_cancelled) {
            ++current_list_index;
            Noise.Media next = list.get(current_list_index);
            current_importation (current_list_index+1);
            media_being_ripped = next;
            ripper.ripMedia(next.track, next);
            ++index;
            current_operation = get_track_status (next);
        } else {
            stop_importation ();
            media_being_ripped = null;
            _is_transferring = false;
            
            int n_songs = current_list_index + 1;
            infobar_message (ngettext (_("Importation of a song from Audio CD finished."), _("Importation of %i songs from Audio CD finished.").printf(n_songs), n_songs), Gtk.MessageType.INFO);
        }
    }

    private string get_track_status (Media m) {
        return _("Importing track %i: %s").printf (m.track, m.get_title_markup ());
    }
    
    public void cancel_transfer() {
        user_cancelled = true;
        current_operation = _("CD import will be <b>cancelled</b> after current import.");
    }
    
    public void ripperError(string err, Gst.Message message) {
        stop_importation ();
        if(err == "missing element") {
            if (message.get_structure () != null && Gst.PbUtils.is_missing_plugin_message (message)) {
                    Noise.InstallGstreamerPluginsDialog dialog = new Noise.InstallGstreamerPluginsDialog(message);
                    dialog.show();
                }
        }
        if(err == "error") {
            GLib.Error error;
            string debug;
            message.parse_error (out error, out debug);
            critical ("Error: %s!:%s\n", error.message, debug);
            cancel_transfer();
            media_being_ripped = null;
            _is_transferring = false;
            infobar_message (_("An error occured during the Import of this CD"), Gtk.MessageType.ERROR);
        }
    }
}
