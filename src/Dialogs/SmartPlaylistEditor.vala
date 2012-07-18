/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
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

/* Merely a place holder for multiple pieces of information regarding
 * the current media playing. Mostly here because of dependence. */

using Gtk;
using Gee;
using Granite.Widgets;

public class BeatBox.SmartPlaylistEditor : Window {

    LibraryWindow lw;
    SmartPlaylist sp;
    
    VBox content;
    HBox padding;
    
    private  Label nameLabel;
    private Label rulesLabel;
    private Label optionsLabel;
    
    Granite.Widgets.HintedEntry _name;
    ComboBoxText comboMatch;
    VBox vertQueries;
    Gee.ArrayList<SmartPlaylistEditorQuery> spQueries;
    Button addButton;
    CheckButton limitMedias;
    SpinButton mediaLimit;
    Button save;
    
    public signal void playlist_saved(SmartPlaylist sp);
    
    public SmartPlaylistEditor(LibraryWindow lw, SmartPlaylist sp) {
        this.lw = lw;
        
        this.title = _("Smart Playlist Editor");
        
        this.window_position = WindowPosition.CENTER;
        this.type_hint = Gdk.WindowTypeHint.DIALOG;
        this.set_modal(true);
        this.set_transient_for(lw);
        this.destroy_with_parent = true;
        
        this.sp = sp;
        
        content = new VBox(false, 10);
        padding = new HBox(false, 10);
        
        /* start out by creating all category labels */
        nameLabel = new Label(_("Name of Playlist"));
        rulesLabel = new Label(_("Rules"));
        optionsLabel = new Label(_("Options"));
        
        /* make them look good */
        nameLabel.xalign = 0.0f;
        rulesLabel.xalign = 0.0f;
        optionsLabel.xalign = 0.0f;
        nameLabel.set_markup("<b>" + Markup.escape_text (_("Name of Playlist"), -1) + "</b>");
        rulesLabel.set_markup("<b>" + Markup.escape_text (_("Rules"), -1) + "</b>");
        optionsLabel.set_markup("<b>" + Markup.escape_text (_("Options"), -1) + "</b>");
        
        /* add the name entry */
        _name = new Granite.Widgets.HintedEntry(_("Playlist Title"));
        if(sp.name != "")
            _name.set_text(sp.name);
        
    /* create match checkbox/combo combination */
        HBox matchBox = new HBox(false, 2);
        Label tMatch = new Label(_("Match"));
        comboMatch = new ComboBoxText();
        comboMatch.insert_text(0, _("any"));
        comboMatch.insert_text(1, _("all"));
        Label tOfTheFollowing = new Label(_("of the following:"));
        
        matchBox.pack_start(tMatch, false, false, 0);
        matchBox.pack_start(comboMatch, false, false, 0);
        matchBox.pack_start(tOfTheFollowing, false, false, 0);
        
        comboMatch.set_active(sp.conditional);
        
        /* create rule list */
        spQueries = new Gee.ArrayList<SmartPlaylistEditorQuery>();
        vertQueries = new VBox(true, 2);
        foreach(SmartQuery q in sp.queries()) {
            SmartPlaylistEditorQuery speq = new SmartPlaylistEditorQuery(q);
            
            vertQueries.pack_start(speq._box, false, true, 1);
            spQueries.add(speq);
        }
        
        if(sp.queries().size == 0) {
            addRow();
        }
        
        addButton = new Gtk.Button.from_stock(Gtk.Stock.ADD);
        vertQueries.pack_end(addButton, false, true, 1);
        addButton.clicked.connect(addButtonClick);
        
        /* create extra option: limiter */
        limitMedias = new CheckButton.with_label(_("Limit to"));
        mediaLimit = new SpinButton.with_range(0, 500, 10);
        Label limiterLabel = new Label(_("items"));
        
        limitMedias.set_active(sp.limit);
        mediaLimit.set_value((double)sp.limit_amount);
        
        HBox limiterBox = new HBox(false, 2);
        limiterBox.pack_start(limitMedias, false, false, 0);
        limiterBox.pack_start(mediaLimit, false, false, 0);
        limiterBox.pack_start(limiterLabel, false, false, 0);
        
        /* add the Save button on bottom */
        HButtonBox bottomButtons = new HButtonBox();
        save = new Gtk.Button.from_stock(Gtk.Stock.SAVE);
        var close_button = new Gtk.Button.from_stock(Gtk.Stock.CLOSE);
        bottomButtons.set_layout(ButtonBoxStyle.END);
        bottomButtons.pack_end(close_button, false, false, 0);
        bottomButtons.pack_end(save, false, false, 0);
        
        /* put it all together */
        content.pack_start(UI.wrap_alignment (nameLabel, 10, 0, 0, 0), false, true, 0);
        content.pack_start(UI.wrap_alignment (_name, 0, 10, 0, 10), false, true, 0);
        content.pack_start(rulesLabel, false, true, 0);
        content.pack_start(UI.wrap_alignment (matchBox, 0, 10, 0, 10) , false, true, 0);
        content.pack_start(UI.wrap_alignment (vertQueries, 0, 10, 0, 10), false, true, 0);
        content.pack_start(optionsLabel, false, true, 0);
        content.pack_start(UI.wrap_alignment (limiterBox, 0, 10, 0, 10), false, true, 0);
        content.pack_start(bottomButtons, false, false, 10);
        
        padding.pack_start(content, true, true, 10);
        
        // Validate initial state
        nameChanged ();
        
        add(padding);
        show_all();
        
        foreach(SmartPlaylistEditorQuery speq in spQueries) {
            speq.fieldChanged();
        }
        
        save.clicked.connect(saveClick);
        close_button.clicked.connect(closeClick);
        _name.changed.connect(nameChanged);
    }
    
