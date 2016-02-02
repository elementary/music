// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2015 Noise Developers (https://launchpad.net/noise)
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
        var output_stream = yield dest_file.create_async (FileCreateFlags.NONE, Priority.HIGH,
                                                          cancellable);

        if (Utils.is_cancelled (cancellable))
            return;

        uint8[] buffer;
        pixbuf.save_to_buffer (out buffer, image_format);

        yield output_stream.write_async (buffer, Priority.HIGH, cancellable);
        output_stream.close (null); // we don't want this to be cancellable
    }
}
