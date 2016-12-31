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
 * Authored by: Lucas Baudin <xapantu@gmail.com>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

namespace Noise.PixbufUtils {
    public async Gdk.Pixbuf? get_pixbuf_from_file_async (File file, Cancellable? c = null) throws Error {
        return yield get_pixbuf_from_file_at_scale_async (file, -1, -1, false, c);
    }

    public async Gdk.Pixbuf? get_pixbuf_from_file_at_scale_async (File file, int width, int height,
                                                                bool preserve_aspect_ratio,
                                                                Cancellable? c = null) throws Error {
        Gdk.Pixbuf? image = null;
        var filestream = yield file.read_async (Priority.HIGH, c);

        if (filestream != null)
            image = new Gdk.Pixbuf.from_stream_at_scale (filestream, width, height,
                                                         preserve_aspect_ratio, c);

        return image;
    }

    public async void save_pixbuf_async (Gdk.Pixbuf pixbuf, File dest_file, string image_format,
                                         Cancellable? cancellable = null) throws Error
    {
    }
}
