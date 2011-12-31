/***
BEGIN LICENSE
Copyright (C) 2011 Maxwell Barvian <mbarvian@gmail.com>
This program is free software: you can redistribute it and/or modify it 
under the terms of the GNU Lesser General Public License version 2.1, as published 
by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY; without even the implied warranties of 
MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR 
PURPOSE.\  See the GNU General Public License for more details.
 
You should have received a copy of the GNU General Public License along 
with this program.  If not, see <http://www.gnu.org/licenses/>.
END LICENSE
***/

	
namespace ElementaryWidgets {

	public class Welcome : Gtk.EventBox {

		// Signals
		public signal void activated (int index);

		protected new GLib.List<Gtk.Button> children = new GLib.List<Gtk.Button> ();
		protected Gtk.VBox options;
		
		public Welcome (string title_text, string subtitle_text) {
			
			Gtk.Box content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
			
			// Set theming
			this.get_style_context().add_class ("welcome-screen");
			
			// VBox properties
			content.spacing = 5;
			content.homogeneous = false;
			
			// Make the background white.
			Gdk.RGBA bg_color = Gdk.RGBA ();
			bg_color.parse ("rgb(255,255,255)");
			this.override_background_color (Gtk.StateFlags.NORMAL, bg_color);
			
			// Top spacer
			content.pack_start (new Gtk.HBox (false, 0), true, true, 0);
			
			// Labels
			var title = new Gtk.Label ("<span weight='heavy' size='15000'>" + title_text + "</span>");
			title.use_markup = true;
			title.set_justify (Gtk.Justification.CENTER);
			content.pack_start (title, false, true, 0);
			
			var subtitle = new Gtk.Label (subtitle_text);
			subtitle.sensitive = false;
			subtitle.set_justify (Gtk.Justification.CENTER);
			content.pack_start (subtitle, false, true, 6);
			
			// Options wrapper
			this.options = new Gtk.VBox (false, 6);
			var options_wrapper = new Gtk.HBox (false, 0);
			
			options_wrapper.pack_start (new Gtk.HBox (false, 0), true, true, 0); // left padding
			options_wrapper.pack_start (this.options, false, false, 0); // actual options
			options_wrapper.pack_end (new Gtk.HBox (false, 0), true, true, 0); // right padding
			
			content.pack_start (options_wrapper, false, false, 0);

			// Bottom spacer
			content.pack_end (new Gtk.HBox (false, 0), true, true, 0);

			add (content);
		}
		
		public void set_sensitivity(uint index, bool val) {
			if(index < children.length() && children.nth_data(index) is Gtk.Widget)
				children.nth_data(index).set_sensitive(val);
		}
		
		public void append (Gdk.Pixbuf? icon, string label_text, string description_text) {
			
			// Button
			var button = new Gtk.Button ();
			button.set_relief (Gtk.ReliefStyle.NONE);
			
			// HBox wrapper
			var hbox = new Gtk.HBox (false, 6);
			
			// Add left image
			if (icon != null) {
				var image = new Gtk.Image.from_pixbuf (icon);
				hbox.pack_start (image, false, true, 6);
			}
			// Add right vbox
			var vbox = new Gtk.VBox (false, 0);
			
			vbox.pack_start (new Gtk.HBox (false, 0), true, true, 0); // top spacing
			
			// Option label
			var label = new Gtk.Label ("<span weight='medium' size='12500'>" + label_text + "</span>");
			label.use_markup = true;
			label.set_alignment(0.0f, 0.5f);
			vbox.pack_start (label, false, false, 0);
			
			// Description label
			var description = new Gtk.Label (description_text);
			description.sensitive = false;
			description.set_alignment(0.0f, 0.5f);
			vbox.pack_start (description, false, false, 0);
			
			vbox.pack_end (new Gtk.HBox (false, 0), true, true, 0); // bottom spacing
			
			hbox.pack_start (vbox, false, true, 6);
			
			button.add (hbox);
			this.children.append (button);
			options.pack_start (button, false, false, 0);
			
			button.button_release_event.connect ( () => {
				int index = this.children.index (button);
				this.activated (index); // send signal
				
				return false;
			} );
			
		}
			
	}
	
}

