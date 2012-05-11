/*
 * Copyright (c) 2012 BeatBox Developers
 *
 * This is a free software; you can redistribute it and/or
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
 *
 */

/**
 * /!\ NOTE: Currently not used.
 *
 * This is an awesome Clutter-based Album View written by Lucas Baudin. We keep this file
 * in case someone wants to re-take the idea in the future and continue its development.
 *
 * Things to consider:
 * - The functional part of the widget is deprecated. We need to update this file to
 *   use the new [internal] ViewWrapper functions. This should be easy to do since
 *   AlbumView implements the ContentView interface. Looking at what's changed there
 *   is a good place to start. Another option would be copying the interface implementation
 *   from AlbumIconView.vala and leaving the rest of the code unmodified.
 */

using Gtk;
using Gee;

namespace BeatBox {
    bool clutter_usable = false;
}

/**
 * The Widget in the Clutter.Actor of a HoverView. It contains some content
 * and a X to close it.
 **/
class BeatBox.HoverSidebar : Gtk.Grid {
    Gtk.Widget? content;
    public signal void close ();

    public HoverSidebar () {
        var close = new Gtk.Button ();
        close.set_image (new Gtk.Image.from_stock ("gtk-close", Gtk.IconSize.MENU));
        
        attach (close, 0, 0, 1, 1);
        
        close.hexpand = close.vexpand = false;
        close.halign = Gtk.Align.START;
        close.set_relief(Gtk.ReliefStyle.NONE);
        close.clicked.connect( () =>  { this.close(); });
    }

    public void set_content (Gtk.Widget widget) {
        if (content != null)
            remove (content);
        attach (widget, 0, 1, 1, 1);
        content = widget;
    }
    
    public Gtk.Widget get_content () {
        return content;
    }
}

class BeatBox.Albums.IconView : Gtk.IconView, HoverBackgroundWidget {
    internal LibraryManager lm;
    internal LibraryWindow lw;

    public IconView(AlbumViewModel model) {
        set_model(model);

        item_activated.connect(on_activate);
        button_press_event.connect(on_button_press);
    }

    void on_activate (Gtk.TreePath path) {
        
        // Get the name and the author
        
        TreeIter iter;
    
        if(!model.get_iter(out iter, path))
        {
            collapse_widget();
            return;
        }
    
        Media s = ((AlbumViewModel)model).get_media(iter);
        Gdk.Pixbuf pix;
        model.get(iter, 0, out pix);
        
        var grid = new Gtk.Grid();
        var title = new Granite.Widgets.WrapLabel(s.album);
        title.set_alignment(0.5f, 0.5f);
        title.set_justify(Gtk.Justification.CENTER);
        var author = new Granite.Widgets.WrapLabel(s.artist);
        author.set_alignment(0.5f, 0.5f);
        author.set_justify(Gtk.Justification.CENTER);
        var image = new Gtk.Image.from_pixbuf(pix);
        author.sensitive = false;
        grid.attach(image, 0, 0, 1, 1);
        image.halign = Gtk.Align.CENTER;
        image.hexpand = true;
        grid.attach(title, 0, 1, 1, 1);
        grid.attach(author, 0, 2, 1, 1);

        // Fake list view
        var tree_view = new MusicListView(lm, lw, "Artist", SortType.ASCENDING, ViewWrapper.Hint.ALBUM_LIST, -1);
        var songs = new LinkedList<int>();
        var albums = new LinkedList<int>();
        lm.do_search("", tree_view.get_hint(), "All Genres", s.album_artist, s.album, lm.media_ids(), ref songs, ref albums);
        tree_view.append_medias(songs);
        tree_view.vexpand = true;
        
        grid.attach(tree_view, 0, 3, 1, 1);
        expand_widget(grid, (int)(get_allocated_width()*0.3));

        grid.margin_right= grid.margin_left = grid.margin_top = grid.margin_bottom = 10;
    }

    int track = 1;
    bool on_button_press(Gdk.EventButton event) {
        base.button_press_event(event);
        var selection = get_selected_items();
        if(selection.length() == 0)
            collapse_widget();
        else
        {
            on_activate(selection.nth_data(0));
        }
        return true;
    }

}

public interface BeatBox.HoverBackgroundWidget : Gtk.Widget
{
    public signal void expand_widget(Gtk.Widget widget, int size);
    public signal void collapse_widget();
}

