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

public class Noise.Plugins.UPnPDeviceManager : GLib.Object {
    BeatBox.LibraryManager lm;
    ArrayList<UPnPDevice> devices;
    
    //public signal void device_added(UPnPDevice d);
    //public signal void device_removed(UPnPDevice d);
    private GUPnP.ContextManager _context_manager;
    
    public UPnPDeviceManager(BeatBox.LibraryManager lm) {
        this.lm = lm;
        devices = new ArrayList<UPnPDevice>();
        
            /* create context manager */
            _context_manager = new GUPnP.ContextManager(null, 0);
            _context_manager.context_available.connect (this.on_context_available);
            
        //lm.device_manager.mount_added.connect (mount_added);
        //lm.device_manager.mount_removed.connect (mount_removed);
    }

    private GUPnP.ControlPoint create_control_point (GUPnP.Context context) {
        debug ("create control point for %s", context.host_ip);
    
        var control_point = new GUPnP.ControlPoint (context, "urn:schemas-upnp-org:device:MediaServer:2");
        control_point.device_proxy_available.connect (this.on_device_proxy_available);
        control_point.device_proxy_unavailable.connect (this.on_device_proxy_unavailable);
        control_point.active = true;
    
        return control_point;
    }
    
    private void on_context_available (GUPnP.ContextManager sender, GUPnP.Context context) {
        debug ("context available %s", context.host_ip);
        sender.manage_control_point (create_control_point (context));
    }

    private void on_device_proxy_available (GUPnP.DeviceProxy proxy) {
        debug ("device available '%s': %s", proxy.get_friendly_name (), proxy.get_device_type ());
        if (verify_if_contains (proxy)) {
            warning ("duplicate proxy device object found: %s", proxy.udn);
            return;
        }
    
        var device = create_upnp_device (proxy);
        if (device != null && proxy.udn != null) {
            devices.add (device);
            lm.lw.sideTree.deviceAdded ((BeatBox.NetworkDevice)device);
        } 
        else  {
            debug ("no ContentDirectory service exposed for %s", proxy.get_friendly_name ());
        }
    }
    
    private void on_device_proxy_unavailable (GUPnP.DeviceProxy proxy) {
        debug ("device unavailable '%s': %s", proxy.get_friendly_name (), proxy.get_device_type ());
        if (verify_if_contains (proxy)) {
            warning ("cannot find proxy device: %s", proxy.udn);
            return;
        }
        var device = create_upnp_device (proxy);
        devices.remove (device);
    }
    
    public UPnPDevice create_upnp_device (GUPnP.DeviceProxy proxy) {
        UPnPDevice device = null;
    
        //try to find a content directory service
        foreach (GUPnP.ServiceInfo service in proxy.list_services ()) {
            debug ("service of type %s exposed %s: %s", service.get_type ().name (), service.udn, service.service_type);
            if (service is GUPnP.ServiceProxy && service.service_type.contains (":ContentDirectory:")) {
                debug ("found a ContentDirectory service");
                if (!service.get_control_url ().contains("/GstLaunch/")) {
                    device = new UPnPDevice (proxy, (GUPnP.ServiceProxy) service);
                }
            }
        }
    
        return device;
    }
    
    private bool verify_if_contains (GUPnP.DeviceProxy proxy) {
        foreach (UPnPDevice device in devices) {
            if (device.proxy.udn == proxy.udn)
                return true;
        }
        return false;
    }
}
