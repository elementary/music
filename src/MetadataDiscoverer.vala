/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

[SingleInstance]
public class Music.MetadataDiscoverer : Object {
    private Gst.PbUtils.Discoverer? discoverer;
    private HashTable<string, AudioObject> objects_to_update;

    construct {
        try {
            discoverer = new Gst.PbUtils.Discoverer ((Gst.ClockTime) (5 * Gst.SECOND));
            discoverer.discovered.connect (relay_metadata);
            discoverer.finished.connect (discoverer.stop);
        } catch (Error e) {
            critical ("Unable to start Gstreamer Discoverer: %s", e.message);
        }

        objects_to_update = new HashTable<string, AudioObject> (str_hash, str_equal);
    }

    public void request (AudioObject audio) requires (discoverer != null && !objects_to_update.contains (audio.uri)) {
        objects_to_update[audio.uri] = audio;
        discoverer.start ();
        discoverer.discover_uri_async (audio.uri);
    }

    private void relay_metadata (Gst.PbUtils.DiscovererInfo info, Error? err) {
        string uri = info.get_uri ();

        var audio_obj = objects_to_update.take (uri, null);

        switch (info.get_result ()) {
            case Gst.PbUtils.DiscovererResult.URI_INVALID:
                critical ("Couldn't read metadata for '%s': invalid URI.", uri);
                return;
            case Gst.PbUtils.DiscovererResult.ERROR:
                critical ("Couldn't read metadata for '%s': %s", uri, err.message);
                return;
            case Gst.PbUtils.DiscovererResult.TIMEOUT:
                critical ("Couldn't read metadata for '%s': Discovery timed out.", uri);
                return;
            case Gst.PbUtils.DiscovererResult.BUSY:
                critical ("Couldn't read metadata for '%s': Already discovering a file.", uri);
                return;
            case Gst.PbUtils.DiscovererResult.MISSING_PLUGINS:
                critical ("Couldn't read metadata for '%s': Missing plugins.", uri);
                return;
            default:
                break;
        }

        audio_obj.update_metadata (info);
    }
}
