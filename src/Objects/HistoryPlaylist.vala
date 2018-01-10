// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2017 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Noise.HistoryPlaylist : StaticPlaylist {
    Zeitgeist.Log log;
    const int HISTORY_LIMIT = 100;

    public HistoryPlaylist () {
        get_history.begin ();
    }

    construct {
        name = _("History");
        read_only = true;
        icon = new ThemedIcon ("document-open-recent");
        log = Zeitgeist.Log.get_default ();
    }

    public override void add_media (Media m) {
        base.add_media (m);
        log_interaction.begin (m);
    }

    public override void add_medias (Gee.Collection<Media> to_add) {
        base.add_medias (to_add);
        foreach (var m in to_add) {
            log_interaction.begin (m);
        }
    }

    private async void log_interaction (Media song) {
        var time = new DateTime.now_local ().to_unix () * 1000;

        FileInfo? info = null;
        try {
            info = yield song.file.query_info_async (FileAttribute.STANDARD_CONTENT_TYPE, 0);
        } catch (Error e) {
            critical (e.message);
        }

        var subject = new Zeitgeist.Subject ();
        subject.uri = song.uri;
        subject.interpretation = Zeitgeist.NFO.AUDIO;
        subject.manifestation = Zeitgeist.NFO.FILE_DATA_OBJECT;
        subject.origin = song.get_display_location ();
        subject.mimetype = info != null ? info.get_content_type () : null;
        subject.text = "%s - %s - %s".printf (song.get_display_title (),
                song.get_display_artist (), song.get_display_album ());

        var event = new Zeitgeist.Event ();
        event.timestamp = time;
        event.interpretation = Zeitgeist.ZG.ACCESS_EVENT;
        event.manifestation = Zeitgeist.ZG.USER_ACTIVITY;
        event.actor = "application://io.elementary.music.desktop";
        event.add_subject (subject);

        try {
            log.insert_event_no_reply (event);
        } catch (Error e) {
            warning ("Logging to zeitgeist failed: %s", e.message);
        }
    }

    private async void get_history () {
        var timerange = new Zeitgeist.TimeRange.anytime ();
        var event_templates = new GLib.GenericArray<Zeitgeist.Event> ();

        var z_subject = new Zeitgeist.Subject ();
        z_subject.interpretation = Zeitgeist.NFO.AUDIO;
        z_subject.manifestation = Zeitgeist.NFO.FILE_DATA_OBJECT;

        var z_event = new Zeitgeist.Event ();
        z_event.interpretation = Zeitgeist.ZG.ACCESS_EVENT;
        z_event.manifestation = Zeitgeist.ZG.USER_ACTIVITY;
        z_event.add_subject (z_subject);

        event_templates.add (z_event);
        var added_media = new Gee.LinkedList<Media> ();
        var new_medias = new Gee.ArrayQueue<Media>();

        try {
            var events = yield log.find_events (timerange, event_templates, Zeitgeist.StorageState.ANY, 0, Zeitgeist.ResultType.MOST_RECENT_EVENTS, null);
            foreach (var event in events) {
                for (int i = 0; new_medias.size < HISTORY_LIMIT && i < event.subjects.length; i++) {
                    Zeitgeist.Subject subject = event.subjects.get (i);

                    var m = libraries_manager.local_library.media_from_uri (subject.uri);
                    if (m == null)
                        continue;

                    if (allow_duplicate || (medias.contains (m) == false && new_medias.contains (m) == false)) {
                        new_medias.add (m);
                    }
                }

                if (new_medias.size >= HISTORY_LIMIT) {
                    break;
                }
            }

            var media = new_medias.poll_tail ();
            while (media != null) {
                medias.add (media);
                added_media.add (media);
                media = new_medias.poll_tail ();
            }

            updated ();
            media_added (added_media);
        } catch (Error e) {
            critical (e.message);
        }
    }
}

/*
 * Handle Incognito Mode
 */

namespace SecurityPrivacy {
    private const string SIG_EVENT = "asaasay";
    private const string SIG_BLACKLIST = "a{s("+SIG_EVENT+")}";

    [DBus (name = "org.gnome.zeitgeist.Blacklist")]
    interface BlacklistInterface : Object {
        public signal void template_added (string blacklist_id, [DBus (signature = "(asaasay)")] Variant blacklist_template);
        public signal void template_removed (string blacklist_id, [DBus (signature = "(asaasay)")] Variant blacklist_template);

        [DBus (signature = "a{s(asaasay)}")]
        public abstract Variant get_templates () throws IOError;
        public abstract void add_template (string blacklist_id, [DBus (signature = "(asaasay)")] Variant blacklist_template) throws IOError;
        public abstract void remove_template (string blacklist_id) throws IOError;
    }

