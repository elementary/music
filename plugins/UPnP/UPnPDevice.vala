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
 
using GPod;
using Gee;

public class Noise.Plugins.UPnPDevice : GLib.Object, Noise.NetworkDevice {
    
    public GUPnP.DeviceProxy proxy;
    public GUPnP.ServiceProxy service;
    public int starting_index = 0;
    private bool _active = false; // store if the source is currently active (selected among the rhythmbox sources list)
    private bool _deleted = false;
    private bool _activated = false;
    internal const int SEARCH_CHUNK_SIZE = 500;
    internal const int ICON_PREFERRED_DEPTH = 24;
    internal const int ICON_PREFERRED_WIDTH = 48;
    internal const int ICON_PREFERRED_HEIGHT = 48;
    private Timer timer = new Timer ();
    LinkedList<Noise.Media> medias;
    
    private GLib.List<GUPnP.DIDLLiteItem> _cache = new GLib.List<GUPnP.DIDLLiteItem>();
    
    public string id { get; set;}

    public bool is_loading { get; set; }
    
    public UPnPDevice(GUPnP.DeviceProxy proxy, GUPnP.ServiceProxy service) {
        this.proxy = proxy;
        this.service = service;
        this.id = proxy.udn;
        medias = new LinkedList<Noise.Media> ();
        start_music_search ();
    }
    
    public bool start_initialization() {
        return false;
    }
    
    public void finish_initialization() {
        
        //initialized(this);
    }
    
    public void set_icon(Gdk.Pixbuf icon) {
        
    }
    
    public string get_path() {
        return proxy.udn;
    }
    
    public Gdk.Pixbuf get_icon() {
        return get_device_icon (proxy);
    }
    
    public string getContentType() {
        return "network";
    }
    
    public string getDisplayName() {
        return proxy.get_friendly_name ();
    }
    
    public void setDisplayName(string name) {
        
    }
    
    public string get_fancy_description() {
        return "No Description";
    }
    
    public void unmount() {
        
    }
    
    public void get_device_type() {
        
    }
    
    public bool supports_podcasts() {
        return false;
    }
    
    public bool supports_audiobooks() {
        return false;
    }
    
    public Collection<Noise.Media> get_medias() {
        
        return medias;
    }
    
    public Collection<Noise.Media> get_songs() {
        //start_music_search ();
        return medias;
    }
    
    public Collection<int> get_podcasts() {
        return new LinkedList<int>();
    }
    
    public Collection<int> get_audiobooks() {
        return new LinkedList<int>();
    }
    
    public Collection<int> get_playlists() {
        return new LinkedList<int>();
    }
    
    public Collection<int> get_smart_playlists() {
        return new LinkedList<int>();
    }
    
    private void start_music_search () {
        timer = new Timer ();
        timer.start ();
        debug ("start music search for %s", id);
        _cache = new GLib.List<GUPnP.DIDLLiteItem>();
        start_predefined_search (service, complete_music_search);
    }
    
    internal static void start_predefined_search (GUPnP.ServiceProxy service_proxy, GUPnP.ServiceProxyActionCallback callback) {
        service_proxy.begin_action (
            "Search", callback,
            "ContainerID", typeof(string), "0",
            "SearchCriteria", typeof(string), "upnp:class derivedFrom \"object.item.audioItem\"",
            "Filter", typeof(string), "dc:title,dc:creator,upnp:artist,dc:date,upnp:album,upnp:originalTrackNumber,upnp:genre,res@duration",
            "StartingIndex", typeof(int), starting_index,
            "RequestedCount", typeof(int), SEARCH_CHUNK_SIZE,
            "SortCriteria", typeof(string), "");

    }
    
