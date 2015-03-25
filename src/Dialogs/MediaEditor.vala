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
 *              Corentin Noël <tintou@mailoo.org>
 */

/**
 * TODO: make this dialog edit and handle Media objects and not media rowids.
 *       We need this in order to allow editing temporary tracks (such as Audio
 *       CDs before importing their media to the library).
 */

public class Noise.MediaEditor : Gtk.Dialog {
    LyricFetcher lf;
    
    Gee.LinkedList<int> _allMedias = new Gee.LinkedList<int> ();
    Gee.LinkedList<int> _medias = new Gee.LinkedList<int> ();
    
    //for padding around notebook mostly
    Gtk.Stack stack;

    private Gee.HashMap<string, FieldEditor> fields;// a hashmap with each property and corresponding editor
    private Gtk.TextView lyricsText;
    
    private Gtk.Button save_button;
    private Gtk.Button close_button;
    
    private Gtk.Label lyricsInfobarLabel;
    private Library library;
    
    public signal void medias_saved (Gee.Collection<int> medias);
    
    public MediaEditor (Gee.Collection<int> allMedias, Gee.Collection<int> medias, Library library) {
        this.library = library;
        this.window_position = Gtk.WindowPosition.CENTER;
        this.type_hint = Gdk.WindowTypeHint.DIALOG;
        this.set_modal(false);
        this.set_transient_for(App.main_window);
        this.destroy_with_parent = true;
        this.resizable = false;
        this.deletable = false;
        
        this.set_size_request (520, -1);

        lf = new LyricFetcher();
        
        _allMedias.add_all (allMedias);
        _medias.add_all (medias);
        
        stack = new Gtk.Stack ();
        
        var stack_switcher = new Gtk.StackSwitcher ();
        stack_switcher.set_stack (stack);
        stack_switcher.halign = Gtk.Align.CENTER;
        stack_switcher.margin_bottom = 24;
        stack_switcher.margin_top = 12;

        stack.add_titled (createBasicContent (), "metadata", _("Details"));
        if(_medias.size == 1)
            stack.add_titled (createLyricsContent (), "lyrics", _("Lyrics"));
        else
            lyricsText = null;

        var arrows = new Noise.Widgets.NavigationArrows ();

        save_button = new Gtk.Button.with_label (_(STRING_SAVE));
        save_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        close_button  = new Gtk.Button.with_label (_("Close"));

        var buttons = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        buttons.set_layout (Gtk.ButtonBoxStyle.END);
        buttons.set_spacing (6);
        buttons.margin_top = 6;

        buttons.pack_start (arrows, false, false, 0);
        buttons.pack_end (close_button, false, false, 0);
        buttons.pack_end (save_button, false, false, 0);
        buttons.set_child_secondary (arrows, true);

        var main_grid = new Gtk.Grid ();
        main_grid.attach (stack, 0, 0, 1, 1);
        main_grid.attach (buttons, 0, 1, 1, 1);

        var content = get_content_area () as Gtk.Container;
        content.margin_left = content.margin_right = 12;
        content.add (main_grid);

        this.show_all();

        arrows.sensitive = allMedias.size > 1;

        if(_medias.size == 1) {
            foreach(FieldEditor fe in fields.values)
                fe.set_check_visible(false);
                
            fetch_lyrics.begin (false);
        }

        arrows.previous_clicked.connect (previousClicked);
        arrows.next_clicked.connect (nextClicked);
        save_button.clicked.connect (saveClicked);
        close_button.clicked.connect (() => {destroy ();});
    }
    
