/*-
 * Copyright (c) 2011-2012	   Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originaly Written by Scott Ringwelski for BeatBox Music Player
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

using Gtk;
using Gee;
using Granite;

#if USE_GRANITE_DECORATED_WINDOW
public class Noise.MediaEditor : Granite.Widgets.LightWindow {
#else
public class Noise.MediaEditor : Window {
#endif
	LibraryManager _lm;
	LyricFetcher lf;
	
	LinkedList<int> _allMedias;
	LinkedList<int> _medias;
	
	//for padding around notebook mostly
	Granite.Widgets.StaticNotebook notebook;

	private HashMap<string, FieldEditor> fields;// a hashmap with each property and corresponding editor
	private TextView lyricsText;
	
	private Button _save;
	
	private InfoBar lyricsInfobar;
	private Label lyricsInfobarLabel;
	
	public signal void medias_saved(LinkedList<int> medias);
	
	public MediaEditor(LibraryManager lm, LinkedList<int> allMedias, LinkedList<int> medias) {
		this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(false);
		this.set_transient_for(lm.lw);
		this.destroy_with_parent = true;
		this.resizable = false;
		
		this.set_size_request (520, -1);

		lf = new LyricFetcher();
		
		_lm = lm;
		
		_allMedias = allMedias;
		_medias = medias;
		
		// don't show notebook separator when using a decorated window
		#if USE_GRANITE_DECORATED_WINDOW
		notebook = new Granite.Widgets.StaticNotebook (false);
		#else
		notebook = new Granite.Widgets.StaticNotebook ();
		#endif

		notebook.append_page(createBasicContent (), new Label(_("Metadata")));
		if(_medias.size == 1)
			notebook.append_page(createLyricsContent (), new Label(_("Lyrics")));
		else
			lyricsText = null;
		
		var buttons = new Gtk.ButtonBox (Orientation.HORIZONTAL);
		buttons.set_layout (Gtk.ButtonBoxStyle.END);

		var arrows = new Granite.Widgets.NavigationArrows ();

		_save = new Button.with_label(_("Done"));
		_save.set_size_request (85, -1);

		_save.valign = arrows.valign = Gtk.Align.END;

		buttons.pack_start (arrows, false, false, 0);
		buttons.pack_end (_save, false, false, 0);

		buttons.set_child_secondary (arrows, true);

		var content = new Gtk.Box (Orientation.VERTICAL, 0);

		buttons.margin_top = 12;

		content.pack_start (notebook, true, true, 0);
		content.pack_start (buttons, false, true, 0);

		content.margin = 12;

		this.add (content);
		
		this.show_all();
		
		arrows.sensitive = allMedias.size > 1;
		
		if(_medias.size == 1) {
			foreach(FieldEditor fe in fields.values)
				fe.set_check_visible(false);
				
			fetch_lyrics (false);
		}

		arrows.previous_clicked.connect(previousClicked);
		arrows.next_clicked.connect(nextClicked);
		_save.clicked.connect(saveClicked);
	}
	
	public Gtk.Box createBasicContent () {
		fields = new HashMap<string, FieldEditor>();
		Media sum = _lm.media_from_id(_medias.get(0)).copy();
		
		/** find what these media have what common, and keep those values **/
		foreach(int i in _medias) {
			Media s = _lm.media_from_id(i);
			
			if(s.track != sum.track)
				sum.track = 0;
			if(s.album_number != sum.album_number)
				sum.album_number = 0;
			if(s.title != sum.title)
				sum.title = "";
			if(s.artist != sum.artist)
				sum.artist = "";
			if(s.album_artist != sum.album_artist)
				sum.album_artist = "";
			if(s.album != sum.album)
				sum.album = "";
			if(s.genre != sum.genre)
				sum.genre = "";
			if(s.comment != sum.comment)
				sum.comment = "";
			if(s.year != sum.year)
				sum.year = 0;
			if(s.bitrate != sum.bitrate)
				sum.bitrate = 0;
			if(s.composer != sum.composer)
				sum.composer = "";
			if(s.grouping != sum.grouping)
				sum.grouping = "";
			//length = 0;
			//samplerate = 0;
			if(s.bpm != sum.bpm)
				sum.bpm = 0;
			if(s.rating != sum.rating)
				sum.rating = 0;
			if(s.mediatype != sum.mediatype)
				sum.mediatype = 0;
			//score = 0;
			//play_count = 0;
			//skip_count = 0;
			//date_added = 0;
			//last_played = 0;
		}

		// be explicit to make translations better		
		if(_medias.size == 1) {
			if (sum.artist != "")
				title = _("Editing %s by %s").printf (sum.title, sum.artist);
			else
				title = _("Editing %s").printf (sum.title);
		}
		else {
			title = _("Editing %i songs").printf (_medias.size);
		}
		
		if(sum.year == -1)
			sum.year = Time().year;
		
		fields.set("Title", new FieldEditor(_("Title"), sum.title, new Entry()));
		fields.set("Artist", new FieldEditor(_("Artist"), sum.artist, new Entry()));
		fields.set("Album Artist", new FieldEditor(_("Album Artist"), sum.album_artist, new Entry()));
		fields.set("Album", new FieldEditor(_("Album"), sum.album, new Entry()));
		fields.set("Genre", new FieldEditor(_("Genre"), sum.genre, new Entry()));
		fields.set("Composer", new FieldEditor(_("Composer"), sum.composer, new Entry()));
		fields.set("Grouping", new FieldEditor(_("Grouping"), sum.grouping, new Entry()));
		fields.set("Comment", new FieldEditor(_("Comment"), sum.comment, new TextView()));
		fields.set("Track", new FieldEditor(_("Track"), sum.track.to_string(), new SpinButton.with_range(0, 500, 1)));
		fields.set("Disc", new FieldEditor(_("Disc"), sum.album_number.to_string(), new SpinButton.with_range(0, 500, 1)));
		fields.set("Year", new FieldEditor(_("Year"), sum.year.to_string(), new SpinButton.with_range(0, 9999, 1)));
		fields.set("Rating", new FieldEditor(_("Rating"), sum.rating.to_string(), new Granite.Widgets.Rating(false, IconSize.MENU)));