interface BeatBox.HoverView : Gtk.Widget
{
    public abstract void set_background_widget (HoverBackgroundWidget icon_view_wi);
}

class BeatBox.HoverViewFallback : Gtk.Grid, HoverView
{
    Gtk.Grid sidebar;
    public HoverViewFallback () {
    }

    bool expanded = false;

    public void set_background_widget (HoverBackgroundWidget widget) {
        var scrolled = new Gtk.ScrolledWindow(null, null);
        //scrolled.set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
        scrolled.add(widget);
        scrolled.size_allocate.connect_after( (alloc) => {
            if(widget is Gtk.IconView) (widget as Gtk.IconView).set_columns((alloc.width - ((widget as Gtk.IconView).margin * 2))/( (widget as Gtk.IconView).get_item_width()));
        });
        attach(scrolled, 0, 0, 1, 1);
        scrolled.hexpand = true;
        scrolled.vexpand = true;

        widget.expand_widget.connect(on_expand);
        widget.collapse_widget.connect(on_collapse);
    }

    Gtk.Widget? content;
    void on_expand(Gtk.Widget content_) {
    expanded = true;
        content_.width_request = 200;
        content_.hexpand = false;
        if(content != null)
            remove(content);
        //sidebar.add(content_); //attach(sidebar_, 1, 0, 1, 1);
        attach(content_, 1, 0, 1, 1);
        content = content_;
        show_all();
    }

    void on_collapse() {
        expanded = false;
        if(sidebar != null)
            remove(sidebar);
        sidebar = null;
    }
}

class BeatBox.HoverViewClutter : GtkClutter.Embed, HoverView
{
    Clutter.Container stage;
    GtkClutter.Actor background_view;

    GtkClutter.Actor expand_view;
    GtkClutter.Actor old_expand_view;
    
    HoverBackgroundWidget main_widget;
    
    HoverSidebar sidebar;
    HoverSidebar old_sidebar;

    Clutter.Group shadow;
    Clutter.CairoTexture shadow_left;
    Clutter.CairoTexture shadow_top;
    Clutter.CairoTexture shadow_bottom;
    
    const int shadow_size = 5;
    const int margin_top = 30;

    Granite.Drawing.BufferSurface buffer_shadow;

    int sidebar_width = 0;

    bool first = false;
    bool expanded = false;
    

    public HoverViewClutter()
    {
        stage = get_stage() as Clutter.Container;

        // Define a group and several Actors to show the sidebar shadow
        shadow = new Clutter.Group();
        shadow_left = new Clutter.CairoTexture(shadow_size*3, 50);
        shadow.add(shadow_left);
        shadow_top = new Clutter.CairoTexture(20, shadow_size*2);
        shadow_top.x = 3*shadow_size + 1;
        shadow_bottom = new Clutter.CairoTexture(20, shadow_size*2);
        shadow.add(shadow_bottom);
        shadow_bottom.x = 3*shadow_size + 1;
        shadow.add(shadow_top);
        shadow.y = margin_top - shadow_size;
        stage.add_actor(shadow);
        shadow.x = get_allocated_width();
        
        /* We only need an auto_resize for the left part, which mustn't scale corners.
         * For the others, we do'nt care, we just need a good height, the width can
         * be scaled since it is only a linear gradient. (and it is faster)
         */
        shadow_left.auto_resize = true;
        
        // Shadow drawing
        shadow_left.draw.connect((cr) => {
            cr.set_source_surface(buffer_shadow.surface, 0, 0);
            cr.paint();
            return false;
        });
        shadow_top.draw.connect((cr) => {
            cr.set_source_surface(buffer_shadow.surface, -2*shadow_size, 0);
            cr.paint();
            return false;
        });
        shadow_bottom.draw.connect((cr) => {
            cr.set_source_surface(buffer_shadow.surface, -2*shadow_size,
                                  -buffer_shadow.height + 2*shadow_size);
            cr.paint();
            return false;
        });

        // Background actor (it will contain the main widget, e.g. an icon view 
        background_view = new GtkClutter.Actor();
        stage.add_actor(background_view);

        // Sidebar actor
        expand_view = new GtkClutter.Actor();
        stage.add_actor(expand_view);
        sidebar = new HoverSidebar();
        (expand_view.get_widget() as Gtk.Bin).add(sidebar);
        sidebar.close.connect(on_collapse);

        // Second sidebar actor, used to do fading
        old_expand_view = new GtkClutter.Actor();
        stage.add_actor(old_expand_view);
        old_sidebar = new HoverSidebar();
        (old_expand_view.get_widget() as Gtk.Bin).add(old_sidebar);
    
        
        size_allocate.connect(on_size_allocate);
    }
    