    public Gtk.Box createBasicContent () {
        fields = new Gee.HashMap<string, FieldEditor>();
        Media sum = library.media_from_id(_medias.get(0)).copy();
        
        /** find what these media have what common, and keep those values **/
        foreach(int i in _medias) {
            Media s = library.media_from_id(i);
            
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
            //score = 0;
            //play_count = 0;
            //skip_count = 0;
            //date_added = 0;
            //last_played = 0;
        }

        // be explicit to make translations better        
        if(_medias.size == 1) {
            if (sum.artist != "")
                title = _("Editing $NAME by $ARTIST").replace ("$NAME", sum.title).replace("$ARTIST", sum.artist);
            else
                title = _("Editing %s").printf (sum.title);
        }
        else {
            title = _("Editing %i songs").printf (_medias.size);
        }
        
        if(sum.year == -1)
            sum.year = Time().year;
        
        fields.set("Title", new FieldEditor(_("Title"), sum.title, new Gtk.Entry()));
        fields.set("Artist", new FieldEditor(_("Artist"), sum.artist, new Gtk.Entry()));
        fields.set("Album Artist", new FieldEditor(_("Album Artist"), sum.album_artist, new Gtk.Entry()));
        fields.set("Album", new FieldEditor(_("Album"), sum.album, new Gtk.Entry()));
        fields.set("Genre", new FieldEditor(_("Genre"), sum.genre, new Gtk.Entry()));
        fields.set("Composer", new FieldEditor(_("Composer"), sum.composer, new Gtk.Entry()));
        fields.set("Grouping", new FieldEditor(_("Grouping"), sum.grouping, new Gtk.Entry()));
        fields.set("Comment", new FieldEditor(_("Comment"), sum.comment, new Gtk.TextView()));
        fields.set("Track", new FieldEditor(_("Track"), sum.track.to_string(), new Gtk.SpinButton.with_range(0, 500, 1)));
        fields.set("Disc", new FieldEditor(_("Disc"), sum.album_number.to_string(), new Gtk.SpinButton.with_range(0, 500, 1)));
        fields.set("Year", new FieldEditor(_("Year"), sum.year.to_string(), new Gtk.SpinButton.with_range(0, 9999, 1)));
        fields.set("Rating", new FieldEditor(_("Rating"), sum.rating.to_string(), new Granite.Widgets.Rating(false, Gtk.IconSize.MENU)));

        var vert = new Gtk.Box (Gtk.Orientation.VERTICAL, 0); // separates editors with buttons and other stuff
        var horiz = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0); // separates text with numerical editors
        var textVert = new Gtk.Box (Gtk.Orientation.VERTICAL, 0); // separates text editors
        var numerVert = new Gtk.Box (Gtk.Orientation.VERTICAL, 0); // separates numerical editors
        
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
        //if(medias.size == 1)
            //numerVert.pack_start(stats, false, true, 5);

        horiz.pack_start(UI.wrap_alignment (textVert, 0, 30, 0, 0), false, true, 0);
        horiz.pack_end(numerVert, false, true, 0);
        vert.pack_start(horiz, true, true, 0);