#if HAVE_PODCASTS && HAVE_INTERNET_RADIO
		fields.set("Media Type", new FieldEditor(_("Media Type"), sum.mediatype.to_string(), new ComboBoxText()));
#endif

		var vert = new Box (Orientation.VERTICAL, 0); // separates editors with buttons and other stuff
		var horiz = new Box (Orientation.HORIZONTAL, 0); // separates text with numerical editors
		var textVert = new Box (Orientation.VERTICAL, 0); // separates text editors
		var numerVert = new Box (Orientation.VERTICAL, 0); // separates numerical editors
		
		textVert.pack_start(fields.get("Title"), false, true, 0);
		textVert.pack_start(fields.get("Artist"), false, true, 5);
		textVert.pack_start(fields.get("Album Artist"), false, true, 5);
		textVert.pack_start(fields.get("Composer"), false, true, 5);
		textVert.pack_start(fields.get("Album"), false, true, 5);
		textVert.pack_start(fields.get("Comment"), false, true, 5);
		
		numerVert.pack_start(fields.get("Track"), false, true, 0);
		numerVert.pack_start(fields.get("Disc"), false, true, 5);
		numerVert.pack_start(fields.get("Genre"), false, true, 5);
		numerVert.pack_start(fields.get("Grouping"), false, true, 5);
		numerVert.pack_start(fields.get("Year"), false, true, 5);
		numerVert.pack_start(fields.get("Rating"), false, true, 5);
#if HAVE_PODCASTS || HAVE_INTERNET_RADIO
		numerVert.pack_end(fields.get("Media Type"), false, true, 5);
