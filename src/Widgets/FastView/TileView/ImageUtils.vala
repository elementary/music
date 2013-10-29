/**
 * Copyright 2009-2013 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 3 or later). See the COPYING file in this distribution.
 *
 * (Code taken from Shotwell Photo Manager: shotwell/src/util/image.vala)
 */

namespace Noise.ImageUtils {
    internal void shift_colors (Gdk.Pixbuf pixbuf, int red, int green, int blue, int alpha) {
        assert (red >= -255 && red <= 255);
        assert (green >= -255 && green <= 255);
        assert (blue >= -255 && blue <= 255);
        assert (alpha >= -255 && alpha <= 255);

        int width = pixbuf.get_width ();
        int height = pixbuf.get_height ();
        int rowstride = pixbuf.get_rowstride ();
        int channels = pixbuf.get_n_channels ();
        uchar *pixels = pixbuf.get_pixels ();

        assert (channels >= 3);
        assert (pixbuf.get_colorspace () == Gdk.Colorspace.RGB);
        assert (pixbuf.get_bits_per_sample () == 8);

        for (int y = 0; y < height; y++) {
            int y_offset = y * rowstride;

            for (int x = 0; x < width; x++) {
                int offset = y_offset + (x * channels);

                if (red != 0)
                    pixels[offset] = shift_color_byte (pixels[offset], red);

                if (green != 0)
                    pixels[offset + 1] = shift_color_byte (pixels[offset + 1], green);

                if (blue != 0)
                    pixels[offset + 2] = shift_color_byte (pixels[offset + 2], blue);

                if (alpha != 0 && channels >= 4)
                    pixels[offset + 3] = shift_color_byte (pixels[offset + 3], alpha);
            }
        }
    }

    internal inline uchar shift_color_byte (int b, int shift) {
        return (uchar) (b + shift).clamp (0, 255);
    }
}
