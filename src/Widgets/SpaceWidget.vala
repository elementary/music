/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski and Victor Eduardo for
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

using Gtk;
using Gee;

public class SpaceWidget : Gtk.EventBox {

    public static CssProvider style_provider;

    public signal void cancel_clicked();

    public enum ItemColor {
        BLUE,
        ORANGE,
        GREEN,
        RED,
        PURPLE,
        GREY
    }

    public enum ItemPosition {
        START,
        END
    }

    private const string WIDGET_STYLE = """
        .SpaceWidgetBase {
            background-image: -gtk-gradient (linear,
                                             left top, left bottom,
                                             from (shade (#e6e6e6, 0.96)),
                                             color-stop (0.5, alpha (shade (#e6e6e6, 1.1) , 0.7)),
                                             to (shade (#f7f7f7, 1.04)));

            border-top-color  : shade (#e6e6e6, 0.88);
            border-style      : solid;
            border-width      : 1 0 0 0;
        }

        .SpaceBarItem,
        .SpaceBarFullItem,
        .SpaceBarItem:nth-child(first),
        .SpaceBarItem:nth-child(last) {
            -unico-inner-stroke-width: 0;
            -unico-outer-stroke-width: 0;

            -unico-border-gradient: -gtk-gradient (linear, left top, left bottom,
                                                   from (alpha (#fff, 0.5)),
                                                   to (alpha (#fff, 0.0)));

            -unico-outer-stroke-gradient: -gtk-gradient (linear, left top, left bottom,
                                                         from (alpha (#000, 0.03)),
                                                         to (alpha (#000, 0.08)));
        }

        .SpaceBarItem {
            border-radius: 0 0 0 0;
        }

        .SpaceBarFullItem {
            border-radius: 300 300 300 300;
        }

        .SpaceBarItem:nth-child(first) {
            border-radius: 300 0 0 300;
        }

        .SpaceBarItem:nth-child(last) {
            border-radius: 0 300 300 0;
        }

        .LegendItem {
            border-radius: 100 100 100 100;

            -unico-inner-stroke-width: 0;
            -unico-outer-stroke-width: 1;

            -GtkButton-default-border           : 0;
            -GtkButton-image-spacing            : 0;
            -GtkButton-inner-border             : 0;
            -GtkButton-interior-focus           : false;


            -unico-border-gradient: -gtk-gradient (linear, left top, left bottom,
                                                   from (alpha (#fff, 0.9)),
                                                   to (alpha (#fff, 0.5)));

            -unico-outer-stroke-gradient: -gtk-gradient (linear, left top, left bottom,
                                                         from (alpha (#000, 0.04)),
                                                         to (alpha (#000, 0.12)));
        }

        .blue {
            background-image: -gtk-gradient (linear,
                                             left top, left bottom,
                                             from (shade (#4b91dd, 1.10) ),
                                             to (#4b91dd));
            /*
            -unico-border-gradient: -gtk-gradient (linear, left top, left bottom,
                                                   from (alpha (shade (#4b91dd, 1.3), 0.9)),
                                                   to (alpha (shade (#4b91dd, 1.0), 0.5)));

            -unico-outer-stroke-gradient: -gtk-gradient (linear, left top, left bottom,
                                                         from (alpha (shade (#4b91dd, 0.8), 0.9)),
                                                         to (alpha (shade (#4b91dd, 0.7), 0.5)));
            */
        }

        .orange {
            background-image: -gtk-gradient (linear,
                                             left top, left bottom,
                                             from (shade (#eb713f, 1.10)),
                                             to (#eb713f));
        }

        .green {
            background-image: -gtk-gradient (linear,
                                             left top, left bottom,
                                             from (shade (#408549, 1.05)),
                                             to (#408549));
        }

        .purple {
            background-image: -gtk-gradient (linear,
                                           left top, left bottom,
                                           from (shade (#a64067, 1.05)),
                                           to (#a64067));
        }

        .red {
            background-image: -gtk-gradient (linear,
                                               left top, left bottom,
                                               from (shade (#ba393e, 1.05)),
                                               to (#ba393e));
        }

        .grey {
            background-image: -gtk-gradient (linear,
                                               left top, left bottom,
                                               from (shade (#d5d3d1, 1.05)),
                                               to (#d5d3d1));
        }

    """;

    private HashMap<int, SpaceWidgetItem> items;

    private int HEIGHT = 100;
    private int DEFAULT_PADDING = 10;

    private double total_size;
    private double free_space_size;

    private bool single_item_visible;

