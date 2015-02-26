// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Granite Developers (http://launchpad.net/granite)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

public class Granite.Widgets.EmbeddedAlert : Gtk.EventBox {

    private const int MARGIN = 78;
    private const int MAX_WIDTH = 850;

    private const string PRIMARY_TEXT_MARKUP = "<span weight=\"bold\" size=\"larger\">%s</span>";

    private int image_size {
        get {
            return image.pixel_size;
        }
        set {
            return_if_fail (value > 0 && image != null && spinner != null);
            image.pixel_size = value;
            image_box.set_size_request (value + 2, value);
            int spinner_size = value - 10;
            spinner_size = (spinner_size > 0) ? spinner_size : value;
            spinner.set_size_request (spinner_size, spinner_size);
            image_box.queue_resize ();
        }
    }

    bool queued_icon_visibility = false;
    public bool show_icon {
        get {
            return queued_icon_visibility;
        }
        set {
            queued_icon_visibility = value;

            if (!working)
                set_image_box_visible (queued_icon_visibility);
        }
    }

    public bool working {
        get {
            return spinner.active;
        }
        set {
            return_if_fail (image_box != null && image != null && spinner != null);

            var child = image_box.get_child ();
            if (child != null)
                image_box.remove (child);

            image_box.add ((value) ? spinner as Gtk.Widget : image as Gtk.Widget);
            set_image_box_visible (show_icon || value);
            spinner.active = value;
        }
    }


    /**
     * Message header.
     * The string *should not* contain any markup information, since the text will be escaped.
     */
    public string primary_text {
        get {
            return primary_text_label.label;
        }
        set {
            set_widget_visible (primary_text_label, value.strip() != "");
            primary_text_label.set_markup (Markup.printf_escaped (PRIMARY_TEXT_MARKUP, value));
        }
    }

    /**
     * Message body.
     * You can include markup information along with the message.
     */
    public string secondary_text {
        get {
            return secondary_text_label.label;
        }
        set {
            set_widget_visible (secondary_text_label, value.strip() != "");
            secondary_text_label.set_markup (value);
        }
    }

    private Gtk.MessageType _message_type = Gtk.MessageType.QUESTION;

    /**
     * Warning level of the message.
     * Besides defining what icon to use, it also defines whether the primary and secondary
     * text are selectable or not.
     * The text is selectable for the WARNING, ERROR and QUESTION types.
     */
    public Gtk.MessageType message_type {
        get {
            return _message_type;
        }
        set {
            _message_type = value;
            image.set_from_icon_name (get_icon_name_for_message_type (value), Gtk.IconSize.DIALOG);

            // Make sure the text is selectable if the level is WARNING, ERROR or QUESTION
            bool text_selectable = value == Gtk.MessageType.WARNING ||
                                   value == Gtk.MessageType.ERROR ||
                                   value == Gtk.MessageType.QUESTION;
            primary_text_label.selectable = secondary_text_label.selectable = text_selectable;
        }
    }

    private Gtk.Action[] ? _actions = null;

    /**
     * All these actions are mapped to buttons
     */
    public Gtk.Action[] ? actions {
        get {
            return _actions;
        }
        set {
            _actions = value;

            // clear button box
            foreach (var button in action_button_box.get_children ()) {
                action_button_box.remove (button);
            }

            // Add a button for each action
            if (actions != null) {
                for (int i = 0; i < actions.length; i++) {
                    var action_item = actions[i];
                    if (action_item != null) {
                        var action_button = new_button_from_action (action_item);
                        action_button_box.pack_start (action_button, false, false, 0);
                    }
                }

                buttons_visible = true;
            }
            else {
                buttons_visible = false;
            }
        }
    }

    public bool buttons_visible {
        get { return action_button_box.visible; }
        set { set_widget_visible (action_button_box, value); }
    }

    private Gtk.Grid content_grid;
    private Gtk.Image image;
    private Gtk.Spinner spinner;
    private Gtk.EventBox image_box;
    private Gtk.Label primary_text_label;
    private Gtk.Label secondary_text_label;
    private Gtk.ButtonBox action_button_box;

    public EmbeddedAlert () {
        var style = this.get_style_context ();
        style.add_class (Gtk.STYLE_CLASS_VIEW);
        style.add_class (Granite.StyleClass.CONTENT_VIEW);

        this.primary_text_label = new Gtk.Label (null);
        this.secondary_text_label = new Gtk.Label (null);

        this.primary_text_label.wrap = secondary_text_label.wrap = true;
        this.primary_text_label.use_markup = secondary_text_label.use_markup = true;

        this.action_button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);

        this.image_box = new Gtk.EventBox ();
        this.image_box.visible_window = false;
        this.image_box.above_child = true;
        this.image_box.halign = Gtk.Align.END;
        this.image_box.valign = Gtk.Align.START;
        this.image_box.margin_right = 12;

        this.image = new Gtk.Image ();
        this.spinner = new Gtk.Spinner ();

        this.spinner.halign = Gtk.Align.CENTER;
        this.spinner.valign = Gtk.Align.CENTER;