    private void complete_music_search (GUPnP.ServiceProxy proxy, GUPnP.ServiceProxyAction action) {
        debug ("music search complete for %s", proxy.get_id ());
        string result;
        string result_number;
        string result_total_matches;
        string update_id = null;
        int number = 0;
        int total_matches = 0;
    
         try {
            if (!proxy.end_action (action, 
                "Result", typeof(string), out result,
                "NumberReturned", typeof(string), out result_number,
                "TotalMatches", typeof(string), out result_total_matches,
                "UpdateID", typeof(string), out update_id)) {
                    critical ("end_action on proxy %s failed", proxy.get_id ());
                is_loading = false;
                warning ("proxy.end_action failed");
                return;
            }
        } catch (Error err) {
            debug ("error %s %d", err.message, err.code);
        }
    
        if (result_number != null && result_number != "")
            number = int.parse (result_number);
        
        if (result_total_matches != null && result_total_matches != "")
            total_matches = int.parse (result_total_matches);
    
        debug ("items returned: %d current count: %d total items: %d", number, number + starting_index, total_matches);

        if (_deleted)  { // if the source was delete stop scanning the media library
            is_loading = false;
            timer = null;
            return;
        }
        
        if (number > 0) {
            // parsing the result
            GUPnP.DIDLLiteParser parser = new GUPnP.DIDLLiteParser ();
            parser.item_available.connect (this.on_item_available);
            try {
                parser.parse_didl (result);
            } catch (Error err) {
                warning ("error parsing didl results: %s", err.message);
            }
            parser.item_available.disconnect (this.on_item_available);
        }

        if (_cache.length() > 0) {
            foreach (GUPnP.DIDLLiteItem item in _cache) {
                add_entry (item);
            }
        }
        _cache = null;
    
        if ((starting_index + number) >= total_matches) {
            timer.stop ();
            debug ("time elapsed to download the song database: %g", timer.elapsed ());
            timer = null;
            is_loading = false;
            //this.notify_status_changed ();
        } else {
            starting_index += number;
            start_music_search (); // continue searching
        }
    }
    
    private void on_item_available (GUPnP.DIDLLiteParser parser, GUPnP.DIDLLiteItem item) {
        debug ("ITEM available %s: %s", item.id, item.title);
        _cache.append (item);
    }
    
    internal static Gdk.Pixbuf? get_device_icon (GUPnP.DeviceProxy device) {
        int preferred_depth = ICON_PREFERRED_DEPTH;
        int preferred_width = ICON_PREFERRED_WIDTH;
        int preferred_height = ICON_PREFERRED_HEIGHT;
        Gdk.Pixbuf pixbuf = null;
        string mime_type;
        int width, height;

        //get the device icon
        try {
            var icon_url = device.get_icon_url (null,
                 preferred_depth,
                 preferred_width,
                 preferred_height,
                 true,
                 out mime_type,
                 null,
                 out width,
                 out height);
                 
            if (icon_url != null) {
                debug ("device icon url: %s", icon_url);
                var message = new Soup.Message ("GET", icon_url);
                var session = new Soup.SessionAsync ();
                session.send_message (message);
                if (message.status_code == 200) {
                    // get icon from message
                    var loader = new Gdk.PixbufLoader.with_mime_type (mime_type);
                    if (loader != null) {
                        try {
                            loader.write (message.response_body.data);
                            pixbuf = loader.get_pixbuf ();
                            if (pixbuf != null) {
                                float aspect_ratio = (float) width / (float) height;
                                int final_height = (int) (preferred_width / aspect_ratio);
                                pixbuf = pixbuf.scale_simple (preferred_height, final_height, Gdk.InterpType.HYPER);
                            }
                            loader.close ();
                        }
                        catch (Error err) {
                            warning ("error while loading the pixbuf: %s", err.message);
                        }
                    }
                    else {
                        warning ("error creating pixbuf loader for mime type %s", mime_type);
                    }
                }
                else {
                    warning ("error sending icon message: %u", message.status_code);
                }
            }
            else {
                debug ("no device icon found");
            }
        }
        catch (Error err) {
            warning ("error getting device icon: %s", err.message);
        }
        return pixbuf;
    }
    
    private void add_entry (GUPnP.DIDLLiteItem item) {
        var res = get_best_resource (item);
        if (res != null) {
            warning (item.title ?? "");
            Noise.Media media = new Noise.Media (res.uri);
            media.title =  item.title ?? "";
            media.album =  item.album ?? "";
            media.artist =  item.title ?? (item.creator ?? "");
            media.genre =  item.genre ?? "";
            if (item.track_number < 4294967295) // 2^32 no value
                media.track = (uint)item.track_number;
            if (res.duration < 4294967295) // 2^32 no value
                media.length = (uint)res.duration;
            medias.add (media);
        }
    }
    
    internal static GUPnP.DIDLLiteResource? get_best_resource (GUPnP.DIDLLiteItem item)
    {
        string[] mime_types = new string[] { "audio/ogg", "audio/mpeg", "audio/x-wav", "audio/" }; // in order of preference

        foreach (string mime_type in mime_types) {
            foreach (GUPnP.DIDLLiteResource res in item.get_resources ()) {
                debug ("mime_type="+res.protocol_info.mime_type);
                if (res.protocol_info.mime_type.has_prefix (mime_type)) {
                    return res;
                }
            }
        }

        return null;
    }
}
