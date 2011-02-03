public class LastFM.Tag : Object {
	private string _tag;
	private string _url;
	
	public Tag.with_string(string tag) {
		_tag = tag;
	}
	
	public Tag.with_string_and_url(string tag, string url) {
		_tag = tag;
		_url = url;
	}
	
	public string tag {
		get { return _tag; } 
		set { _tag = value; }
	}
	
	public string url {
		get { return _url; }
		set { _url = value; }
	}
	
}
