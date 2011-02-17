public class BeatBox.SmartQuery : Object {
	// form a sql query as so:
	// WHERE `_field` _comparator _search
	private int _rowid;
	private string _field; 
	private string _comparator;
	private string _value; //internally this often holds numbers, but that's ok.
	
	public SmartQuery() {
		_field = "album";
		_comparator = "=";
		_value = "";
	}
	
	public SmartQuery.with_info(string field, string comparator, string value) {
		_field = field;
		_comparator = comparator;
		_value = value;
	}
	
	public int rowid {
		get { return _rowid; }
		set { _rowid = value; }
	}
	
	public string field {
		get { return _field; }
		set { _field = value; } // i should check this
	}
	
	public string comparator {
		get { return _comparator; }
		set { _comparator = value; } // i should check this
	}
	
	public string value {
		get { return _value; }
		set { _value = value; }
	}
}