    void nameChanged() {
        if (String.is_white_space (_name.get_text())) {
            save.set_sensitive(false);
            return;
        }
        else {
            foreach (var p in lw.library_manager.smart_playlists ()) {
                var fixed_name = _name.get_text ().strip ();
                if((sp == null || sp.rowid != p.rowid) && fixed_name == p.name) {
                    save.set_sensitive(false);
                    return;
                }
            }
        }

        save.set_sensitive(true);
    }

    public void addRow() {
        SmartPlaylistEditorQuery speq = new SmartPlaylistEditorQuery(new SmartQuery());
        
        vertQueries.pack_start(speq._box, false, true, 1);
        spQueries.add(speq);
        
    }
    
    public virtual void addButtonClick() {
        addRow();
    }
    
    public virtual void closeClick() {
        sp.clearQueries();
        
        this.destroy();
    }
    
    public virtual void saveClick() {
        sp.clearQueries();
        foreach(SmartPlaylistEditorQuery speq in spQueries) {
            if(speq._box.visible)
                sp.addQuery(speq.getQuery());
        }
        
        sp.name = _name.text.strip ();
        sp.conditional = (SmartPlaylist.ConditionalType) comboMatch.get_active ();
        sp.limit = limitMedias.get_active();
        sp.limit_amount = (int)mediaLimit.get_value();
        
        playlist_saved(sp);
        
        this.destroy();
    }
}

public class BeatBox.SmartPlaylistEditorQuery : GLib.Object {
    private SmartQuery _q;
    
    public HBox _box;
    private ComboBoxText _field;
    private ComboBoxText _comparator;
    private Entry _value;
    private Rating _valueRating;
    private SpinButton _valueNumerical;
    private ComboBoxText _valueOption;
    private Label _units;
    private Button _remove;
    
    private HashTable<int, SmartQuery.ComparatorType> comparators;
    
    public signal void removed();
    
