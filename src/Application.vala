/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.Application : Gtk.Application {
    public Application () {
        Object (
            application_id: "io.elementary.music",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        MediaKeyListener.get_default ();

        var main_window = new MainWindow () {
            application = this,
            title = _("Music")
        };
        main_window.show_all ();

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = (
            granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
        );

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = (
                granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
            );
        });
    }

    public static int main (string[] args) {
        return new Music.Application ().run (args);
    }
}
