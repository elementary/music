public class BeatBox.Device : GLib.Object {
	private Mount m;
	
	private string[] mediaTypes;
	
	public Device(Mount m) {
		this.m = m;
		
		m.guess_content_type(false,null, onGuessContentType);
	}
	
	public void onGuessContentType(GLib.Object? source_object, GLib.AsyncResult res){
		try {
			//mediaTypes = m.guess_content_type_finish(res);
			
			foreach(string s in mediaTypes) {
				stdout.printf("Media type: %s\n", s);
			}
			
		} 
		catch(GLib.Error err) {
			stdout.printf("Could not guess guess %s media type: %s", m.get_name(), err.message);
		}
	}
}