#endif
		//if(medias.size == 1)
			//numerVert.pack_start(stats, false, true, 5);

		horiz.pack_start(UI.wrap_alignment (textVert, 0, 30, 0, 0), false, true, 0);
		horiz.pack_end(numerVert, false, true, 0);
		vert.pack_start(horiz, true, true, 0);

		return vert;
	}
	
	public Gtk.Box createLyricsContent () {
		var lyricsContent = new Gtk.Box (Orientation.VERTICAL, 10);
		
		lyricsInfobarLabel = new Label("");
		
		lyricsInfobarLabel.set_justify(Justification.LEFT);
		lyricsInfobarLabel.set_single_line_mode(true);
		lyricsInfobarLabel.ellipsize = Pango.EllipsizeMode.END;
		
		lyricsInfobar = new InfoBar();
		lyricsInfobar.set_message_type (Gtk.MessageType.INFO);
		
		(lyricsInfobar.get_content_area() as Gtk.Container).add (lyricsInfobarLabel);

		lyricsText = new TextView();
		lyricsText.set_wrap_mode(WrapMode.WORD_CHAR);
		lyricsText.get_buffer().text = _lm.media_from_id(_medias.get(0)).lyrics;

		var text_scroll = new ScrolledWindow(null, null);		
		text_scroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		
		text_scroll.add(lyricsText);
		
		lyricsContent.pack_start(text_scroll, true, true, 0);
		lyricsContent.pack_start(lyricsInfobar, false, true, 5);
		
		lyricsText.set_size_request(400, -1);
		
		return lyricsContent;
	}
	
	public async void fetchLyricsClicked() {
		yield fetch_lyrics (true);
	}
	
	private async void fetch_lyrics (bool overwrite) {
		lyricsInfobar.hide();
		Media s = _lm.media_from_id(_medias.get(0));

		// fetch lyrics here
		if (!(!String.is_white_space (s.lyrics) && !overwrite)) {
			s.lyrics = yield lf.fetch_lyrics_async (s);

            var current_media = _lm.media_from_id (_medias.get(0));
            if (current_media == s)
                lyricsFetched (s);
	    }
	}
	

	public void lyricsFetched (Media m) {
        Gdk.threads_enter ();

		lyricsInfobarLabel.set_text ("");
		lyricsInfobar.hide();

		if (!String.is_white_space (m.lyrics)) {
			lyricsText.get_buffer().text = m.lyrics;
		}
		else {
			lyricsInfobar.show_all();
			lyricsInfobarLabel.set_markup (_("Lyrics not found for %s").printf ("<i>" + String.escape (m.title) + "</i>"));
		}

        Gdk.threads_leave ();
	}

	
	public void previousClicked() {
		save_medias();
		
		// now fetch the next media on current_view
		int i = 0; // will hold next media to edit
		int indexOfCurrentFirst = _allMedias.index_of(_medias.get(0));
		
		if(indexOfCurrentFirst == 0)
			i = _allMedias.get(_allMedias.size - 1);
		else
			i = _allMedias.get(indexOfCurrentFirst - 1);
		
		// now fetch the previous media on current_view
		var newMedias = new LinkedList<int>();
		newMedias.add(i);
		
		change_media(newMedias);
	}
	
	public void nextClicked() {
		save_medias();
		
		// now fetch the next media on current_view
		int i = 0; // will hold next media to edit
		int indexOfCurrentLast = _allMedias.index_of(_medias.get(_medias.size - 1));
		
		if(indexOfCurrentLast == _allMedias.size - 1)
			i = _allMedias.get(0);
		else
			i = _allMedias.get(indexOfCurrentLast + 1);
		
		var newMedias = new LinkedList<int>();
		newMedias.add(i);
		
		change_media(newMedias);
	}
	
	public void change_media(LinkedList<int> newMedias) {
		_medias = newMedias;
		
		Media sum = _lm.media_from_id(newMedias.get(0));

		// be explicit to improve translations
		if(_medias.size == 1) {
			if (sum.artist != "")
				title = _("Editing %s by %s").printf (sum.title, sum.artist);
			else
				title = _("Editing %s").printf (sum.title);
		}
		else {
			title = _("Editing %i songs").printf (_medias.size);
		}

		/* do not show check boxes for 1 media */
		foreach(FieldEditor fe in fields.values)
			fe.set_check_visible(false);
		
		fields.get("Title").set_value(sum.title);
		fields.get("Artist").set_value(sum.artist);
		fields.get("Album Artist").set_value(sum.album_artist);
		fields.get("Album").set_value(sum.album);
		fields.get("Genre").set_value(sum.genre);
		fields.get("Comment").set_value(sum.comment);
		fields.get("Track").set_value(sum.track.to_string());
		fields.get("Disc").set_value(sum.album_number.to_string());
		fields.get("Year").set_value(sum.year.to_string());
		fields.get("Rating").set_value(sum.rating.to_string());
		fields.get("Composer").set_value(sum.composer);
		fields.get("Grouping").set_value(sum.grouping);
#if HAVE_PODCASTS && HAVE_INTERNET_RADIO
		fields.get("Media Type").set_value(sum.mediatype.to_string());
#endif	
		if(lyricsText == null) {
			var lyrics = createLyricsContent ();
			notebook.append_page(lyrics, new Label(_("Lyrics")));
			lyrics.show_all();
		}

		lyricsText.get_buffer().text = sum.lyrics;

		fetch_lyrics (false);
	}
	
	public void save_medias() {
		foreach(int i in _medias) {
			Media s = _lm.media_from_id(i);
			
			if(fields.get("Title").checked())
				s.title = fields.get("Title").get_value();
			if(fields.get("Artist").checked())
				s.artist = fields.get("Artist").get_value();
			if(fields.get("Album Artist").checked())
				s.album_artist = fields.get("Album Artist").get_value();
			if(fields.get("Album").checked())
				s.album = fields.get("Album").get_value();
			if(fields.get("Genre").checked())
				s.genre = fields.get("Genre").get_value();
			if(fields.get("Composer").checked())
				s.composer = fields.get("Composer").get_value();
			if(fields.get("Grouping").checked())
				s.grouping = fields.get("Grouping").get_value();
			if(fields.get("Comment").checked())
				s.comment = fields.get("Comment").get_value();
				
			if(fields.get("Track").checked())
				s.track = int.parse(fields.get("Track").get_value());
			if(fields.get("Disc").checked())
				s.album_number = int.parse(fields.get("Disc").get_value());
			if(fields.get("Year").checked())
				s.year = int.parse(fields.get("Year").get_value());
			if(fields.get("Rating").checked())
				s.rating = int.parse(fields.get("Rating").get_value());

#if HAVE_PODCASTS && HAVE_INTERNET_RADIO
			if(fields.get("Media Type").checked())
				s.mediatype = int.parse(fields.get("Media Type").get_value());
#endif
				
			// save lyrics
			if(lyricsText != null) {
				var lyrics = lyricsText.get_buffer().text;
				if (!String.is_white_space (lyrics))
					s.lyrics = lyrics;
			}
		}
		
		medias_saved(_medias);
	}
	
	public virtual void saveClicked() {
		save_medias();
		
		this.destroy();
	}
}

