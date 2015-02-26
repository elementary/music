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
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

namespace Noise.PlaylistsUtils {

    public bool save_playlist_m3u (Playlist p, string folder_uri, string without_path) {
        bool rv = false;
        string to_save = get_playlist_m3u_file (p, without_path);
        
        File dest = GLib.File.new_for_uri(folder_uri + "/" + p.name.replace("/", "_") + ".m3u");
        try {
            // find a file path that doesn't exist
            if (dest.query_exists ()) {
                int i = 2;
                while((dest = GLib.File.new_for_uri (folder_uri + "/" + p.name.replace("/", "_") + "(%d)".printf (i) + ".m3u")).query_exists()) {
                    i++;
                }
            }
            
            var file_stream = dest.create(FileCreateFlags.NONE);
            
            // Write text data to file
            var data_stream = new DataOutputStream (file_stream);
            data_stream.put_string(to_save);
            rv = true;
        }
        catch(Error err) {
            warning ("Could not save playlist %s to m3u file %s: %s\n", p.name, dest.get_path(), err.message);
        }
        
        return rv;
    }

    public string get_playlist_m3u_file (Playlist p, string without_path) {
        string to_save = "#EXTM3U";
        
        foreach(var s in p.medias) {
            if (s == null)
                continue;

            to_save += "\n\n#EXTINF:" + s.length.to_string() + ", " + s.artist + " - " + s.title + "\n" + File.new_for_uri(s.uri).get_path();
            to_save = to_save.replace (without_path, "");
        }
        
        return to_save;
    }
    
    public bool save_playlist_pls(Playlist p, string folder_uri) {
        bool rv = false;
        string to_save = "[playlist]\nX-GNOME-Title=%s\nNumberOfEntries=%d\nVersion=2".printf (p.name, p.medias.size);
        
        int index = 1;
        foreach(var s in p.medias) {
            if (s == null)
                continue;
            
            to_save += "\n\nFile%d=%s".printf (index, s.uri.replace (folder_uri, ""));
            to_save += "\nTitle%d=%s".printf (index, s.title);
            to_save += "\nLength%d=%u".printf (index, s.length);
            ++index;
        }
        
        File dest = GLib.File.new_for_uri(folder_uri + "/" + p.name.replace("/", "_") + ".pls");
        try {
            // find a file path that doesn't exist
            int extra = 2;
            if (dest.query_exists() == true) {
                while((dest = GLib.File.new_for_uri(folder_uri + "/" + 
                            _("%s (%d)").printf (p.name.replace("/", "_"), extra) + ".pls")).query_exists()) {
                    extra++;
                }
            }
            
            var file_stream = dest.create(FileCreateFlags.NONE);
            
            // Write text data to file
            var data_stream = new DataOutputStream (file_stream);
            data_stream.put_string(to_save);
            rv = true;
        }
        catch(Error err) {
            warning ("Could not save playlist %s to pls file %s: %s\n", p.name, dest.get_path(), err.message);
        }
        
        return rv;
    }

    public static bool parse_paths_from_m3u(string uri, ref Gee.LinkedList<string> locals) {
        // now try and load m3u file
        // if some files are not found by media_from_file(), ask at end if user would like to import the file to library
        // if so, just do import_individual_files
        // if not, do nothing and accept that music files are scattered.
        
        var file = File.new_for_uri(uri);
        if(!file.query_exists()) {
            critical ("The imported playlist doesn't exist !");
            return false;
        }
        
        try {
            string line;
            string previous_line = "";
            var dis = new DataInputStream(file.read());
            
            while ((line = dis.read_line(null)) != null) {
                if(line[0] != '#' && line.replace(" ", "").length > 0) {
                    warning ("file://" + line);
                    locals.add("file://" + line);
                }
                
                previous_line = line;
            }
        }
        catch(Error err) {
            warning ("Could not load m3u file at %s: %s\n", uri, err.message);
            return false;
        }
        
        return true;
    }