    /**
     * This function generate a shadow in the BufferSurface buffer_shadow. Then, the surface
     * can be used to get the part of the shadow (top, bottom, and left).
     *
     * @param height the height of the widget (not the height of the shadow). If null is
     * passed, then we'll use get_allocated_height().
     **/
    void update_shadow_surface(int? height = null) {
        height = height ?? get_allocated_height();

        buffer_shadow = new Granite.Drawing.BufferSurface(sidebar_width + shadow_size,
                                                          height - 2*margin_top + 2*shadow_size);

        buffer_shadow.context.rectangle(shadow_size, shadow_size,
                                        sidebar_width, height - 2*margin_top);
        buffer_shadow.context.set_source_rgb(0,0,0);
        buffer_shadow.context.fill();
        buffer_shadow.fast_blur(2, 2);
    }
    
    void on_size_allocate(Gtk.Allocation alloc) {
        background_view.height = alloc.height;
        background_view.width = alloc.width;
        shadow.height = alloc.height;
        /* FIXME: What are those -1 ? -.- */
        shadow_bottom.y =  shadow.height - 2*margin_top - 1;
        expand_view.height = alloc.height - 2*margin_top - 1;
        old_expand_view.height = alloc.height - 2*margin_top - 1;
        expand_view.y = margin_top;
        old_expand_view.y = margin_top;

        if(!expanded) {
            shadow.x = alloc.width;
            expand_view.x = alloc.width + shadow_size;
        }
        else {
            shadow.x = alloc.width - sidebar_width - shadow_size;
            expand_view.x = alloc.width - sidebar_width;
        }
        if(expanded) {
            update_shadow_surface(alloc.height);
            shadow_left.height = alloc.height - margin_top - shadow_size;
        }
    }

    public void set_background_widget (HoverBackgroundWidget icon_view_wi) {
        var scrolled = new Gtk.ScrolledWindow(null, null);
        scrolled.set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
        scrolled.add_with_viewport(icon_view_wi);
        main_widget = icon_view_wi;
        main_widget.expand_widget.connect(on_expand);
        main_widget.collapse_widget.connect(on_collapse);

        (background_view.get_widget() as Gtk.Bin).add(scrolled);
        scrolled.show_all();
    }

    void on_collapse() {
        expanded = false;

        double x = get_allocated_width() + shadow_size;
        double x2 = get_allocated_width();
        expand_view.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 400, x:x);
        shadow.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 400, x:x2);
        background_view.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 400, opacity:255);
        
    }
    
    /**
     * Function called by a signal of the main_widget.
     *
     * @param label the widget to put in the sidebar
     * @param width thre requested width for the sidebar
     **/
    void on_expand(Gtk.Widget label, int width) {
        if(expanded) {
            var w = sidebar.get_content();
            sidebar.set_content(label);

            /* We must set up a fading effect if there is already a sidebar shown */
            old_sidebar.set_content(w);
            old_sidebar.show_all();
            old_expand_view.x = get_allocated_width() - sidebar_width;
            old_expand_view.opacity = 255;
            old_expand_view.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 400, opacity:0);
            Timeout.add(400, () => {
                old_expand_view.x = - sidebar_width;
                return false;
            }); /* and hide it */
        }

        else {
            sidebar_width = width;
            update_shadow_surface();
            shadow_bottom.width = shadow_top.width = sidebar_width - shadow_size;
            if(!first) {
                shadow_top.invalidate();
                shadow_bottom.invalidate();
                first = true;
            }
            shadow_left.height = get_allocated_height() - margin_top - shadow_size;
            expand_view.x = get_allocated_width() + shadow_size;
            shadow.x = get_allocated_width();
            shadow.width = sidebar_width + shadow_size;
            shadow.opacity = 255;
            expand_view.width = width;
            double x = get_allocated_width() - width;
            double x2 = get_allocated_width() - width - shadow_size;
            sidebar.set_content(label);
            
            expand_view.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 400, x:x);
            shadow.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 400, x:x2);
            background_view.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 400, opacity:120);
        }
        expanded = true;

        sidebar.show_all();
    }
}

public class BeatBox.AlbumView : ContentView, Grid {
    LibraryManager lm;
    LibraryWindow lw;
    Collection<int> medias;
    