    public class Blacklist {

        private BlacklistInterface blacklist;
        private HashTable<string, Zeitgeist.Event> blacklists;
        private Zeitgeist.Log log;

        // Incognito
        private string incognito_id = "block-all";
        private Zeitgeist.Event incognito_event;

        public Blacklist () {
            try {
                blacklist = Bus.get_proxy_sync (BusType.SESSION, "org.gnome.zeitgeist.Engine", "/org/gnome/zeitgeist/blacklist");
                blacklist.template_added.connect (on_template_added);
                blacklist.template_removed.connect (on_template_removed);
            } catch (Error e) {
                error (e.message);
            }
            log = new Zeitgeist.Log ();
            incognito_event = new Zeitgeist.Event ();
        }

        public HashTable<string, Zeitgeist.Event> all_templates {
            get {
                if (blacklists == null)
                    this.get_templates ();
                return blacklists;
            }
        }

        public signal void template_added (string blacklist_id, Zeitgeist.Event blacklist_template);
        public signal void template_removed (string blacklist_id, Zeitgeist.Event blacklist_template);
        public signal void incognito_toggled (bool status);

        public void add_template (string blacklist_id, Zeitgeist.Event blacklist_template) {
            try {
                blacklist.add_template (blacklist_id, blacklist_template.to_variant());
            } catch (Error e) {
                critical (e.message);
            }
        }

        public void remove_template (string blacklist_id) {
            try {
                blacklist.remove_template (blacklist_id);
            } catch (Error e) {
                critical (e.message);
            }
        }

        // If status is true, means we want incognito to be set
        public void set_incognito (bool status) {
            if (status)
                this.add_template (incognito_id, incognito_event);
            else
                this.remove_template (incognito_id);
        }

        public HashTable<string, Zeitgeist.Event> get_templates () {
            try {
                Variant var_blacklists = blacklist.get_templates ();
                blacklists = from_variant (var_blacklists);
                return blacklists;
            } catch (Error e) {
                critical (e.message);
                return new HashTable<string, Zeitgeist.Event> (null, null);
            }
        }

        private void on_template_added (string blacklist_id, Variant blacklist_template) {
            try {
                var ev = new Zeitgeist.Event.from_variant (blacklist_template);
                template_added (blacklist_id, ev);
                if (blacklist_id == incognito_id)
                    incognito_toggled (true);

                blacklists.insert (blacklist_id, ev);
            } catch (Error e) {
                critical (e.message);
            }
        }

        private void on_template_removed (string blacklist_id, Variant blacklist_template) {
            try {
                var ev = new Zeitgeist.Event.from_variant (blacklist_template);
                template_removed (blacklist_id, ev);
            } catch (Error e) {
                critical (e.message);
            }

            if (blacklist_id == incognito_id)
                incognito_toggled (false);

            if (blacklists.lookup (blacklist_id) != null)
                blacklists.remove (blacklist_id);
        }

        public bool get_incognito () {
            if (blacklists == null)
                this.get_templates ();

            foreach (var ev in all_templates.get_values ()) {
                if (matches_event_template (ev, incognito_event))
                    return true;
            }

            return false;
        }

        public async void find_events (string id, Gtk.TreeIter iter, Gtk.ListStore store) {
            var event = new Zeitgeist.Event ();
            event.manifestation = Zeitgeist.ZG.USER_ACTIVITY;
            event.actor = "application://%s".printf (id);

            var events = new GenericArray<Zeitgeist.Event> ();
            events.add (event);

            var event2 = new Zeitgeist.Event ();
            event2.manifestation = Zeitgeist.ZG.USER_ACTIVITY;
            var subj = new Zeitgeist.Subject ();
            subj.uri = "application://%s".printf (id);
            event2.add_subject (subj);

            events.add (event2);

            try {
                uint32[] results = yield log.find_event_ids (new Zeitgeist.TimeRange.anytime (),
                                                    events,
                                                    Zeitgeist.StorageState.ANY,
                                                    0,
                                                    Zeitgeist.ResultType.MOST_RECENT_EVENTS,
                                                    null);

                var counter = results.length/100;
                store.set_value (iter, 5, counter);
            } catch (Error e) {
                warning (e.message);
            }
        }

        public void get_count_for_app (string app_id, Gtk.TreeIter iter, Gtk.ListStore store) {
            find_events.begin (app_id, iter, store);
        }
    }

    public class FileTypeBlacklist {
        public static string interpretation_prefix = "interpretation-";

        private Blacklist blacklist_interface;
        private Gee.HashSet<string> all_blocked_filetypes;

        public Gee.HashSet<string> all_filetypes {
            get {
                return all_blocked_filetypes;
            }
        }