    public static bool parse_paths_from_pls(string uri, ref Gee.LinkedList<string> locals, ref string title) {
        var files = new Gee.HashMap<int, string>();
        var titles = new Gee.HashMap<int, string>();
        var lengths = new Gee.HashMap<int, string>();
        
        var file = File.new_for_uri(uri);
        if(!file.query_exists())
            return false;
        
        
        try {
            string line;
            var dis = new DataInputStream(file.read());
            
            while ((line = dis.read_line(null)) != null) {
                if(line.has_prefix("File")) {
                    parse_index_and_value("File", line, ref files);
                } else if(line.has_prefix("X-GNOME-Title")) {
                    string[] parts = line.split("=", 2);
                    title = parts[1];
                } else if(line.has_prefix("Title")) {
                    parse_index_and_value("Title", line, ref titles);
                } else if(line.has_prefix("Length")) {
                    parse_index_and_value("Length", line, ref lengths);
                }
            }
        }
        catch(Error err) {
            warning ("Could not load m3u file at %s: %s\n", uri, err.message);
            return false;
        }
        locals.add_all(files.values);
        
        
        return true;
    }

    public static void parse_index_and_value(string prefix, string line, ref Gee.HashMap<int, string> map) {
        int index;
        string val;
        string[] parts = line.split("=", 2);
        
        index = int.parse(parts[0].replace(prefix,""));
        val = parts[1];
        
        map.set(index, val);
    }
    
    private Gee.Collection<string> convert_paths_to_uris (Gee.Collection<string> paths) {
        var uris = new Gee.TreeSet<string> ();
        foreach (var path in paths) {
            uris.add (File.new_for_path (path).get_uri ());
        }

        return uris;
    }
    
    public void import_from_playlist_file_info(Gee.HashMap<string, Gee.LinkedList<string>> playlists, Library library) {
        
        foreach (var values in playlists.values) {
            if (values.size > 0) {
                if (values.get (0).has_prefix ("/")) {
                    library.add_files_to_library (convert_paths_to_uris (values));
                } else {
                    library.add_files_to_library (values);
                }
            }
        }
        
        foreach (var playlist in playlists.entries) {
            var new_playlist = new StaticPlaylist();
            new_playlist.name = playlist.key;
            var medias_to_use = playlist.value;
            var to_add = new Gee.LinkedList<Media> ();
            foreach (var media in library.get_medias ()) {
                if (medias_to_use.contains (media.file.get_path()) || medias_to_use.contains (media.file.get_uri())) {
                    to_add.add (media);
                }
            }
            new_playlist.add_medias (to_add);
            library.add_playlist (new_playlist);
        }
    }

    public static string get_new_playlist_name (Gee.Collection<Playlist> playlists, string? name = null) {
        string base_name;
        if (name == null)
            base_name = _("New playlist");
        else
            base_name = name;
        bool is_fine = true;
        int index =2;
        string new_name = base_name;
        while (is_fine) {
            bool found = false;
            foreach (var p in playlists) {
                if (p.name == new_name) {
                    // Translators: used for new playlists ex: "New playlist (1)"
                    new_name = _("%s (%i)").printf (base_name, index);
                    index++;
                    found = true;
                    break;
                }
            }
            if (found == false) {
                is_fine = false;
            }
        }
        return new_name;
    }

    public StaticPlaylist static_playlist_from_smartplaylist (SmartPlaylist sp) {
        var p = new StaticPlaylist();
        p.add_medias (sp.medias);
        p.name = sp.name;
        return p;
    }

