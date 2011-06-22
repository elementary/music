using Gtk;
using Gdk;

public class Store.TagLabel : EventBox {
	public Gtk.Label label; // actual label. wrapped around eventbox for click catching
	public Color foreground; // text color and hover color
	public Color background; // default background color
	public Color secondary; // new text color on hover
	
	public TagLabel(string label, Color fore, Color back, Color sec) {
		this.label = new Gtk.Label(label);
		this.foreground = fore;
		this.background = back;
		this.secondary = sec;
		
		this.add(this.label);
	}
}
