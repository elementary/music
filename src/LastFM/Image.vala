using Cairo;

public class LastFM.Image : Object {
	private string _url;
	private Gdk.Pixbuf _image;
	private int[] _size;
	private static int default_size = 500;
	
	public string url {
		get { return _url; }
		set { _url = value; if(_image == null) generate_pixbuf(); }
	}
	
	public Gdk.Pixbuf image {
		get {
			if(_image == null && _url != null) {
				generate_pixbuf();
			}
			
			return _image;
		}
		set { _image = value; }
	}
	
	public Image.basic() {
		_url = null;
		_image = null;
		_size = {default_size, default_size};
	}
	
	public Image.with_url(string url, bool generate) {
		_url = url;
		_image = null;
		_size = {default_size, default_size};
		
		if(generate)
			generate_pixbuf();
	}
	
	public Image.with_image(Gdk.Pixbuf image) {
		_image = image;
		_size = {default_size, default_size};
	}
	
	public Image.with_import_string(string s) {
		string[] values = s.split("<value_seperator>", 0);
		
		_url = values[0];
		_image = null;
		_size = new int[2];
		_size[0] = int.parse(values[1]);
		_size[1] = int.parse(values[2]);
	}
	
	public void set_size(int width, int height) {
		_size[0] = width;
		_size[1] = height;
	}
	
	private Gdk.Pixbuf? generate_pixbuf() {
		Gdk.Pixbuf rv;
		
		if(url == null || url == "") {
			return null;
		}
		
		File file = File.new_for_uri(url);
		FileInputStream filestream;
		
		try {
			filestream = file.read(null);
			rv = new Gdk.Pixbuf.from_stream_at_scale(filestream, _size[0], _size[1], true, null);
		}
		catch(GLib.Error err) {
			stdout.printf("Could not fetch album art from %s: %s\n", url, err.message);
			rv = null;
		}
		
		_image = rv;
		return rv;
	}
	
	public string to_string() {
		return _url + "<value_seperator>" + _size[0].to_string() + "<value_seperator>" + _size[1].to_string();
	}
}