    public void export_playlist (Playlist p) {
        if(p == null)
            return;
        
        string file = "";
        string name = "";
        string extension = "";
        var file_chooser = new Gtk.FileChooserDialog (_("Export Playlist"), null,
                                  Gtk.FileChooserAction.SAVE,
                                  _(STRING_CANCEL), Gtk.ResponseType.CANCEL,
                                  _(STRING_SAVE), Gtk.ResponseType.ACCEPT);
        
        // filters for .m3u and .pls
        var m3u_filter = new Gtk.FileFilter();
        m3u_filter.add_pattern("*.m3u");
        m3u_filter.set_filter_name(_("MPEG Version 3.0 Extended (*.m3u)"));
        file_chooser.add_filter(m3u_filter);
        
        var pls_filter = new Gtk.FileFilter();
        pls_filter.add_pattern("*.pls");
        pls_filter.set_filter_name(_("Shoutcast Playlist Version 2.0 (*.pls)"));
        file_chooser.add_filter(pls_filter);
        
        file_chooser.do_overwrite_confirmation = true;
        file_chooser.set_current_name(p.name + ".m3u");
        
        // set original folder. if we don't, then file_chooser.get_filename() starts as null, which is bad for signal below.
        var main_settings = Settings.Main.get_default ();
        if(File.new_for_path(main_settings.music_folder).query_exists())
            file_chooser.set_current_folder(main_settings.music_folder);
        else
            file_chooser.set_current_folder(Environment.get_home_dir());
            
        
        // listen for filter change
        file_chooser.notify["filter"].connect( () => {
            if(file_chooser.get_filename() == null) // happens when no folder is chosen. need way to get textbox text, rather than filename
                return;
            
            if(file_chooser.filter == m3u_filter) {
                message ("changed to m3u\n");
                var new_file = file_chooser.get_filename().replace(".pls", ".m3u");
                
                if(new_file.slice(new_file.last_index_of(".", 0), new_file.length).length == 0) {
                    new_file += ".m3u";
                }
                
                file_chooser.set_current_name(new_file.slice(new_file.last_index_of("/", 0) + 1, new_file.length));
            }
            else {
                message ("changed to pls\n");
                var new_file = file_chooser.get_filename().replace(".m3u", ".pls");
                
                if(new_file.slice(new_file.last_index_of(".", 0), new_file.length).length == 0) {
                    new_file += ".pls";
                }
                
                file_chooser.set_current_name(new_file.slice(new_file.last_index_of("/", 0) + 1, new_file.length));
            }
        });
        
        if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {
            file = file_chooser.get_filename();
            extension = file.slice(file.last_index_of(".", 0), file.length);
            
            if(extension.length == 0 || extension[0] != '.') {
                extension = (file_chooser.filter == m3u_filter) ? ".m3u" : ".pls";
                file += extension;
            }
            
            name = file.slice(file.last_index_of("/", 0) + 1, file.last_index_of(".", 0));
            message ("name is %s extension is %s\n", name, extension);
        }
        
        file_chooser.destroy ();
        
        string original_name = p.name;
        if(file != "") {
            var f = File.new_for_path(file);
            
            string folder = f.get_parent().get_uri();
            p.name = name; // temporary to save
            
            if(file.has_suffix(".m3u"))
                save_playlist_m3u(p, folder, "");
            else
                save_playlist_pls(p, folder);
        }
        
        p.name = original_name;
    }

    public Gee.HashMap<string, Gee.LinkedList<string>> get_playlists_to_import (string? set_title = "Playlist") throws GLib.Error {
        string title = set_title;
        if (set_title == null || set_title == "") {
            title = _("Playlist");
        }
        var files = new SList<string> ();
        var playlists = new Gee.HashMap<string, Gee.LinkedList<string>> ();
        bool success = false;

        var file_chooser = new Gtk.FileChooserDialog (_("Import %s").printf (title), null,
                                  Gtk.FileChooserAction.OPEN,
                                  _(STRING_CANCEL), Gtk.ResponseType.CANCEL,
                                  _(STRING_OPEN), Gtk.ResponseType.ACCEPT);
        file_chooser.set_select_multiple (true);
        
        // filters for .m3u and .pls
        var m3u_filter = new Gtk.FileFilter();
        m3u_filter.add_pattern("*.m3u");
        m3u_filter.set_filter_name(_("MPEG Version 3.0 Extended (*.m3u)"));
        file_chooser.add_filter(m3u_filter);
        
        var pls_filter = new Gtk.FileFilter();
        pls_filter.add_pattern("*.pls");
        pls_filter.set_filter_name(_("Shoutcast Playlist Version 2.0 (*.pls)"));
        file_chooser.add_filter(pls_filter);
        
        if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {
            files = file_chooser.get_filenames();
        }
        file_chooser.destroy ();
        
        foreach (var file in files) {
            if(file != "") {
                var name = GLib.File.new_for_path (file).get_basename ();
                var paths = new Gee.LinkedList<string> ();
                if (file.has_suffix(".m3u")) {
                    name = name.replace (".m3u", "");
                    success = parse_paths_from_m3u("file://" + file, ref paths);
                } else if(file.has_suffix(".pls")) {
                    name = name.replace (".pls", "");
                    success = parse_paths_from_pls("file://" + file, ref paths, ref name);
                } else {
                    success = false;
                    throw new GLib.Error (GLib.Quark.from_string ("not-recognized"), 1, "%s", _("Unrecognized playlist file. Import failed."));
                }
                playlists.set (name, paths);
            }
        }
        
        return playlists;
    }

}