    private Box legend_wrapper;
    private Box bar_wrapper;
    private Box full_bar_wrapper;

    private SpaceWidgetBarFullItem full_bar_item;
    
    bool already_drawing;

    public SpaceWidget (double size) {
		already_drawing = false;
        style_provider = new CssProvider();

        try  {
            style_provider.load_from_data (WIDGET_STYLE, -1);
        } catch (Error e) {
            stderr.printf ("\nSpaceWidget: Couldn't load style provider");
        }

        this.get_style_context().add_class("SpaceWidgetBase");
        this.get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);

        var padding = new Box (Orientation.VERTICAL, 0);

        legend_wrapper = new Box (Orientation.HORIZONTAL, 5);

        var top_box = new Box (Orientation.HORIZONTAL, 0);

        // Adding left and right spacing
        top_box.pack_start (new Box (Orientation.HORIZONTAL, 0), true, true, 0);
        top_box.pack_end (new Box (Orientation.HORIZONTAL, 0), true, true, 0);

        // Adding legend
        top_box.pack_start (legend_wrapper, false, true, 0);

        bar_wrapper = new Box (Orientation.HORIZONTAL, 0);
        full_bar_wrapper = new Box (Orientation.HORIZONTAL, 0);
        full_bar_wrapper.set_no_show_all (true);
        full_bar_wrapper.hide ();

        var bottom_box = new Box (Orientation.HORIZONTAL, 0);

        // Adding left and right spacing
        bottom_box.pack_start (new Box (Orientation.HORIZONTAL, 0), true, true, 0);
        bottom_box.pack_end (new Box (Orientation.HORIZONTAL, 0), true, true, 0);

        // Adding bar
        bottom_box.pack_start (bar_wrapper, false, true, 0);
        bottom_box.pack_start (full_bar_wrapper, false, true, 0);

        var left_box = new Box (Orientation.VERTICAL, 3);
        left_box.pack_start (top_box, true, false, 0);
        left_box.pack_end (bottom_box, true, false, 0);

        var wrapper = new Box (Orientation.HORIZONTAL, 0);
        wrapper.pack_start (new Box (Orientation.HORIZONTAL, 0), false, true, DEFAULT_PADDING);
        wrapper.pack_end (new Box (Orientation.HORIZONTAL, 0), false, true, DEFAULT_PADDING);
        wrapper.pack_start (left_box, true, true, 4);
        wrapper.pack_start (new Box (Orientation.HORIZONTAL, 0), false, true, DEFAULT_PADDING);

        padding.pack_start (wrapper, true, true, DEFAULT_PADDING);

        add (padding);

        items = new HashMap<int, SpaceWidgetItem>();
        set_size (size);

        set_size_request (-1, HEIGHT);

        /** Adding free-space element **/
        add_item_at_pos ("Free", size, ItemColor.GREY, ItemPosition.END);
        
