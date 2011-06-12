/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originaly Written by Scott Ringwelski for BeatBox Music Player
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

/* Merely a place holder for multiple pieces of information regarding
 * the current song playing. Mostly here because of dependence. */

using Gee;

public interface BeatBox.Device {
	DeviceType type;
	string internalName;
	string displayName;
	
	bool supportsPlaylists, supportsPodcasts, supportsAlbumArt;
	private string[] supportedFileTypes;
	string musicFolder, podcastFolder, playlistFolder, albumArtFolder;
	GLib.File mountPoint;
	
	int capacity; // in kb
	int availableSpace; // in kb
	string serialNumber;
	
	enum DeviceStatus {
		UNKNOWN,
		DISCONNECTED,
		CONNECTING,
		CONNECTED,
		TRANSFERRING,
		SYNCING
	}
	
	enum SyncMode {
		MANUAL,
		SELECT_PLAYLISTS,
		ENTIRE_LIBRARY
	}
	
	enum FileType {
		SONG,
		PODCAST,
		ALBUM_ART,
		PLAYLIST
	}
	
	enum Error {
		NO_ERROR,
		UNKOWN,
		DEVICE_NOT_FOUND,
		DEVICE_BUSY,
		DEVICE_DISCONNECTED,
		DEVICE_FULL,
		WRITE_ERROR
	}
	
	enum DeviceType {
		UNKOWN,
		MASS_STORAGE,
		MTP,
		ANDROID,
		IPOD_VIDEO,
		IPOD_TOUCH,
		IPHONE,
		IPAD
	}
	
	/** Initializer method
	 * @param internal The internal name of device ex.)apple_ipod_touch_5th_gen
	 * @param display The display name of device ex.) iPod Touch
	 * @param location The mounting point of the device
	*/
	public Device(string internal, string display, DeviceType type, GLib.File location);
	
	
	/** Does the actual device connecting. Done here rather in initializer
	 * so we can return an error.
	*/
	public abstract Error connectDevice();
	
	/** tests to see if device is able to be safely ejected.
	 */
	public abstract bool canEjectDevice();
	
	/** Eject's device. Is not safe. Use canEjectDevice before ejecting.
	 * @return true if successful
	*/
	public abstract bool ejectDevice();
	
	
	/** Returns a linked list of path's of all songs on device
	 * @return a Linked list of all device's songs' paths
	*/
	public abstract LinkedList<string> getSongPaths();
	public abstract LinkedList<string> getPlaylistPaths();
	
	/** Given a referenced linked list of songs, strips out all that are
	 * found on device 
	 * @param the songs to search for
	*/
	public abstract void searchForSongs(ref LinkedList<Song> toSearch);
	public abstract void searchForPlaylists(ref LinkedList<Playlist> toSearch);
	
	/** Adds a song/playlist to device
	 * @param song the song to add
	*/
	public abstract Error addSong(Song song);
	public abstract Error addPlaylist(Playlist playlist);
	
	/** updates a song/playlist on device to match parameter. not sure if
	 * this is fully logical
	*/
	public abstract Error updateSong(Song song);
	public abstract Error updatePlaylist(Playlist playlist);
	
	/** removes the given song/playlist from device
	 */
	public abstract Error removeSong(Song song);
	public abstract Error removePlaylist(Playlist playlist);
	
	/** Adds the given song to playlist p
	 * @param s Song to add
	 * @param p Playlist to add to
	*/
	public abstract Error addSongToPlaylist(Song s, Playlist p);
	
	/** Removes given song from playlist p
	 * 
	*/
	public abstract Error removeSongFromPlaylist(Song s, Playlist p);
	
	/** After doing adding/updating/removing, this is the final operation
	 * that finalizes everything done
	*/
	public abstract Error pushChanges();
	
	/** Given a string location of path, generates a Song object
	 * @param path The path of song
	 * @return a Song from path
	*/
	public abstract Song fetchSong(string path);
	public abstract Playlist fetchPlaylist(string path);
	
	public bool setDeviceName(string name);
}