public class Noise.FieldEditor : VBox {
	private string _name;
	private string _original;
	
	private HBox nameBox;
	
	private CheckButton check;
	private Label label;
	private Entry entry;
	private TextView textView;
	private SpinButton spinButton;
	private Granite.Widgets.Rating ratingWidget;
	private Image image;
#if HAVE_PODCASTS && HAVE_INTERNET_RADIO
	private ComboBoxText comboBox;
#endif
	//private DoubleSpinButton doubleSpinButton;

	public FieldEditor(string name, string original, Widget w) {
		_name = name;
		_original = original;
		
		this.spacing = 0;
		
		check = new CheckButton();
		label = new Label(_name);
		nameBox = new HBox(false, 0);
		
		label.justify = Justification.LEFT;
		label.xalign = 0.0f;
		label.set_markup("<b>" + _name + "</b>");
		
		nameBox.pack_start(check, false, false, 0);
		nameBox.pack_start(label, false, true, 0);
		
		this.pack_start(nameBox, false, false, 0);
		
		if(w is Entry && !(w is SpinButton)) {
			check.set_active(original != "");
			
			entry = (Entry)w;
			if(name != _("Genre") && name != _("Grouping"))
				entry.set_size_request(300, -1);
			else
				entry.set_size_request(100, -1);
			
			entry.set_text(original);
			entry.changed.connect(entryChanged);
			this.pack_start(entry, true, true, 0);
		}
		else if(w is TextView) {
			check.set_active(original != "");
			
			textView = (TextView)w;
			textView.set_size_request(300, 90);
			textView.set_wrap_mode(WrapMode.WORD_CHAR);
			textView.get_buffer().text = original;
			
			ScrolledWindow scroll = new ScrolledWindow(null, null);
			scroll.set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
			
			scroll.add(textView);
			
			scroll.set_size_request(300, 100);
			
			textView.buffer.changed.connect(textViewChanged);
			this.pack_start(scroll, true, true, 0);
		}
		else if(w is SpinButton) {
			check.set_active(original != "0");
			
			spinButton = (SpinButton)w;
			spinButton.set_size_request(100, -1);
			spinButton.value = check.get_active() ? double.parse(original) : 0.0;
			spinButton.adjustment.value_changed.connect(spinButtonChanged);
			this.pack_start(spinButton, true, true, 0);
		}
		else if(w is Image) {
			check.set_active(original != "");
			
			image = (Image)w;
			image.set_size_request(100, 100);
			image.set_from_file(original);
			//callback on file dialogue saved. setup here
			this.pack_start(image, true, true, 0);
		}
		else if(w is Granite.Widgets.Rating) {
			check.set_active(original != "0");
			
			ratingWidget = (Granite.Widgets.Rating)w;
			ratingWidget.rating = int.parse (original);
			ratingWidget.rating_changed.connect(ratingChanged);
			
			this.pack_start(ratingWidget, true, true, 0);
		}
#if HAVE_PODCASTS && HAVE_INTERNET_RADIO
		else if(w is ComboBoxText) {
			check.set_active(original != "0");
			
			comboBox = (ComboBoxText)w;
			comboBox.append_text(_("Song"));
#if HAVE_PODCASTS
			comboBox.append_text(_("Podcast"));
#endif
			comboBox.set_active(int.parse(original));
			comboBox.changed.connect(comboChanged);
			
			this.pack_start(comboBox, true, true, 0);
		}
#endif
	}
	