        this.primary_text_label.margin_bottom = 12;
        this.secondary_text_label.margin_bottom = 18;
        this.primary_text_label.valign = secondary_text_label.valign = Gtk.Align.START;
        this.primary_text_label.vexpand = secondary_text_label.vexpand = false;

        this.action_button_box.valign = Gtk.Align.START;
        this.action_button_box.vexpand = false;
        this.action_button_box.spacing = 6;

        this.content_grid = new Gtk.Grid ();
        this.content_grid.attach (this.image_box, 1, 1, 1, 3);
        this.content_grid.attach (this.primary_text_label, 2, 1, 1, 1);
        this.content_grid.attach_next_to (this.secondary_text_label, this.primary_text_label,
                                          Gtk.PositionType.BOTTOM, 1, 1);
        this.content_grid.attach_next_to (this.action_button_box, this.secondary_text_label,
                                          Gtk.PositionType.BOTTOM, 1, 1);

        content_grid.halign = content_grid.valign = Gtk.Align.CENTER;
        content_grid.margin = MARGIN;

        this.add (content_grid);

        // INIT WIDGETS. We use these setters to avoid code duplication
        this.image_size = 64;
        this.working = false;
        this.set_alert ("", "", null, false);
    }

    public override void get_preferred_width (out int minimum_width, out int natural_width) {
        base.get_preferred_width (out minimum_width, out natural_width);
        natural_width = MAX_WIDTH;
    }

    /** PUBLIC API **/

    /**
     * Convenient method that allows setting all the widget properties at once, instead of making
     * single calls to set_primary_text(), set_secondary_text(), show_icon, etc. These are called
     * for you internally. Using this method is recommended when you plan to destroy the widget
     * after the user makes a choice, or if you want to re-use the alert to display completely
     * different information, which is often the case.
     */
    public void set_alert (string primary_text, string secondary_text, Gtk.Action[] ? actions = null,
                            bool show_icon = true, Gtk.MessageType type = Gtk.MessageType.WARNING)
    {
        // Reset size request
        set_size_request (0, 0);

        this.primary_text = primary_text;
        this.secondary_text = secondary_text;
        this.actions = actions;
        this.message_type = type;

        this.show_icon = show_icon;
    }

    /* INTERNALS */

    private void set_image_box_visible (bool visible) {
        set_widget_visible (image_box, visible);
        update_text_layout (visible);
    }

    private void update_text_layout (bool show_icon) {
        // Whenever show_icon is true, the title has to be left-aligned. This also
        // applies to the spinner
        if (show_icon) {
            primary_text_label.halign = secondary_text_label.halign = Gtk.Align.START;
            primary_text_label.justify = Gtk.Justification.LEFT;
            secondary_text_label.justify = Gtk.Justification.FILL;

            action_button_box.set_layout (Gtk.ButtonBoxStyle.END);
            action_button_box.halign = Gtk.Align.END;
        }
        else {
            primary_text_label.halign = secondary_text_label.halign = Gtk.Align.CENTER;
            primary_text_label.justify = secondary_text_label.justify = Gtk.Justification.CENTER;

            action_button_box.set_layout (Gtk.ButtonBoxStyle.CENTER);
            action_button_box.halign = Gtk.Align.CENTER;
        }
    }


    /** Utility functions **/

    private static string get_icon_name_for_message_type (Gtk.MessageType message_type) {
        switch (message_type) {
            case Gtk.MessageType.ERROR:
                return "dialog-error";
            case Gtk.MessageType.WARNING:
                return "dialog-warning";
            case Gtk.MessageType.QUESTION:
                return "dialog-question";
            default:
                return "dialog-information";
        }
    }

    private static void set_widget_visible (Gtk.Widget widget, bool visible) {
        widget.set_no_show_all (!visible);
        if (visible)
            widget.show_all ();
        else
            widget.hide ();
    }

    private static Gtk.Button new_button_from_action (Gtk.Action action) {
        bool has_label = action.label != null;
        bool has_stock = action.stock_id != null;
        bool has_gicon = action.gicon != null;
        bool has_tooltip = action.tooltip != null;

        Gtk.Button action_button;

        // Prefer label over stock_id
        if (has_label) {
            action_button = new Gtk.Button.with_label (action.label);
            // Most time it results convenient to listen for label changes on the action item
            action.notify["label"].connect ( () => {
                action_button.label = action.label;
            });
        } else if (has_stock) {
            action_button = new Gtk.Button.from_stock (action.stock_id);
        } else {
            action_button = new Gtk.Button ();
        }

        // Prefer stock_id over gicon
        if (has_stock)
            action_button.set_image (new Gtk.Image.from_stock (action.stock_id, Gtk.IconSize.BUTTON));
        else if (has_gicon)
            action_button.set_image (new Gtk.Image.from_gicon (action.gicon, Gtk.IconSize.BUTTON));

        if (has_tooltip)
            action_button.set_tooltip_text (action.tooltip);

        // Trigger action on click
        action_button.clicked.connect ( () => {
            action.activate ();
        });

        return action_button;
    }
}
