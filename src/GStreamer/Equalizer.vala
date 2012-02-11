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

using Gst;

public class BeatBox.Equalizer : GLib.Object {
	public dynamic Gst.Element element;
	
	public Equalizer() {
		element = ElementFactory.make("equalizer-10bands", "equalizer");
		
		int[10] freqs = {60, 170, 310, 600, 1000, 3000, 6000, 12000, 14000, 16000};
		
		float last_freq = 0;
		for (int index = 0; index < 10; index++) {
			Gst.Object band = ((Gst.ChildProxy)element).get_child_by_index(index);
			
			float freq = freqs[index];
			float bandwidth = freq - last_freq;
			last_freq = freq;
			
			band.set("freq", freq,
			"bandwidth", bandwidth,
			"gain", 0.0f);
		}
	}
	
	public void setGain(int index, double gain) {
		Gst.Object band = ((Gst.ChildProxy)element).get_child_by_index(index);
		
		if (gain < 0)
			gain *= 0.24f;
		else
			gain *= 0.12f;
		
		band.set("gain", gain);
	}
}
