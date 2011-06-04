// ModeButton
// 
// Copyright (C) 2008 Christian Hergert <chris@dronelabs.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

using Gtk;
using Gdk;

namespace ElementaryWidgets {

    public class ModeButton : Gtk.EventBox {  
      
        public signal void added (int index, Widget widget);
        public signal void removed (int index, Widget widget);
        public signal void activated (int index, Widget widget);

        private int _selected = -1;
        private int _hovered = -1;
        private HBox box;

        public ModeButton () {
            events |= EventMask.POINTER_MOTION_MASK
                   |  EventMask.BUTTON_PRESS_MASK
                   |  EventMask.LEAVE_NOTIFY_MASK; 

            box = new HBox (true, 1);
            box.border_width = 0;
            add (box);
            box.show ();

            leave_notify_event.connect(on_leave_notify_event);
            button_press_event.connect(on_button_press_event);
            motion_notify_event.connect(on_motion_notify_event);
            scroll_event.connect(on_scroll_event);	
        }

        public int selected {
            get {
                return this._selected;
            }
            set {
                if (value < -1 || value >= box.get_children ().length ())
                    return;

                if (_selected >= 0)
                    box.get_children ().nth_data(_selected).set_state (StateType.NORMAL);

                _selected = value;
                box.get_children ().nth_data (_selected).set_state (StateType.SELECTED);
                queue_draw ();

                Widget selectedItem = (value >= 0) ? box.get_children().nth_data (value) : null;
                activated (_selected, selectedItem);
            }
        }

        public int hovered {
            get {
                return this._hovered;
            }
            set {
                if (value < -1 || value >= box.get_children().length())
                    return;

                if (value == _hovered)
                    return;

                _hovered = value;
                queue_draw ();
            }
        }

        public void append (Widget widget)
        {
            box.pack_start (widget, true, true, 5);
            int index = (int) box.get_children ().length () - 2;
            added (index, widget);
        }

        public new void remove (int index) {
            Widget child = box.get_children ().nth_data (index);
            box.remove (child);
            if (_selected == index)
                _selected = -1;
            else if (_selected >= index)
                _selected--;
            if (_hovered >= index)
                _hovered--;
            this.removed (index, child);
            this.queue_draw ();
        }

        public new void focus (Widget widget) {
            int select = box.get_children().index(widget);

            if (_selected >= 0)
                box.get_children ().nth_data(_selected).set_state(StateType.NORMAL);

            _selected = select;
            widget.set_state (StateType.SELECTED);
            queue_draw ();
        }

        protected bool on_scroll_event (EventScroll event) {
            switch (event.direction) {
                case ScrollDirection.UP:
                    if (selected < box.get_children().length() - 1)
                        selected++;
                    break;
                case ScrollDirection.DOWN:
                    if (selected > 0)
                        selected--;
                    break;
            }

            return true;	
        }

        protected bool on_button_press_event (EventButton event) {
            if (_hovered > -1 && _hovered != _selected)
                selected = _hovered;

            return true;
        }

        protected bool on_leave_notify_event () {
            hovered = -1;

            return true;
        }

        protected bool on_motion_notify_event (EventMotion event) {
            int n_children = (int) box.get_children ().length ();
            if (n_children < 1)
                return false;

            Allocation allocation;
            get_allocation (out allocation);	

            double child_size = allocation.width / n_children;
            int i = -1;

            if (child_size > 0)
                i = (int) (event.x / child_size);

            if (i >= 0 && i < n_children)
                this.hovered = i;

            return false;
        }

        protected override bool expose_event (Gdk.EventExpose event){
        
			var clip_region = Gdk.Rectangle () {x=0, y=0, width=0, height=0};
			var n_children = (int) box.get_children().length();
			event.window.begin_paint_rect (event.area);
			Gtk.paint_box (this.style, event.window, Gtk.StateType.NORMAL, Gtk.ShadowType.IN, event.area, this, "button", event.area.x, event.area.y, event.area.width, event.area.height);
			
            if (_selected >= 0) {
                if (n_children > 1) {
					clip_region.width = event.area.width / n_children;
					clip_region.x = (clip_region.width * _selected) + 1;
				}
				else {
					clip_region.x = 0;
					clip_region.width = event.area.width;
				}
				
				clip_region.y = event.area.y;
				clip_region.height = event.area.height;
				Gtk.paint_box (this.style, event.window, Gtk.StateType.SELECTED, Gtk.ShadowType.ETCHED_OUT, clip_region, this, "button", event.area.x, event.area.y, event.area.width, event.area.height);
				
            }
            
            if (hovered >= 0 && selected != hovered) {
				if (n_children > 1) {
					clip_region.width = event.area.width / n_children;
					if (hovered == 0)
						clip_region.x = 0;
					else
						clip_region.x = clip_region.width * hovered + 1;
				}
				else {
					clip_region.x = 0;
					clip_region.width = event.area.width;
				}

				clip_region.y = event.area.y;
				clip_region.height = event.area.height;
				Gtk.paint_box (this.style, event.window, Gtk.StateType.PRELIGHT, Gtk.ShadowType.IN, clip_region, this, "button", event.area.x, event.area.y, event.area.width, event.area.height);
			}

            propagate_expose (box, event);
            
            event.window.end_paint ();
            
            return true;
        }
        
    }
    
}
