// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2013 Noise Developers (http://launchpad.net/noise)
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
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 *              Corentin Noël <tintou@mailoo.org>
 */

public class Noise.EqualizerPreset : Object {

	public string name = "";
	public Gee.ArrayList<int> gains = new Gee.ArrayList<int> ();

	public bool is_default { get; set; default = false; }

	public EqualizerPreset.basic (string name) {
		this.name = name;
		for (int i = 0; i < 10; ++i)
			this.gains.add (0);
	}

	public EqualizerPreset.with_gains (string name, int[] items) {
		this.name = name;
		for(int i = 0; i < 10; ++i)
			this.gains.add (items[i]);
	}

    public EqualizerPreset.from_string (string data) {
        var vals = data.split ("/", 0);
        this.name = vals[0];
        for(int i = 1; i < vals.length; ++i)
            this.gains.add (int.parse (vals[i]));
    }

    public string to_string () {
        string str_preset = "";

        if (name != null && name != "") {
            str_preset = name;
            for (int i = 0; i < 10; ++i)
    				str_preset += "/" + getGain (i).to_string ();
        }

        return str_preset;
    }

	public void setGain (int index, int val) {
		if(index > 9)
			return;
		
		gains.set (index, val);
	}
	
	public int getGain (int index) {
		return gains.get (index);
	}
}