    public SmartPlaylistEditorQuery(SmartQuery q) {
        _q = q;
        
        comparators = new HashTable<int, SmartQuery.ComparatorType>(null, null);
        
        _box = new HBox(false, 2);
        _field = new ComboBoxText();
        _comparator = new ComboBoxText();
        _value = new Entry();
        _valueNumerical = new SpinButton.with_range(0, 9999, 1);
        _valueOption = new ComboBoxText();
        _valueRating = new Rating (true, IconSize.MENU, true);
        _remove = new Gtk.Button.from_stock(Gtk.Stock.REMOVE);
        
        _field.append_text(_("Album"));
        _field.append_text(_("Artist"));
        _field.append_text(_("Bitrate"));
        _field.append_text(_("Comment"));
        _field.append_text(_("Composer"));
        _field.append_text(_("Date Added"));
        _field.append_text(_("Date Released"));
        _field.append_text(_("Genre"));
        _field.append_text(_("Grouping"));
        _field.append_text(_("Last Played"));
        _field.append_text(_("Length"));
        _field.append_text(_("Media Type"));
        _field.append_text(_("Playcount"));
        _field.append_text(_("Rating"));
        _field.append_text(_("Skipcount"));
        _field.append_text(_("Title"));
        _field.append_text(_("Year"));
        
        _field.set_active((int)q.field);
        message ("setting filed to %d\n", q.field);
        _comparator.set_active((int)q.comparator);
        
        if(needs_value (q.field)) {
            _value.text = q.value;
        }
        else if(q.field == SmartQuery.FieldType.MEDIA_TYPE) {
            _valueOption.append_text(_("Song"));
            _valueOption.append_text(_("Podcast"));
            _valueOption.append_text(_("Audiobook"));
            _valueOption.append_text(_("Radio Station"));
            _valueOption.set_active(int.parse(q.value));
        }
        else if(q.field == SmartQuery.FieldType.RATING) {
            _valueRating.rating = int.parse (q.value);
        }
        else {
            _valueNumerical.set_value(int.parse(q.value));
        }
            
        _units = new Label("");
        
        _box.pack_start(_field, false, true, 0);
        _box.pack_start(_comparator, false ,true, 1);
        _box.pack_start(_value, true, true, 1);
        _box.pack_start(_valueOption, true, true, 1);
        _box.pack_start(_valueRating, true, true, 1);
        _box.pack_start(_valueNumerical, true, true, 1);
        _box.pack_start(_units, false, true, 1);
        _box.pack_start(_remove, false, true, 0);
        
        _box.show_all();
        
        fieldChanged();
        _remove.clicked.connect(removeClicked);
        _field.changed.connect(fieldChanged);
    }
    
    public SmartQuery getQuery() {
        SmartQuery rv = new SmartQuery();
        
        rv.field = (SmartQuery.FieldType)_field.get_active ();
        rv.comparator = comparators.get(_comparator.get_active ());
        
        if(needs_value ((SmartQuery.FieldType)_field.get_active ()))
            rv.value = _value.text;
        else if(_field.get_active() == SmartQuery.FieldType.MEDIA_TYPE)
            rv.value = _valueOption.get_active().to_string();
        else if(_field.get_active() == SmartQuery.FieldType.RATING)
            rv.value = _valueRating.rating.to_string();
        else
            rv.value = _valueNumerical.value.to_string();
        
        return rv;
    }
    
