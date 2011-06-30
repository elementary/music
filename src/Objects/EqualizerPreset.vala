using Gee;

public class BeatBox.EqualizerPreset : Object {
	public string name;
	public ArrayList<int> gains;
	
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
