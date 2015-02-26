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
 */

public class Noise.Equalizer : GLib.Object {
	public dynamic Gst.Element element;

	public Equalizer() {
		element = Gst.ElementFactory.make("equalizer-10bands", "equalizer");
		
		int[10] freqs = {60, 170, 310, 600, 1000, 3000, 6000, 12000, 14000, 16000};
		//int[10] freqs = {32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000};

		float last_freq = 0;
		for (int index = 0; index < 10; index++) {
			GLib.Object? band = ((Gst.ChildProxy)element).get_child_by_index (index);
			
			float freq = freqs[index];
			float bandwidth = freq - last_freq;
			last_freq = freq;
			
			band.set("freq", freq,
			"bandwidth", bandwidth,
			"gain", 0.0f);
		}
	}
	
	public void setGain(int index, double gain) {
		GLib.Object? band = ((Gst.ChildProxy)element).get_child_by_index (index);
		
		if (gain < 0)
			gain *= 0.24f;
		else
			gain *= 0.12f;
		
		band.set("gain", gain);
	}

	private static Gee.TreeSet<EqualizerPreset> ? default_presets = null;
	public static Gee.Collection<EqualizerPreset> get_default_presets () {
		if (default_presets != null)
			return default_presets;

		default_presets = new Gee.TreeSet<EqualizerPreset> ();

		default_presets.add (new EqualizerPreset.with_gains (_("Flat"), {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}));
		default_presets.add (new EqualizerPreset.with_gains (_("Classical"), {0, 0, 0, 0, 0, 0, -40, -40, -40, -50}));
		default_presets.add (new EqualizerPreset.with_gains (_("Club"), {0, 0, 20, 30, 30, 30, 20, 0, 0, 0}));
		default_presets.add (new EqualizerPreset.with_gains (_("Dance"), {50, 35, 10, 0, 0, -30, -40, -40, 0, 0}));
		default_presets.add (new EqualizerPreset.with_gains (_("Full Bass"), {70, 70, 70, 40, 20, -45, -50, -55, -55, -55}));
		default_presets.add (new EqualizerPreset.with_gains (_("Full Treble"), {-50, -50, -50, -25, 15, 55, 80, 80, 80, 80}));
		default_presets.add (new EqualizerPreset.with_gains (_("Full Bass + Treble"), {35, 30, 0, -40, -25, 10, 45, 55, 60, 60}));
		default_presets.add (new EqualizerPreset.with_gains (_("Headphones"), {25, 50, 25, -20, 0, -30, -40, -40, 0, 0}));
		default_presets.add (new EqualizerPreset.with_gains (_("Large Hall"), {50, 50, 30, 30, 0, -25, -25, -25, 0, 0}));
		default_presets.add (new EqualizerPreset.with_gains (_("Live"), {-25, 0, 20, 25, 30, 30, 20, 15, 15, 10}));
		default_presets.add (new EqualizerPreset.with_gains (_("Party"), {35, 35, 0, 0, 0, 0, 0, 0, 35, 35}));
		default_presets.add (new EqualizerPreset.with_gains (_("Pop"), {-10, 25, 35, 40, 25, -5, -15, -15, -10, -10}));
		default_presets.add (new EqualizerPreset.with_gains (_("Reggae"), {0, 0, -5, -30, 0, -35, -35, 0, 0, 0}));
		default_presets.add (new EqualizerPreset.with_gains (_("Rock"), {40, 25, -30, -40, -20, 20, 45, 55, 55, 55}));
		default_presets.add (new EqualizerPreset.with_gains (_("Soft"), {25, 10, -5, -15, -5, 20, 45, 50, 55, 60}));
		default_presets.add (new EqualizerPreset.with_gains (_("Ska"), {-15, -25, -25, -5, 20, 30, 45, 50, 55, 50}));
		default_presets.add (new EqualizerPreset.with_gains (_("Soft Rock"), {20, 20, 10, -5, -25, -30, -20, -5, 15, 45}));
		default_presets.add (new EqualizerPreset.with_gains (_("Techno"), {40, 30, 0, -30, -25, 0, 40, 50, 50, 45}));

		return default_presets.read_only_view;
	}
}
