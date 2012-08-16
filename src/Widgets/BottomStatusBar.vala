
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

        repeatChooser      = new RepeatChooser ();
        shuffleChooser     = new ShuffleChooser ();
        addPlaylistChooser = new AddPlaylistChooser ();
        eq_option_chooser  = new EqualizerChooser ();
        info_panel_chooser = new InfoPanelChooser ();

        insert_widget (addPlaylistChooser, true);
        insert_widget (shuffleChooser, true);
        insert_widget (repeatChooser, true);
        insert_widget (eq_option_chooser);
        insert_widget (info_panel_chooser);

/* XXX
        if(App.player.media_active) {
            if(Settings.Main.instance.shuffle_mode == Player.Shuffle.ALL) {
                App.player.setShuffleMode(Player.Shuffle.ALL, true);
            }
        }
*/        
    }


    public void set_info (string message)
    {
        set_text (message);
    }
}



/********************
 * STATUSBAR ITEMS  *
 ********************/


private class Noise.RepeatChooser : Noise.SimpleOptionChooser {

    public RepeatChooser () {
        var repeat_on_image    = Icons.REPEAT_ON.render_image (Gtk.IconSize.MENU);
        var repeat_one_image    = Icons.REPEAT_ONE.render_image (Gtk.IconSize.MENU);
        var repeat_off_image   = Icons.REPEAT_OFF.render_image (Gtk.IconSize.MENU);

        // MUST follow the exact same order of Noise.Player.Repeat
        appendItem (_("Off"), repeat_off_image, _("Enable Repeat"));
        appendItem (_("Song"), repeat_one_image, _("Repeat Song"));
        appendItem (_("Album"), repeat_on_image, _("Repeat Album"));
        appendItem (_("Artist"), repeat_on_image, _("Repeat Artist"));
        appendItem (_("All"), repeat_on_image, _("Repeat All"));

        setOption ((int)App.player.repeat);

        option_changed.connect (on_option_changed);

        App.player.notify["repeat"].connect ( () => {
            setOption ((int)App.player.repeat);
        });
    }

    private void on_option_changed () {
        int val = current_option;

        if ((int)App.player.repeat == val)
            return;

        App.player.repeat = (Noise.Player.Repeat)val;
    }
}


private class Noise.ShuffleChooser : Noise.SimpleOptionChooser {

    public ShuffleChooser () {
        var shuffle_on_image   = Icons.SHUFFLE_ON.render_image (Gtk.IconSize.MENU);
        var shuffle_off_image  = Icons.SHUFFLE_OFF.render_image (Gtk.IconSize.MENU);

        appendItem (_("Off"), shuffle_off_image, _("Enable Shuffle"));
        appendItem (_("All"), shuffle_on_image, _("Disable Shuffle"));
        setOption (Settings.Main.instance.shuffle_mode);

        setOption ((int)App.player.repeat);

        option_changed.connect (on_option_changed);

        App.player.notify["shuffle"].connect ( () => {
            setOption ((int)App.player.shuffle);
        });
    }

    private void on_option_changed () {
        int val = current_option;

        if ((int)App.player.shuffle == val)
            return;

        App.player.setShuffleMode ((Player.Shuffle)val, true);
    }
}


private class Noise.AddPlaylistChooser : Noise.SimpleOptionChooser {

    public AddPlaylistChooser () {
        base (true);

        var add_playlist_image = Icons.render_image ("list-add-symbolic", Gtk.IconSize.MENU);

        margin_right = 12;

        var tooltip = _("Add Playlist");

        appendItem (tooltip, add_playlist_image, tooltip);
        appendItem (_("Add Smart Playlist"), add_playlist_image, tooltip);

        setOption (0);

        option_changed.connect (on_option_changed);
    }

    private void on_option_changed () {
        int val = current_option;

        if (val == 0) {
            App.main_window.sideTree.playlistMenuNewClicked ();
        } else if (val == 1) {
            App.main_window.sideTree.smartPlaylistMenuNewClicked ();
        }
    }
}


private class Noise.EqualizerChooser : Noise.SimpleOptionChooser {

    private Gtk.Window? equalizer_window = null;

    public EqualizerChooser () {
        var eq_show_image = Icons.EQ_SYMBOLIC.render_image (Gtk.IconSize.MENU);
        var eq_hide_image = Icons.EQ_SYMBOLIC.render_image (Gtk.IconSize.MENU);

        appendItem (_("Hide"), eq_show_image, _("Show Equalizer"));
        appendItem (_("Show"), eq_hide_image, _("Hide Equalizer"));

        setOption (0);

        option_changed.connect (eq_option_chooser_clicked);
    }

    private void eq_option_chooser_clicked () {
        int val = current_option;

        if (equalizer_window == null && val == 1) {
            equalizer_window = new EqualizerWindow (App.library_manager, App.main_window);
            equalizer_window.show_all ();
            equalizer_window.destroy.connect ( () => {
                // revert the option to "Hide equalizer" after the window is destroyed
                setOption (0);
            });
        }
        else if (val == 0 && equalizer_window != null) {
            equalizer_window.destroy ();
            equalizer_window = null;
        }
    }
}


private class Noise.InfoPanelChooser : Noise.SimpleOptionChooser {

    public InfoPanelChooser () {
        var info_panel_show = Icons.PANE_SHOW_SYMBOLIC.render_image (Gtk.IconSize.MENU);
        var info_panel_hide = Icons.PANE_HIDE_SYMBOLIC.render_image (Gtk.IconSize.MENU);

        appendItem (_("Hide"), info_panel_show, _("Show Info Panel"));
        appendItem (_("Show"), info_panel_hide, _("Hide Info Panel"));

        on_info_panel_visibility_change ();
        App.main_window.info_panel.show.connect (on_info_panel_visibility_change);
        App.main_window.info_panel.hide.connect (on_info_panel_visibility_change);

        option_changed.connect (on_option_changed);
    }

    private void on_info_panel_visibility_change () {
        setOption (App.main_window.info_panel.visible ? 1 : 0);
    }

    private void on_option_changed () {
        int val = current_option;

        App.main_window.info_panel.set_visible (val == 1);
        Settings.SavedState.instance.more_visible = (val == 1);
    }
}