        return vert;
    }
    
    public Gtk.Box createLyricsContent () {
        var lyricsContent = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        
        lyricsInfobarLabel = new Gtk.Label("");
        
        lyricsInfobarLabel.set_justify(Gtk.Justification.LEFT);
        lyricsInfobarLabel.set_single_line_mode(true);
        lyricsInfobarLabel.ellipsize = Pango.EllipsizeMode.END;
        

        lyricsText = new Gtk.TextView();
        lyricsText.set_wrap_mode(Gtk.WrapMode.WORD_CHAR);
        lyricsText.get_buffer().text = library.media_from_id(_medias.get(0)).lyrics;

        var text_scroll = new Gtk.ScrolledWindow(null, null);
        text_scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        
        text_scroll.add(lyricsText);

        var frame = new Gtk.Frame (null);
        frame.add (text_scroll);
        
        lyricsContent.pack_start(frame, true, true, 0);
        lyricsContent.pack_start(lyricsInfobarLabel, false, true, 5);
        
        lyricsText.set_size_request(400, -1);
        
        return lyricsContent;
    }
    
    public async void fetchLyricsClicked() {
        yield fetch_lyrics (true);
    }
    
    private async void fetch_lyrics (bool overwrite) {
        lyricsInfobarLabel.hide();
        Media s = library.media_from_id(_medias.get(0));

        // fetch lyrics here
        if (!(!String.is_white_space (s.lyrics) && !overwrite)) {
            s.lyrics = yield lf.fetch_lyrics_async (s);

            var current_media = library.media_from_id (_medias.get(0));
            if (current_media == s)
                lyricsFetched (s);
        }
    }
    

    public void lyricsFetched (Media m) {
        Idle.add ( () => {

            lyricsInfobarLabel.set_text ("");
            lyricsInfobarLabel.hide();

            if (!String.is_white_space (m.lyrics)) {
                lyricsText.get_buffer().text = m.lyrics;
            }
            else {
                lyricsInfobarLabel.show_all();
                lyricsInfobarLabel.set_markup (_("Lyrics not found for %s").printf ("<i>" + String.escape (m.title) + "</i>"));
            }
            return false;
        });
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
        var newMedias = new Gee.LinkedList<int>();
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
        
        var newMedias = new Gee.LinkedList<int>();
        newMedias.add(i);
        
        change_media(newMedias);
    }
    
    public void change_media(Gee.LinkedList<int> newMedias) {
        _medias = newMedias;
        
        Media sum = library.media_from_id(newMedias.get(0));

        // be explicit to improve translations
        if(_medias.size == 1) {
            if (sum.artist != "")
                title = _("Editing $NAME by $ARTIST").replace ("$NAME", sum.title).replace("$ARTIST", sum.artist);
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
        if(lyricsText == null) {
            var lyrics = createLyricsContent ();
            stack.add_titled (lyrics, "lyrics", _("Lyrics"));
            lyrics.show_all();
        }

        lyricsText.get_buffer().text = sum.lyrics;

        fetch_lyrics.begin (false);
    }
    
    public void save_medias() {
        foreach(int i in _medias) {
            Media s = library.media_from_id(i);
            
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

public class Noise.FieldEditor : Gtk.Box {
    private string _name;
    private string _original;
    
    private Gtk.Box nameBox;
    
    private Gtk.CheckButton check;
    private Gtk.Label label;
    private Gtk.Entry entry;
    private Gtk.TextView textView;
    private Gtk.SpinButton spinButton;
    private Granite.Widgets.Rating ratingWidget;
    private Gtk.Image image;
    //private DoubleSpinButton doubleSpinButton;

    public FieldEditor(string name, string original, Gtk.Widget w) {
        _name = name;
        _original = original;
        set_orientation (Gtk.Orientation.VERTICAL);
        this.spacing = 0;
        
        check = new Gtk.CheckButton();
        label = new Gtk.Label(_name);
        nameBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        
        label.justify = Gtk.Justification.LEFT;
        label.halign = Gtk.Align.START;
        label.set_markup("<b>" + _name + "</b>");
        
        nameBox.pack_start(check, false, false, 0);
        nameBox.pack_start(label, false, true, 0);
        
        this.pack_start(nameBox, false, false, 0);
        
        if(w is Gtk.Entry && !(w is Gtk.SpinButton)) {
            check.set_active(original != "");
            
            entry = (Gtk.Entry)w;
            if(name != _("Genre") && name != _("Grouping"))
                entry.set_size_request(300, -1);
            else
                entry.set_size_request(100, -1);
            
            entry.set_text(original);
            entry.changed.connect(entryChanged);
            this.pack_start(entry, true, true, 0);
        }
        else if(w is Gtk.TextView) {
            check.set_active(original != "");
            
            textView = (Gtk.TextView)w;
            textView.set_size_request(300, 90);
            textView.set_wrap_mode(Gtk.WrapMode.WORD_CHAR);
            textView.get_buffer().text = original;
            
            var scroll = new Gtk.ScrolledWindow(null, null);
            scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            
            scroll.add(textView);
            
            scroll.set_size_request(300, 100);
            
            textView.buffer.changed.connect(textViewChanged);
            this.pack_start(scroll, true, true, 0);
        }
        else if(w is Gtk.SpinButton) {
            check.set_active(original != "0");
            
            spinButton = (Gtk.SpinButton)w;
            spinButton.set_size_request(100, -1);
            spinButton.value = check.get_active() ? double.parse(original) : 0.0;
            spinButton.adjustment.value_changed.connect(spinButtonChanged);
            this.pack_start(spinButton, true, true, 0);
        }
        else if(w is Gtk.Image) {
            check.set_active(original != "");
            
            image = (Gtk.Image)w;
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
    }
}

public class Noise.StatsDisplay : Gtk.Box {
    public int plays;
    public int skips;
    public int last_played;
    
    Gtk.Label header;
    Gtk.Label info;
    Gtk.Button reset;
    
    public StatsDisplay(int plays, int skips, int last_played) {
        this.plays = plays;
        this.skips = skips;
        this.last_played = last_played;
        set_orientation (Gtk.Orientation.VERTICAL);
        
        header = new Gtk.Label("");
        info = new Gtk.Label("");
        reset = new Gtk.Button.with_label(_("Reset"));
        
        header.justify = Gtk.Justification.LEFT;
        header.halign = Gtk.Align.START;
        header.set_markup(_("<b>Stats</b>"));
        
        info.justify = Gtk.Justification.LEFT;
        info.halign = Gtk.Align.START;
        
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
