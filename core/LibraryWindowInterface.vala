/*-
 * Copyright (c) 2012 Lucas Baudin <xapantu@gmail.com>
 *
 * Originally Written by Lucas Baudin for BeatBox Music Player
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

public interface Noise.LibraryWindowInterface : Object {
    public abstract void updateInfoLabel ();
    public abstract void progressNotification(string? message, double progress);
    public abstract async void update_sensitivities ();
    public signal void add_preference_page (Noise.SettingsWindow.NoteBook_Page widget);
    public signal void source_list_added (GLib.Object o, int view_number);
    public signal void media_as_played (Media m);
}