    private Collection<int> _show_next; // these are populated if necessary when user opens this view.
    private Collection<int> _showing_medias;
    private string last_search;
    LinkedList<string> timeout_search;
    
    BeatBox.Albums.IconView icons;
    AlbumViewModel model;
    
    Gdk.Pixbuf defaultPix;
    
    bool _is_current;
    bool _is_current_view;
    bool needsUpdate;
    //BeatBox.HoverView view;
    
    public signal void itemClicked(string artist, string album);
    
    /* medias should be mutable, as we will be sorting it */
    public AlbumView(LibraryManager lmm, LibraryWindow lww, Collection<int> smedias) {
        lm = lmm;
        lw = lww;
        medias = smedias;
        
        _showing_medias = new LinkedList<int>();
        last_search = "";
        timeout_search = new LinkedList<string>();
        
        defaultPix = lm.icons.default_album_art.render (null, null);
        
        buildUI();
        
        lm.medias_removed.connect(medias_removed);
    }
    
    public void buildUI() {
        /*Viewport v = new Viewport(null, null);*/
        
        /*set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);*/
        if(clutter_usable && Environment.get_variable("BEATBOX_NO_CLUTTER") == null)
            view = new BeatBox.HoverViewClutter();
        else
            view = new BeatBox.HoverViewFallback();
        
        /*v.set_shadow_type(ShadowType.NONE);*/
        model = new AlbumViewModel(lm, defaultPix);
        //icons = new BeatBox.Albums.IconView(model);
        //view.set_background_widget(icons);
        
        icons.set_pixbuf_column(0);
        icons.set_markup_column(1);
        icons.set_item_width(134);
        icons.item_padding = 0;
        icons.spacing = 2;
        icons.margin = 20;
        icons.lm = lm;
        icons.lw = lw;
        //v.add(icons);
        
        add(view);
        //view.vexpand = view.hexpand = true;
        show_all();
        
        //icons.button_press_event.connect(buttonPressEvent);
        //icons.item_activated.connect(itemActivated);
        this.focus_out_event.connect(on_focus_out);
        
        this.grab_focus ();
    }
    
    public void set_is_current(bool val) {
        _is_current = val;
        //model.is_current = val;
    }
    
    public bool get_is_current() {
        return _is_current;
    }
    
    public void set_is_current_view(bool val) {
        _is_current_view = val;
    }
    
    public bool get_is_current_view() {
        return _is_current_view;
    }
    
    public void set_hint(ViewWrapper.Hint hint) {
        // nothing
    }
    
    public ViewWrapper.Hint get_hint() {
        return ViewWrapper.Hint.MUSIC;
    }
    
    public void set_show_next(Collection<int> medias) {
        _show_next = medias;
    }
    
    public void set_relative_id(int id) {
        // do nothing
    }
    
    public int get_relative_id() {
        return 0;
    }
    
    public Collection<int> get_medias() {
        return medias;
    }
    
    public Collection<int> get_showing_medias() {
        return _showing_medias;
    }
    
    public void set_as_current_list(int media_id, bool is_initial) {
        set_is_current(true);
    }
    
    public void set_statusbar_text() {
        uint count = 0;
        uint total_time = 0;
        uint total_mbs = 0;
        
        foreach(int id in _showing_medias) {
            ++count;
            total_time += lm.media_from_id(id).length;
            total_mbs += lm.media_from_id(id).file_size;
        }
        
        string fancy = "";
        if(total_time < 3600) { // less than 1 hour show in minute units
            fancy = (total_time/60).to_string() + " minutes";
        }
        else if(total_time < (24 * 3600)) { // less than 1 day show in hour units
            fancy = (total_time/3600).to_string() + " hours";
        }
        else { // units in days
            fancy = (total_time/(24 * 3600)).to_string() + " days";
        }
        
        string fancy_size = "";
        if(total_mbs < 1000)
            fancy_size = ((float)(total_mbs)).to_string() + " MB";
        else 
            fancy_size = ((float)(total_mbs/1000.0f)).to_string() + " GB";
        
        lw.set_statusbar_text(count.to_string() + " items, " + fancy + ", " + fancy_size);
    }
    
    /*public void set_medias(Collection<int> new_medias) {
        medias = new_medias;
    }*/
    