        public FileTypeBlacklist (Blacklist blacklist_inter) {
            blacklist_interface = blacklist_inter;
            this.blacklist_interface.template_added.connect (on_blacklist_added);
            this.blacklist_interface.template_removed.connect (on_blacklist_removed);
            all_blocked_filetypes = new Gee.HashSet<string> ();
            populate_file_types ();
        }

        private string get_name (string interpretation) {
            var names = interpretation.split ("#");
            var name = names[names.length-1].down ();
            return "%s%s".printf (interpretation_prefix, name);
        }

        private void populate_file_types () {
            foreach (string key in blacklist_interface.all_templates.get_keys ()) {
                if (key.has_prefix (interpretation_prefix)) {
                    var inter = blacklist_interface.all_templates[key].get_subject (0).interpretation;
                    all_blocked_filetypes.add (inter);
                }
            }
        }

        public void block (string interpretation) {
            var ev = new Zeitgeist.Event ();
            var sub = new Zeitgeist.Subject ();
            sub.interpretation = interpretation;
            ev.add_subject (sub);
            blacklist_interface.add_template (this.get_name (interpretation), ev);
        }

        public void unblock (string interpretation) {
            blacklist_interface.remove_template (this.get_name(interpretation));
        }

        private void on_blacklist_added (string blacklist_id, Zeitgeist.Event ev) {
            if (blacklist_id.has_prefix (interpretation_prefix)) {
                all_blocked_filetypes.add (ev.get_subject (0).interpretation);
            }
        }

        private void on_blacklist_removed (string blacklist_id, Zeitgeist.Event ev) {
            if (blacklist_id.has_prefix (interpretation_prefix)) {
                var inter = ev.get_subject (0).interpretation;
                if (all_blocked_filetypes.contains (inter) == true) {
                    all_blocked_filetypes.remove (ev.get_subject (0).interpretation);
                }
            }
        }
    }

    public class PathBlacklist {
        public signal void folder_added (string path);
        public signal void folder_removed (string path);

        public static string folder_prefix = "dir-";
        private static string suffix = "/*";

        private Blacklist blacklist_interface;
        private Gee.HashSet<string> all_blocked_folder;

        public PathBlacklist (Blacklist blacklist_inter) {
            blacklist_interface = blacklist_inter;
            this.blacklist_interface.template_added.connect (on_blacklist_added);
            this.blacklist_interface.template_removed.connect (on_blacklist_removed);
            this.get_blocked_folder ();
        }

        public Gee.HashSet<string> all_folders {
            get {
                return all_blocked_folder;
            }
        }

        public bool is_duplicate (string path) {
            return all_blocked_folder.contains (path);
        }

        private void get_blocked_folder () {
            all_blocked_folder = new Gee.HashSet<string> ();
            foreach (string key in blacklist_interface.all_templates.get_keys()) {
                if (key.has_prefix (folder_prefix) == true) {
                    string folder = get_folder (blacklist_interface.all_templates.get (key));
                    if (folder != null)
                        all_blocked_folder.add (folder);
                }
            }
        }

        private void on_blacklist_added (string blacklist_id, Zeitgeist.Event ev) {
            if (blacklist_id.has_prefix (folder_prefix)) {
                string uri = get_folder (ev);
                if (uri != null) {
                    folder_added (uri);
                    if (all_blocked_folder.contains (uri) == false)
                        all_blocked_folder.add (uri);
                }
            }
        }

        private void on_blacklist_removed (string blacklist_id, Zeitgeist.Event ev) {
            if (blacklist_id.has_prefix (folder_prefix)) {
                string uri = get_folder (ev);
                if (uri != null) {
                    folder_removed (uri);
                    if (all_blocked_folder.contains (uri) == true)
                        all_blocked_folder.remove (uri);
                }
            }
        }

        private string? get_folder (Zeitgeist.Event ev) {
            Zeitgeist.Subject sub = ev.get_subject(0);
            string uri = sub.uri.replace (suffix, "");
            var blocked_uri = File.new_for_uri (uri);
            if (blocked_uri.query_exists (null) == true)
                return blocked_uri.get_path ();

            return null;
        }

        public void block (string folder) {
            var ev = new Zeitgeist.Event ();
            var sub = new Zeitgeist.Subject ();

            var block_path = File.new_for_path (folder);
            string uri = "%s%s".printf (block_path.get_uri (), suffix);
            sub.uri = uri;
            ev.add_subject (sub);

            blacklist_interface.add_template ("%s%s".printf (folder_prefix, folder), ev);

            if (all_blocked_folder.contains (folder) == false)
                all_blocked_folder.add (folder);
        }

