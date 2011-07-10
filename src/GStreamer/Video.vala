using Gst;

public class BeatBox.Video : GLib.Object {
	public dynamic Gst.Element element;
	
	public Video() {
		element = ElementFactory.make("xvimagesink", "videosink");
	}
}
