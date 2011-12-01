/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
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

public class BeatBox.EqualizerPreset : Object {

	public string name;
	public ArrayList<int> gains;

	private bool _default_preset = false;

	public bool is_default {
		get {
			return _default_preset;
		}
		set {
			_default_preset = value;
		}
	}

	public EqualizerPreset.basic(string name) {
		this.name = name;
		
		gains = new ArrayList<int>();

		for(int i = 0; i < 10; ++i)
			this.gains.add(0);
	}
	
	public EqualizerPreset.with_gains(string name, int[] items) {
		this.name = name;
		this.gains = new ArrayList<int>();
		
		for(int i = 0; i < 10; ++i)
			this.gains.add(items[i]);
	}
	
	public void setGain(int index, int val) {
		if(index > 9)
			return;
		
		gains.set(index, val);
	}
	
	public int getGain(int index) {
		return gains.get(index);
	}

}