        public void unblock (string folder) {
            blacklist_interface.remove_template ("%s%s".printf (folder_prefix, folder));
            if (all_blocked_folder.contains (folder) == true)
                all_blocked_folder.remove (folder);
        }
    }

    public class ApplicationBlacklist {
        public static string interpretation_prefix = "app-";
        public static string launcher_prefix = "launch-";

        public signal void application_added (string app, Zeitgeist.Event ev);
        public signal void application_removed (string app, Zeitgeist.Event ev);

        private Blacklist blacklist_interface;
        private Gee.HashSet<string> all_blocked_apps;

        public ApplicationBlacklist (Blacklist blacklist) {
            this.blacklist_interface = blacklist;
            this.blacklist_interface.template_added.connect (on_blacklist_added);
            this.blacklist_interface.template_removed.connect (on_blacklist_removed);
            this.get_blocked_apps();
        }

        public Gee.HashSet<string> all_apps {
            get {
                return all_blocked_apps;
            }
        }

        public void get_count_for_app (string id, Gtk.TreeIter iter, Gtk.ListStore store) {
            this.blacklist_interface.get_count_for_app(id, iter, store);
        }

        private Gee.HashSet<string> get_blocked_apps () {
            all_blocked_apps = new Gee.HashSet<string>();
            foreach (string key in blacklist_interface.all_templates.get_keys()) {
                if (key.has_prefix (interpretation_prefix) == true) {
                    var app = key.substring (4);
                    all_blocked_apps.add (app);
                }
            }

            return all_blocked_apps;
        }

        private void on_blacklist_added (string blacklist_id, Zeitgeist.Event ev) {
            if (blacklist_id.has_prefix (interpretation_prefix) == true) {
                string app = blacklist_id.substring (4);
                application_added (app, ev);
                if (all_apps.contains(app) == false)
                    all_apps.add(app);
            }
        }

        private void on_blacklist_removed (string blacklist_id, Zeitgeist.Event ev) {
            if (blacklist_id.has_prefix (interpretation_prefix) == true) {
                string app = blacklist_id.substring (4);
                application_removed (app, ev);
                if (all_apps.contains(app) == true)
                    all_apps.remove (app);
            }
        }
    }

    public static bool matches_event_template (Zeitgeist.Event event, Zeitgeist.Event template_event) {
        if (!check_field_match (event.interpretation, template_event.interpretation, "ev-int"))
            return false;
        //Check if manifestation is child of template_event or same
        if (!check_field_match (event.manifestation, template_event.manifestation, "ev-mani"))
            return false;
        //Check if actor is equal to template_event actor
        if (!check_field_match (event.actor, template_event.actor, "ev-actor"))
            return false;

        if (event.num_subjects () == 0)
            return true;

        for (int i = 0; i < event.num_subjects (); i++) {
            for (int j = 0; j < template_event.num_subjects (); j++) {
                if (matches_subject_template (event.get_subject (i), template_event.get_subject (j)))
                    return true;
            }
        }

        return false;
    }

    public static bool matches_subject_template (Zeitgeist.Subject subject, Zeitgeist.Subject template_subject) {
        if (!check_field_match (subject.uri, template_subject.uri, "sub-uri"))
            return false;
        if (!check_field_match (subject.interpretation, template_subject.interpretation, "sub-int"))
            return false;
        if (!check_field_match (subject.manifestation, template_subject.manifestation, "sub-mani"))
            return false;
        if (!check_field_match (subject.origin, template_subject.origin, "sub-origin"))
            return false;
        if (!check_field_match (subject.mimetype, template_subject.mimetype, "sub-mime"))
            return false;

        return true;
    }

    private static bool check_field_match (string? property, string? template_property, string property_name = "") {
        var matches = false;
        var parsed = template_property;
        var is_negated = template_property != null? parse_negation (ref parsed): false;
        if (parsed == "") {
            return true;
        } else if (parsed == property) {
            matches = true;
        }

        return (is_negated) ? !matches : matches;
    }

    public static bool parse_negation (ref string val) {
        if (!val.has_prefix ("!"))
            return false;
        val = val.substring (1);
        return true;
    }

    public static HashTable<string, Zeitgeist.Event> from_variant (Variant templates_variant) {
        var blacklist = new HashTable<string, Zeitgeist.Event> (str_hash, str_equal);
        foreach (Variant template_variant in templates_variant) {
            VariantIter iter = template_variant.iterator ();
            string template_id = iter.next_value ().get_string ();
            var ev_variant = iter.next_value ();
            if (ev_variant != null) {
                try {
                    Zeitgeist.Event template = new Zeitgeist.Event.from_variant (ev_variant);
                    blacklist.insert (template_id, template);
                } catch (Error e) {
                    warning (e.message);
                }
            }
        }

        return blacklist;
    }
}
