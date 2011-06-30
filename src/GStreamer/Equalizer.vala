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
