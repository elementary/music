// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*
 * Copyright (c) 2012 Noise Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; see the file COPYING.  If not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Corentin Noël <corentin@noel.tf>
 */

namespace Noise.PlaylistsUtils {

    public bool save_playlist_m3u (Playlist p, string folder) {
        bool rv = false;
        string to_save = "#EXTM3U";
        
        foreach(var s in p.media) {
            if (s == null)
                continue;

            to_save += "\n\n#EXTINF:" + s.length.to_string() + ", " + s.artist + " - " + s.title + "\n" + File.new_for_uri(s.uri).get_path();
        }
        
        File dest = GLib.File.new_for_path(Path.build_path("/", folder, p.name.replace("/", "_") + ".m3u"));
        try {
            // find a file path that doesn't exist
            string extra = "";
            while((dest = GLib.File.new_for_path(Path.build_path("/", folder, p.name.replace("/", "_") + extra + ".m3u"))).query_exists()) {
                extra += "_";
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

    public bool save_playlist_pls(Playlist p, string folder) {
        bool rv = false;
        string to_save = "[playlist]\n\nNumberOfEntries=" + p.media.size.to_string() + "\nVersion=2";
        
        int index = 1;
        foreach(var s in p.media) {
            if (s == null)
                continue;
            
            to_save += "\n\nFile" + index.to_string() + "=" + File.new_for_uri(s.uri).get_path() + "\nTitle" + index.to_string() + "=" + s.title + "\nLength" + index.to_string() + "=" + s.length.to_string();
            ++index;
        }
        
        File dest = GLib.File.new_for_path(Path.build_path("/", folder, p.name.replace("/", "_") + ".pls"));
        try {
            // find a file path that doesn't exist
            string extra = "";
            while((dest = GLib.File.new_for_path(Path.build_path("/", folder, p.name.replace("/", "_") + extra + ".pls"))).query_exists()) {
                extra += "_";
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

    public static bool parse_paths_from_m3u(string path, ref Gee.LinkedList<string> locals) {
        // now try and load m3u file
        // if some files are not found by media_from_file(), ask at end if user would like to import the file to library
        // if so, just do import_individual_files
        // if not, do nothing and accept that music files are scattered.
        
        var file = File.new_for_path(path);
        if(!file.query_exists())
            return false;
        
        try {
            string line;
            string previous_line = "";
            var dis = new DataInputStream(file.read());
            
            while ((line = dis.read_line(null)) != null) {
                if(line[0] != '#' && line.replace(" ", "").length > 0) {
                    locals.add(line);
                }
                
                previous_line = line;
            }
        }
        catch(Error err) {
            warning ("Could not load m3u file at %s: %s\n", path, err.message);
            return false;
        }
        
        return true;
    }

    public static bool parse_paths_from_pls(string path, ref Gee.LinkedList<string> locals) {
        var files = new Gee.HashMap<int, string>();
        var titles = new Gee.HashMap<int, string>();
        var lengths = new Gee.HashMap<int, string>();
        
        var file = File.new_for_path(path);
        if(!file.query_exists())
            return false;
        
        try {
            string line;
            var dis = new DataInputStream(file.read());
            
            while ((line = dis.read_line(null)) != null) {
                if(line.has_prefix("File")) {
                    parse_index_and_value("File", line, ref files);
                }
                else if(line.has_prefix("Title")) {
                    parse_index_and_value("Title", line, ref titles);
                }
                else if(line.has_prefix("Length")) {
                    parse_index_and_value("Length", line, ref lengths);
                }
            }
        }
        catch(Error err) {
            warning ("Could not load m3u file at %s: %s\n", path, err.message);
            return false;
        }
        
        foreach(var entry in files.entries) {
            locals.add(entry.value);
        }
        
        
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

    public Playlist extract_playlist_from_smartplaylist (SmartPlaylist sp) {
        var p = new Playlist();
        p.add_media (sp.reanalyze());
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
                                  Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
                                  Gtk.Stock.SAVE, Gtk.ResponseType.ACCEPT);
        
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
            
            string folder = f.get_parent().get_path();
            p.name = name; // temporary to save
            
            if(file.has_suffix(".m3u"))
                save_playlist_m3u(p, folder);
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
                                  Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
                                  Gtk.Stock.OPEN, Gtk.ResponseType.ACCEPT);
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
                    success = parse_paths_from_m3u(file, ref paths);
                } else if(file.has_suffix(".pls")) {
                    name = name.replace (".pls", "");
                    success = parse_paths_from_pls(file, ref paths);
                } else {
                    success = false;
                    throw new GLib.Error (GLib.Quark.from_string ("not-recognized"), 1, _("Unrecognized playlist file. Import failed."));
                }
                playlists.set (name, paths);
            }
        }
        
        return playlists;
    }

}