    public virtual void fieldChanged() {
        if(needs_value ((SmartQuery.FieldType)_field.get_active ())) {
            _value.show();
            _valueNumerical.hide();
            _valueOption.hide();
            _valueRating.hide();
            
            comparators.remove_all ();
            for(int i = 0;i < 3; ++i) _comparator.remove(0);
            
            _comparator.append_text(_("is"));
            _comparator.append_text(_("contains"));
            _comparator.append_text(_("does not contain"));
            comparators.insert (0, SmartQuery.ComparatorType.IS);
            comparators.insert (1, SmartQuery.ComparatorType.CONTAINS);
            comparators.insert (2, SmartQuery.ComparatorType.NOT_CONTAINS);
            
            if ((_q.comparator == SmartQuery.ComparatorType.IS) || ((int)_q.comparator-1 > 2))
                _comparator.set_active(0);
            else
                _comparator.set_active((int)_q.comparator-1);
        }
        else if(_field.get_active () == SmartQuery.FieldType.MEDIA_TYPE) {
            _value.hide();
            _valueNumerical.hide();
            _valueOption.show();
            _valueRating.hide();
            
            // upate valueOption 
            _valueOption.remove_all();
            _valueOption.append_text(_("Song"));
            _valueOption.append_text(_("Podcast"));
            _valueOption.append_text(_("Audiobook"));
            _valueOption.append_text(_("Radio Station"));
            _valueOption.set_active(int.parse(_q.value));
            
            _comparator.remove_all();
            
            _comparator.append_text(_("is"));
            _comparator.append_text(_("is not"));
            comparators.insert (0, SmartQuery.ComparatorType.IS);
            comparators.insert (1, SmartQuery.ComparatorType.IS_NOT);
            
            _comparator.set_active((int)_q.comparator);
            if ((int)_q.comparator > 1)
                _comparator.set_active(0);
        }
        else {
            if(is_rating ((SmartQuery.FieldType)_field.get_active ())) {
                _valueNumerical.hide();
                _valueRating.show();
            }
            else {
                _valueNumerical.show();
                _valueRating.hide();
            }
            _value.hide();
            _valueOption.hide();
            
            if(needs_value_2((SmartQuery.FieldType)_field.get_active ())) {
                for(int i = 0;i < 3; ++i) _comparator.remove(0);
                _comparator.append_text(_("is exactly"));
                _comparator.append_text(_("is at most"));
                _comparator.append_text(_("is at least"));
                comparators.insert (0, SmartQuery.ComparatorType.IS_EXACTLY);
                comparators.insert (1, SmartQuery.ComparatorType.IS_AT_MOST);
                comparators.insert (2, SmartQuery.ComparatorType.IS_AT_LEAST);

                if ((int)_q.comparator >= 4)
                    _comparator.set_active((int)_q.comparator-4);
                else
                    _comparator.set_active(0);
            }
            else if(is_date((SmartQuery.FieldType)_field.get_active ())) {
                for(int i = 0;i < 3; ++i) _comparator.remove(0);
                _comparator.append_text(_("is exactly"));
                _comparator.append_text(_("is within"));
                _comparator.append_text(_("is before"));
                comparators.insert (0, SmartQuery.ComparatorType.IS_EXACTLY);
                comparators.insert (1, SmartQuery.ComparatorType.IS_WITHIN);
                comparators.insert (2, SmartQuery.ComparatorType.IS_BEFORE);
                
                if ((_q.comparator == SmartQuery.ComparatorType.IS_EXACTLY) || ((int)_q.comparator-6 > 2))
                    _comparator.set_active(0);
                else
                    _comparator.set_active((int)_q.comparator-6);
            }
        }
        
        _comparator.show();
        
        //helper for units
        if(_field.get_active_text() == _("Length")) {
            _units.set_text(_("seconds"));
            _units.show();
        }
        else if(is_date((SmartQuery.FieldType)_field.get_active ())) {
            _units.set_text(_("days ago"));
            _units.show();
        }
        else if((SmartQuery.FieldType)_field.get_active () == SmartQuery.FieldType.BITRATE) {
            _units.set_text(_("kbps"));
            _units.show();
        }
        else
            _units.hide();
    }
    
    public virtual void removeClicked() {
        removed();
        this._box.hide();
    }
    
    public bool needs_value (SmartQuery.FieldType compared) {
        return (compared == SmartQuery.FieldType.ALBUM || compared == SmartQuery.FieldType.ARTIST || compared == SmartQuery.FieldType.COMMENT || 
                compared == SmartQuery.FieldType.COMPOSER || compared == SmartQuery.FieldType.GENRE || compared == SmartQuery.FieldType.GROUPING || 
                compared == SmartQuery.FieldType.TITLE);
    }
    
    public bool needs_value_2 (SmartQuery.FieldType compared) {
        return (compared == SmartQuery.FieldType.BITRATE || compared == SmartQuery.FieldType.YEAR || compared == SmartQuery.FieldType.RATING || 
                compared == SmartQuery.FieldType.PLAYCOUNT || compared == SmartQuery.FieldType.SKIPCOUNT || compared == SmartQuery.FieldType.LENGTH || 
                compared == SmartQuery.FieldType.TITLE);
    }

    public bool is_rating (SmartQuery.FieldType compared) {
        return compared == SmartQuery.FieldType.RATING;
    }
    
    public bool is_date (SmartQuery.FieldType compared) {
        return (compared == SmartQuery.FieldType.LAST_PLAYED || compared == SmartQuery.FieldType.DATE_ADDED || compared == SmartQuery.FieldType.DATE_RELEASED);
    }
}