        this.draw.connect(draw_called);
    }

    public void set_size (double size) {
        total_size = size;
        free_space_size = size;
        update_bar_item_sizes (false);
    }

    public int add_item (string name, double size, ItemColor color) {
        return add_item_at_pos (name, size, color, ItemPosition.START);
    }

    private int add_item_at_pos (string name, double size, ItemColor color, ItemPosition pos) {

        if (size > free_space_size)
            return -1;

        var item = new SpaceWidgetItem (items.size, name, size, color);
		item.size_changed.connect (update_bar_item_sizes);

        items.set(items.size, item);

        if (pos == ItemPosition.END) {
            bar_wrapper.pack_end (item.bar_item, false, false, 0);
            legend_wrapper.pack_end (item.legend, true, true, 0);
        } else {
            bar_wrapper.pack_start (item.bar_item, false, false, 0);
            legend_wrapper.pack_start (item.legend, true, true, 0);
        }

        if (items.size > 0)
            update_bar_item_sizes (items.size < 1);

        return items.size;
    }


    public void update_item_size (int index, double size) {
        items.get(index).set_size (size);
        update_bar_item_sizes (index < 1);
    }

    public void remove_item(int index) {
        if (items.size <= 1)
            return;

        var item = items.get(index);
        item.destroy();
        items.unset(index);
        update_bar_item_sizes(false);
    }

    private void update_bar_item_sizes (bool is_free_space) {
        int item_list_size = items.size;

        int actual_width = get_allocated_width ();
        int bar_width = actual_width * 7 / 10;
        
        stdout.printf("actual width %d, bar width %d\n", actual_width, bar_width);

        if (item_list_size < 1)
            return;

        int total_visible_items = item_list_size;

        int last_visible_id = 0;
        foreach (var item in items) {
            if (item.size <= 0.0)
                total_visible_items --;
            else
                last_visible_id = item.ID;
        }

        if (total_visible_items == 1) {

            if (single_item_visible) {
                //update the size of the bar
                stdout.printf("a\n");
                full_bar_item.set_size (bar_width);
            } else {
                // show a nice rounded bar
                stdout.printf("b\n");
                show_full_bar_item (true, items.get(last_visible_id).color);
                full_bar_item.show();
                full_bar_item.set_size (bar_width);
            }

            return;
        }
        else if (single_item_visible) {
			stdout.printf("c\n");
                show_full_bar_item (false, null);
        }

        var free_space_item = items.get(0);

        if (is_free_space) {
            int width = (int) ((free_space_item.size/total_size) * bar_width);
            stdout.printf("is_free_space width is %d\n", width);
            free_space_item.bar_item.set_size (width);
            return;

        }

        free_space_size = total_size;

        //free_space_item.bar_item.set_size (0);

        foreach (var item in items) {
            if (item.ID > 0) {
                int width = (int) ((item.size/total_size) * bar_width);
                free_space_size -= item.size;
                item.bar_item.set_size (width);

                item.show ();
            }
        }

        free_space_item.set_size (free_space_size);
    }

    private void show_full_bar_item (bool show_item, ItemColor? color) {
        if (show_item) {
            bar_wrapper.hide ();
            bar_wrapper.set_no_show_all (true);
            full_bar_wrapper.set_no_show_all (false);
            full_bar_item = new SpaceWidgetBarFullItem (color, 0);
            full_bar_wrapper.pack_start (full_bar_item, false, false, 0);
            single_item_visible = true;
        } else {
            full_bar_item.destroy ();
            bar_wrapper.set_no_show_all (false);
            full_bar_wrapper.set_no_show_all (true);
            bar_wrapper.show_all ();
            single_item_visible = false;
        }
    }

    /**
     * This method gets called by GTK+ when the actual size is known
     * and the widget is told how much space could actually be allocated.
     * It is called every time the widget size changes, for example when the
     * user resizes the window.
     **/
	bool draw_called(Cairo.Context c) {
		if(already_drawing)
			return false;
		stdout.printf("draw_called\n");
        // The base method will save the allocation and move/resize the
        // widget's GDK window if the widget is already realized.
        // FIXME: Don't let the widget increase its height
        // FIXME: Apply the new size inmediatly
        //stdout.printf("size is now %d\n", allocation.width);
        already_drawing = true;
        update_bar_item_sizes (false);
        already_drawing = false;
        //base.size_allocate (allocation);
        //stdout.printf("size is still %d\n", allocation.width);
        //Move/resize other realized windows if necessary
        
        return false;
    }
}

private class SpaceWidgetBarItem : Gtk.Button {
    public SpaceWidget.ItemColor color;
    public int hsize = 0;

    private const int BAR_HEIGHT = 23; // FIXME: Find a better size

    public SpaceWidgetBarItem (SpaceWidget.ItemColor color, int hsize) {
        this.color = color;
        var style = this.get_style_context ();

        switch (color) {
            case SpaceWidget.ItemColor.BLUE:
                style.add_class ("blue");
                break;
            case SpaceWidget.ItemColor.ORANGE:
                style.add_class ("orange");
                break;
            case SpaceWidget.ItemColor.GREEN:
                style.add_class ("green");
                break;
            case SpaceWidget.ItemColor.RED:
                style.add_class ("red");
                break;
            case SpaceWidget.ItemColor.PURPLE:
                style.add_class ("purple");
                break;
            case SpaceWidget.ItemColor.GREY:
                style.add_class ("grey");
                break;
            default:
                style.add_class ("grey");
                break;
        }

        this.sensitive = false;
        style.add_class ("SpaceBarItem");
        style.add_provider (SpaceWidget.style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);

        this.set_size_request (0, BAR_HEIGHT);
    }

    public void set_size (int size) {
		if(size == hsize)
			return;
		stdout.printf("setting hsize %d in bar item to %d\n", hsize, size);
        this.hsize = size;

        if (size < 1) {
            this.hide ();
        } else {
            this.show ();
            this.width_request = hsize;
        }
    }
}


