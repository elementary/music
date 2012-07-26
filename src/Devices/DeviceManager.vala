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

public class Noise.DeviceManager : GLib.Object {
	LibraryManager lm;
	VolumeMonitor vm;
	
	Mutex _pref_lock;
	HashTable<string, DevicePreferences> _device_preferences;
	
	public signal void device_added(Device d);
	public signal void device_removed(Device d);
	
	public signal void mount_added (Mount mount);
	public signal void mount_removed (Mount mount);
	
	public DeviceManager(LibraryManager lm) {
		this.lm = lm;
		vm = VolumeMonitor.get();
		
		_device_preferences = new HashTable<string, Noise.DevicePreferences>(null, null);
		
		// pre-load devices and their preferences
		_pref_lock.lock();
		foreach(Noise.DevicePreferences dp in lm.dbm.load_devices()) {
			_device_preferences.set(dp.id, dp);
		}
		_pref_lock.unlock();
		
		vm.mount_added.connect((mount) => {mount_added (mount);});
		vm.mount_changed.connect(mount_changed);
		vm.mount_pre_unmount.connect(mount_pre_unmount);
		vm.mount_removed.connect((mount) => {mount_removed (mount);});
		vm.volume_added.connect(volume_added);
	}
	
	public void loadPreExistingMounts() {
		
		// this can take time if we have to rev up the cd drive
		try {
			new Thread<void*>.try (null, get_pre_existing_mounts);
		}
		catch(GLib.Error err) {
			warning ("Could not create mount getter thread: %s", err.message);
		}
	}
	
	public void* get_pre_existing_mounts () {
		var mounts = new LinkedList<Mount>();
		var volumes = new LinkedList<Volume>();
		
		foreach(var m in vm.get_mounts()) {
			mounts.add(m);
		}
		
		foreach(var v in vm.get_volumes()) {
			volumes.add(v);
		}
		
		Idle.add( () => {
			
			foreach(var m in mounts) {
				mount_added(m);
			}
			
			foreach(var v in volumes) {
				volume_added(v);
			}
			
			return false;
		});
		
		return null;
	}
	
	void volume_added(Volume volume) {
		if(lm.lw.main_settings.music_mount_name == volume.get_name() && volume.get_mount() == null) {
			message ("mounting %s because it is believed to be the music folder\n", volume.get_name());
			volume.mount(MountMountFlags.NONE, null, null);
		}
	}
	
	public void deviceInitialized(Device d) {
		message ("adding device\n");
		device_added(d);
		lm.lw.update_sensitivities();
	}
	
	public virtual void mount_changed (Mount mount) {
		//message ("mount_changed:%s\n", mount.get_uuid());
	}
	
	public virtual void mount_pre_unmount (Mount mount) {
		//message ("mount_preunmount:%s\n", mount.get_uuid());
	}
	
		
	/** Device Preferences **/
	public GLib.List<DevicePreferences> device_preferences() {
		var rv = new GLib.List<Noise.DevicePreferences>();
		
		_pref_lock.lock();
		foreach(var pref in _device_preferences.get_values()) {
			rv.append(pref);
		}
		_pref_lock.unlock();
		
		return rv;
	}
	
	public DevicePreferences? get_device_preferences(string id) {
		return _device_preferences.get(id);
	}
	
	public void add_device_preferences(DevicePreferences dp) {
		_pref_lock.lock();
		_device_preferences.set(dp.id, dp);
		_pref_lock.unlock();
	}
}