	public void set_check_visible(bool val) {
		check.set_visible(false);
	}
	
	public virtual void entryChanged() {
		if(entry.text != _original)
			check.set_active(true);
		else
			check.set_active(false);
	}
	
	public virtual void textViewChanged() {
		if(textView.get_buffer().text != _original)
			check.set_active(true);
		else
			check.set_active(false);
	}
	
	public virtual void spinButtonChanged() {
		if(spinButton.value != double.parse(_original))
			check.set_active(true);
		else
			check.set_active(false);
	}
	
	public virtual void ratingChanged(int new_rating) {
		if(ratingWidget.rating != int.parse(_original))
			check.set_active(true);
		else
			check.set_active(false);
	}
#if HAVE_PODCASTS && HAVE_INTERNET_RADIO	
	public virtual void comboChanged() {
		if(comboBox.get_active() != int.parse(_original))
			check.set_active(true);
		else
			check.set_active(false);
	}
#endif
	
	public bool checked() {
		return check.get_active();
	}
	
	public virtual void resetClicked() {
		if(entry != null) {
			entry.text = _original;
		}
		else if(textView != null) {
			textView.get_buffer().text = _original;
		}
		else if(spinButton != null) {
			spinButton.value = double.parse(_original);
		}
		else if(image != null) {
			image.set_from_file(_original);
		}
		else if(ratingWidget != null) {
			ratingWidget.rating = int.parse (_original);
		}
#if HAVE_PODCASTS && HAVE_INTERNET_RADIO
		else if(comboBox != null) {
			comboBox.set_active(int.parse(_original));
		}
#endif
	}
	