private class SpaceWidgetBarFullItem : SpaceWidgetBarItem {
    public SpaceWidgetBarFullItem (SpaceWidget.ItemColor color, int hsize) {
        base (color, hsize);
        var style = this.get_style_context ();
        this.sensitive = false;
        style.remove_class("SpaceBarItem");
        style.add_class ("SpaceBarFullItem");
        style.add_provider (SpaceWidget.style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
}

private class LegendItem : Gtk.Button {

    public SpaceWidget.ItemColor color;

    private const int DIAMETER = 20;

    public LegendItem (SpaceWidget.ItemColor color) {
        this.color = color;
        var style = this.get_style_context ();

        switch (color) {
            case SpaceWidget.ItemColor.BLUE:
                style.add_class ("blue");
                break;
            case SpaceWidget.ItemColor.ORANGE:
                style.add_class ("orange");
                break;
            case SpaceWidget.ItemColor.GREEN:
                style.add_class ("green");
                break;
            case SpaceWidget.ItemColor.RED:
                style.add_class ("red");
                break;
            case SpaceWidget.ItemColor.GREY:
                style.add_class ("grey");
                break;
            case SpaceWidget.ItemColor.PURPLE:
                style.add_class ("purple");
                break;
            default:
                style.add_class ("grey");
                break;
        }

        style.add_class ("LegendItem");
        style.add_provider (SpaceWidget.style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
        this.sensitive = false;
        this.set_diameter (DIAMETER);
    }

    public void set_diameter (int diameter) {
        this.set_size_request (diameter, diameter);
    }
}

private class SpaceWidgetItem : GLib.Object {
    public signal void size_changed (bool is_free_space);

    public int ID;
    public string name;
    public double size;
    public SpaceWidget.ItemColor color;

    public Gtk.Box legend;
    public SpaceWidgetBarItem bar_item;

    private Gtk.Label title_label;
    private Gtk.Label size_label;

    /** Base Unit: Megabytes (MB) **/
    const double MULT = 1024;
    const double MB = 1;
    const double GB = MULT * MB;
    const double TB = MULT * GB;

    public SpaceWidgetItem (int id, string name, double size, SpaceWidget.ItemColor color) {
        this.name = name;
        this.size = size;
        this.color = color;
        this.ID = id;
        this.legend = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        // set size data
        this.set_size (size);

        /** Create legend **/
        var legend_icon = new LegendItem (color);

        var legend_icon_wrapper = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        legend_icon_wrapper.pack_start (new Gtk.Box (Gtk.Orientation.VERTICAL, 0), true, true, 0);
        legend_icon_wrapper.pack_start (legend_icon, false, false, 0);
        legend_icon_wrapper.pack_end (new Gtk.Box (Gtk.Orientation.VERTICAL, 0), true, true, 0);

        if (id > 0)
            legend.pack_end (new Box (Orientation.HORIZONTAL, 0), true, true, 20);

        legend.pack_start (legend_icon_wrapper, true, true, 0);

        this.title_label = new Gtk.Label ("<span weight='medium' size='10700'>" + name + "</span>");
        title_label.use_markup = true;

        var label_wrapper = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
        label_wrapper.pack_start (title_label, true, true, 0);
        label_wrapper.pack_start (size_label, true, true, 0);

        legend.pack_start (label_wrapper, true, true, 7);

        /** Create bar item **/
        bar_item = new SpaceWidgetBarItem (color, 0);
    }

    public void set_size (double s) {
		if(size == s)
			return;
			
        size = s;

        /** Updating size label **/

        var size_text = new StringBuilder();

        if (size <= GB) {
            size_text.append ("%.1f".printf(size/MB));
            size_text.append (" MB");
        } else if (size <= TB) {
            size_text.append ("%.1f".printf(size/GB));
            size_text.append (" GB");
        } else {
            size_text.append ("%.1f".printf(size/TB));
            size_text.append (" TB");
        }

        if (size_label == null)
            size_label = new Label (size_text.str);
        else
            size_label.set_text (size_text.str);

        size_changed (this.ID < 1);
    }

    public void show () {
        if (size > 0.0) {
            show_legend ();
            show_bar_item ();
        } else if (this.ID > 0) {
            hide_legend ();
            hide_bar_item ();
        } else {
            hide_bar_item ();
        }
    }

    /** These functions shouldn't be called directly **/
    public void hide_bar_item () {
        this.bar_item.hide ();
    }

    public void show_bar_item () {
        this.bar_item.show ();
    }

    public void hide_legend () {
        legend.hide ();
    }

    public void show_legend () {
        legend.show_all ();
    }

    public void destroy () {
        bar_item.destroy();
        legend.destroy();
    }
}

