
public class Noise.BottomStatusBar : Granite.Widgets.StatusBar {

    /* Statusbar items */
    private SimpleOptionChooser addPlaylistChooser;
    private SimpleOptionChooser shuffleChooser;
    private SimpleOptionChooser repeatChooser;
    private SimpleOptionChooser info_panel_chooser;
    private SimpleOptionChooser eq_option_chooser;
    
    private LibraryWindow lw;

    public BottomStatusBar (LibraryWindow lw) {
        
        this.lw = lw;
        
        /* Build the toolbar */
        
        var add_playlist_image = Icons.render_image ("list-add-symbolic", Gtk.IconSize.MENU);
        var shuffle_on_image   = Icons.SHUFFLE_ON.render_image (Gtk.IconSize.MENU);
        var shuffle_off_image  = Icons.SHUFFLE_OFF.render_image (Gtk.IconSize.MENU);
        var repeat_on_image    = Icons.REPEAT_ON.render_image (Gtk.IconSize.MENU);
        var repeat_one_image    = Icons.REPEAT_ONE.render_image (Gtk.IconSize.MENU);
        var repeat_off_image   = Icons.REPEAT_OFF.render_image (Gtk.IconSize.MENU);
        var info_panel_show    = Icons.PANE_SHOW_SYMBOLIC.render_image (Gtk.IconSize.MENU);
        var info_panel_hide    = Icons.PANE_HIDE_SYMBOLIC.render_image (Gtk.IconSize.MENU);
        var eq_show_image      = Icons.EQ_SYMBOLIC.render_image (Gtk.IconSize.MENU);
        var eq_hide_image      = Icons.EQ_SYMBOLIC.render_image (Gtk.IconSize.MENU);

        addPlaylistChooser = new SimpleOptionChooser ();
        shuffleChooser     = new SimpleOptionChooser();
        repeatChooser      = new SimpleOptionChooser ();
        info_panel_chooser = new SimpleOptionChooser ();
        eq_option_chooser  = new SimpleOptionChooser ();

        addPlaylistChooser.margin_right = 12;
        addPlaylistChooser.appendItem ("", add_playlist_image, _("Add Playlist"));
        addPlaylistChooser.setOption (0);

        repeatChooser.appendItem (_("Off"), repeat_off_image, _("Enable Repeat"));
        repeatChooser.appendItem (_("Song"), repeat_one_image, _("Repeat Song"));
        repeatChooser.appendItem (_("Album"), repeat_on_image, _("Repeat Album"));
        repeatChooser.appendItem (_("Artist"), repeat_on_image, _("Repeat Artist"));
        repeatChooser.appendItem (_("All"), repeat_on_image, _("Repeat All"));
        repeatChooser.setOption (Settings.Main.instance.repeat_mode);

        shuffleChooser.appendItem (_("Off"), shuffle_off_image, _("Enable Shuffle"));
        shuffleChooser.appendItem (_("All"), shuffle_on_image, _("Disable Shuffle"));
        shuffleChooser.setOption (Settings.Main.instance.shuffle_mode);

        info_panel_chooser.appendItem (_("Hide"), info_panel_show, _("Show Info Panel"));
        info_panel_chooser.appendItem (_("Show"), info_panel_hide, _("Hide Info Panel"));
        info_panel_chooser.setOption (Settings.SavedState.instance.more_visible ? 1 : 0);

        eq_option_chooser.appendItem (_("Hide"), eq_hide_image, _("Show Equalizer"));
        eq_option_chooser.appendItem (_("Show"), eq_show_image, _("Hide Equalizer"));
        eq_option_chooser.setOption (0);
        
        insert_widget (addPlaylistChooser, true);
        insert_widget (shuffleChooser, true);
        insert_widget (repeatChooser, true);
        insert_widget (eq_option_chooser);
        insert_widget (info_panel_chooser);
        
        /* Handle Signal */
        
        addPlaylistChooser.button_press_event.connect(addPlaylistChooserOptionClicked);
        eq_option_chooser.option_changed.connect(eq_option_chooser_clicked);

        repeatChooser.option_changed.connect(repeatChooserOptionChanged);
        shuffleChooser.option_changed.connect(shuffleChooserOptionChanged);
        info_panel_chooser.option_changed.connect(info_panel_chooserOptionChanged);

        if(App.player.media_active) {
            if(Settings.Main.instance.shuffle_mode == Player.Shuffle.ALL) {
                App.player.setShuffleMode(Player.Shuffle.ALL, true);
            }
        }
        
        
    }
    public void set_info (string message)
    {
        set_text (message);
    }

    public virtual void repeatChooserOptionChanged(int val) {
        Settings.Main.instance.repeat_mode = val;

        if(val == 0)
            App.player.repeat = Player.Repeat.OFF;
        else if(val == 1)
            App.player.repeat = Player.Repeat.MEDIA;
        else if(val == 2)
            App.player.repeat = Player.Repeat.ALBUM;
        else if(val == 3)
            App.player.repeat = Player.Repeat.ARTIST;
        else if(val == 4)
            App.player.repeat = Player.Repeat.ALL;
    }

    public virtual void shuffleChooserOptionChanged(int val) {
        if(val == 0)
            App.player.setShuffleMode(Player.Shuffle.OFF, true);
        else if(val == 1)
            App.player.setShuffleMode(Player.Shuffle.ALL, true);
    }

    public virtual bool addPlaylistChooserOptionClicked(Gdk.EventButton event) {
        if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == 1) {
            lw.sideTree.playlistMenuNewClicked();
            return true;
        }

        return false;
    }


    private Gtk.Window? equalizer_window = null;

    public virtual void eq_option_chooser_clicked (int val) {
        if (equalizer_window == null && val == 1) {
            equalizer_window = new EqualizerWindow (lw.library_manager, lw);
            equalizer_window.show_all ();
            equalizer_window.destroy.connect ( () => {
                // revert the option to "Hide equalizer" after the window is destroyed
                eq_option_chooser.setOption (0);
            });
        }
        else if (val == 0 && equalizer_window != null) {
            equalizer_window.destroy ();
            equalizer_window = null;
        }
    }


    public virtual void info_panel_chooserOptionChanged (int val) {
        lw.info_panel.set_visible (val == 1);
        Settings.SavedState.instance.more_visible = (val == 1);
    }

}