	public string get_value() {
		if(entry != null) {
			return entry.text;
		}
		else if(textView != null) {
			return textView.get_buffer().text;
		}
		else if(spinButton != null) {
			return spinButton.value.to_string();
		}
		else if(image != null) {
			return image.file;
		}
		else if(ratingWidget != null) {
			return ratingWidget.rating.to_string();
		}
#if HAVE_PODCASTS && HAVE_INTERNET_RADIO
		else if(comboBox != null) {
			return comboBox.get_active().to_string();
		}
#endif
		
		return "";
	}
	
	public void set_value(string val) {
		if(entry != null) {
			entry.text = val;
		}
		else if(textView != null) {
			textView.get_buffer().text = val;
		}
		else if(spinButton != null) {
			spinButton.value = double.parse(val);
		}
		else if(image != null) {
			image.file = val;
		}
		else if(ratingWidget != null) {
			ratingWidget.rating = int.parse (val);
		}
#if HAVE_PODCASTS && HAVE_INTERNET_RADIO
		else if(comboBox != null) {
			comboBox.set_active(int.parse(val));
		}
#endif
	}
}

public class Noise.StatsDisplay : VBox {
	public int plays;
	public int skips;
	public int last_played;
	
	Label header;
	Label info;
	Button reset;
	
	public StatsDisplay(int plays, int skips, int last_played) {
		this.plays = plays;
		this.skips = skips;
		this.last_played = last_played;
		
		header = new Label("");
		info = new Label("");
		reset = new Button.with_label("Reset");
		
		header.justify = Justification.LEFT;
		header.xalign = 0.0f;
		header.set_markup("<b>Stats</b>");
		
		info.justify = Justification.LEFT;
		info.xalign = 0.0f;
		
		setInfoText();
		
		pack_start(header, true, false, 0);
		pack_start(info, true, true, 0);
		pack_start(reset, true, false, 0);
		
		reset.clicked.connect(resetClicked);
	}
	
	public virtual void resetClicked() {
		plays = 0;
		skips = 0;
		last_played = 0;
		
		setInfoText();
		
		reset.set_sensitive(false);
	}
	
	private void setInfoText() {
		var t = Time.local(last_played);
		string pretty_last_played = t.format("%m/%e/%Y %l:%M %p");
		
		string text = "";
		text += "Plays: <span gravity=\"east\">" + plays.to_string() + "</span>\n";
		text += "Skips: <span gravity=\"east\">" + skips.to_string() + "</span>\n";
		text += "Last Played: <span gravity=\"east\">" + ((last_played != 0) ? pretty_last_played : "Never") + "</span>";
		
		info.set_markup(text);
	}
}

/*public class Noise.DoubleSpinButton : HBox {
	private SpinButton spin1;
	private SpinButton spin2;
	
	public DoubleSpinButton(double val1, double val2, double maxVal) {
		spin1 = new SpinButton.with_range(0.0, maxVal, 1.0);
		spin2 = new SpinButton.with_range(0.0, maxVal, 1.0);
		
		spin1.set_value(val1);
		spin2.set_value(val2);
	}
	
	public double getVal1() {
		return spin1.get_value();
	}
	
	public double getVal2() {
		return spin2.get_value();
	}
}*/