    public void append_medias(Collection<int> new_medias) {
        
        /*_showing_medias.add_all(new_medias);
        
        var toShowS = new LinkedList<Media>();
        foreach(int i in new_medias)
            toShowS.add(lm.media_from_id(i));
        
        // first sort the medias so we know they are grouped by artists, then albums
        toShowS.sort((CompareFunc)mediaCompareFunc);
        
        LinkedList<int> albs = new LinkedList<int>();
        string previousAlbum = "";
        
        foreach(Media s in toShowS) {
            if(s.album != previousAlbum) {
                albs.add(s.rowid);
                
                previousAlbum = s.album;
            }
        }*/
        
        //model.appendMedias(albs, false);
        //model.resort();
        queue_draw();
    }
    
    public void remove_medias(Collection<int> to_remove) {
        //model.removeMedias(to_remove);
        //queue_draw();
    }
    
    /** Goes through the hashmap and generates html. If artist,album, or genre
     * is set, makes sure that only items that fit those filters are
     * shown
    */
    public void populate_view() {
        if(_show_next == _showing_medias || _show_next == null) {
            return;
        }
        
        _showing_medias = _show_next;
        
        var toShowS = new LinkedList<Media>();

        foreach(int i in _showing_medias)
            toShowS.add(lm.media_from_id(i));
        
        // first sort the medias so we know they are grouped by artists, then albums
        toShowS.sort((CompareFunc)mediaCompareFunc);
        
        LinkedList<int> albs = new LinkedList<int>();
        string previousAlbum = "";
        
        foreach(Media s in toShowS) {
            if(s.album != previousAlbum) {
                albs.add(s.rowid);
                
                previousAlbum = s.album;
            }
        }
        
        //var hPos = this.vadjustment.get_value();
        
        model = new AlbumViewModel(lm, defaultPix);
        model.appendMedias(albs, false);
        icons.set_model(model);
        
        //move_focus_out(DirectionType.UP);
        
        /* this is required to make the iconview initially scrollable */
        if(albs.size > 0) {
            //icons.select_path(new TreePath.from_string((albs.size - 1).to_string()));
            //icons.unselect_all();
        }
        
        /*if(get_is_current() && lm.media_info.media != null)
            scrollToCurrent();
        else
            this.vadjustment.set_value((int)hPos);*/
        
        needsUpdate = false;
    }
    
    public void update_medias(Collection<int> medias) {
        // nothing to do
    }
    
    public static int mediaCompareFunc(Media a, Media b) {
        if(a.album_artist == b.album_artist)
            return (a.album > b.album) ? 1 : -1;
            
        return a.album_artist > b.album_artist ? 1 : -1;
    }
    
    public bool buttonPressEvent(Gdk.EventButton ev) {
        stdout.printf("button was pressed\n");
        if(ev.type == Gdk.EventType.BUTTON_PRESS && ev.button == 1) {
            // select one based on mouse position
            TreeIter iter;
            TreePath path;
            CellRenderer cell;
            
            icons.get_item_at_pos((int)ev.x, (int)ev.y, out path, out cell);
            
            if(!model.get_iter(out iter, path))
                return false;
            
            string s;
            model.get(iter, 1, out s);
            
            string[] pieces = s.split("\n", 0);
        
            itemClicked(pieces[0], pieces[1]);
        }
        
        return false;
    }
    
    public virtual void itemActivated(TreePath path) {
        TreeIter iter;
        
        if(!model.get_iter(out iter, path))
            return;
        
        string s;
        model.get(iter, 1, out s);
        
        string[] pieces = s.split("\n", 0);
        
        itemClicked(pieces[0], pieces[1]);
    }
    
    void medias_removed(LinkedList<int> ids) {
        model.removeMedias(ids);
        //_showing_medias.remove_all(ids);
        //_show_next.remove_all(ids);
    }
    
    public void scrollToCurrent() {
        if(!get_is_current() || lm.media_info.media == null)
            return;
        
        TreeIter iter;
        for(int i = 0; model.get_iter_from_string(out iter, i.to_string()); ++i) {
            Value vs;
            model.get_value(iter, 2, out vs);

            if(icons is IconView && ((Media)vs).album == lm.media_info.media.album) {
                icons.scroll_to_path(new TreePath.from_string(i.to_string()), false, 0.0f, 0.0f);
                
                return;
            }
        }
    }
    
    public bool on_focus_out () {
        // Make sure that the search entry is not selected before grabbing focus
        if (!lw.searchField.has_focus)
            this.grab_focus ();

        return true;
    }
}

