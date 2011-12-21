using Gtk;

public class BeatBox.WarningLabel : EventBox {

	private Box content;

	private Label errorLabel;
	private Image warningIcon;

	public bool show_icon {
		get {
			return warningIcon.visible;
		}
		set {
			warningIcon.set_no_show_all (!value);
			warningIcon.set_visible (value);
		}
	}
	
	public WarningLabel() {
		errorLabel = new Label("");
		warningIcon = new Image.from_stock (Gtk.Stock.DIALOG_WARNING, Gtk.IconSize.DIALOG);
		
		content = new Box (Orientation.VERTICAL, 10);
		var outer_box = new Box (Orientation.VERTICAL, 0);
		var top_padding = new Box (Orientation.VERTICAL, 0);
		var bottom_padding = new Box (Orientation.VERTICAL, 0);

		content.pack_start (warningIcon, false, false, 10);
		content.pack_start (errorLabel, false, true, 0);

		outer_box.pack_start (top_padding, true, true, 0);
		outer_box.pack_start (content, false, true, 10);
		outer_box.pack_start (bottom_padding, true, true, 0);

		add(outer_box);
		
		Gdk.Color c = Gdk.Color();
		Gdk.Color.parse("#FFFFFF", out c);
		modify_bg(StateType.NORMAL, c);
		
		errorLabel.xalign = 0.5f;
		errorLabel.set_justify(Justification.CENTER);
		errorLabel.ellipsize = Pango.EllipsizeMode.END;
	}
	
	public void setWarning(string warning) {
		errorLabel.set_markup(warning);
	}
}
