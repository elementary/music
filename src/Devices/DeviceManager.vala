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

public class BeatBox.DeviceManager : GLib.Object {
	LibraryManager lm;
	VolumeMonitor vm;
	LinkedList<Device> devices;
	
	Mutex _pref_lock;
	HashTable<string, DevicePreferences> _device_preferences;
	
	public signal void device_added(Device d);
	public signal void device_removed(Device d);
	
	public DeviceManager(LibraryManager lm) {
		this.lm = lm;
		vm = VolumeMonitor.get();
		devices = new LinkedList<Device>();
		
		_pref_lock = new Mutex();
		_device_preferences = new HashTable<string, DevicePreferences>(null, null);
		
		// pre-load devices and their preferences
		_pref_lock.lock();
		foreach(DevicePreferences dp in lm.dbm.load_devices()) {
			_device_preferences.set(dp.id, dp);
		}
		_pref_lock.unlock();
		
		vm.mount_added.connect(mount_added);
		vm.mount_changed.connect(mount_changed);
		vm.mount_pre_unmount.connect(mount_pre_unmount);
		vm.mount_removed.connect(mount_removed);
		vm.volume_added.connect(volume_added);
	}
	
	public void loadPreExistingMounts() {
		
		// this can take time if we have to rev up the cd drive
		try {
			Thread.create<void*>(get_pre_existing_mounts, false);
		}
		catch(GLib.ThreadError err) {
			stdout.printf("ERROR: could not create mount getter thread: %s \n", err.message);
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
		if(lm.settings.getMusicMountName() == volume.get_name() && volume.get_mount() == null) {
			stdout.printf("mounting %s because it is believed to be the music folder\n", volume.get_name());
			volume.mount(MountMountFlags.NONE, null, null);
		}
	}
	
	public virtual void mount_added (Mount mount) {
		foreach(var dev in devices) {
			if(dev.get_path() == mount.get_default_location().get_path()) {
				return;
			}
		}
		
		Device added;
		if(mount.get_default_location().get_uri().has_prefix("cdda://")) {
			added = new CDRomDevice(lm, mount);
		}
		else if(File.new_for_path(mount.get_default_location().get_path() + "/iTunes_Control").query_exists() ||
				File.new_for_path(mount.get_default_location().get_path() + "/iPod_Control").query_exists() ||
				File.new_for_path(mount.get_default_location().get_path() + "/iTunes/iTunes_Control").query_exists()) {
			added = new iPodDevice(lm, mount);	
		}
		else if(mount.get_default_location().get_parse_name().has_prefix("afc://")) {
			added = new iPodDevice(lm, mount);
		}
		else if(File.new_for_path(mount.get_default_location().get_path() + "/Android").query_exists()) {
			added = new AndroidDevice(mount);
		}
		else if(lm.settings.getMusicFolder().contains(mount.get_default_location().get_path())) {
			// user mounted music folder, rescan for images
			lm.settings.setMusicMountName(mount.get_volume().get_name());
			try {
				Thread.create<void*>(lm.fetch_all_cover_art, false);
			}
			catch(GLib.ThreadError err) {
				stdout.printf("Could not create thread to load media pixbuf's: %s \n", err.message);
			}
			
			return;
		}
		else { // not a music player, ignore it
			return;
		}
		
		if(added == null) {
			stdout.printf("Found device at %s is invalid. Not using it\n", mount.get_default_location().get_parse_name());
			return;
		}
		
		added.set_mount(mount);
		devices.add(added);
		
		if(added.start_initialization()) {
			added.finish_initialization();
			added.initialized.connect(deviceInitialized);
		}
		else {
			mount_removed(added.get_mount());
		}
	}
	
	void deviceInitialized(Device d) {
		stdout.printf("adding device\n");
		device_added(d);
		lm.lw.update_sensitivities();
	}
	
	public virtual void mount_changed (Mount mount) {
		//stdout.printf("mount_changed:%s\n", mount.get_uuid());
	}
	
	public virtual void mount_pre_unmount (Mount mount) {
		//stdout.printf("mount_preunmount:%s\n", mount.get_uuid());
	}
	
	public virtual void mount_removed (Mount mount) {
		foreach(var dev in devices) {
			if(dev.get_path() == mount.get_default_location().get_path()) {
				devices.remove(dev);
				device_removed(dev);
				
				// removing temp medias
				var toRemove = new LinkedList<Media>();
				foreach(int i in dev.get_medias()) {
					Media s = lm.media_from_id(i);
					if(s.isTemporary)
						toRemove.add(s);
					else
						s.unique_status_image = null;
				}
				foreach(int i in dev.get_podcasts()) {
					Media s = lm.media_from_id(i);
					if(s.isTemporary)
						toRemove.add(s);
					else
						s.unique_status_image = null;
				}
				foreach(int i in dev.get_audiobooks()) {
					Media s = lm.media_from_id(i);
					if(s.isTemporary)
						toRemove.add(s);
					else
						s.unique_status_image = null;
				}
				lm.remove_medias(toRemove, false);
				
				return;
			}
		}
	}
	
	/** Device Preferences **/
	public GLib.List<DevicePreferences> device_preferences() {
		var rv = new GLib.List<DevicePreferences>();
		
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
