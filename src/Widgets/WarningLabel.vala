using Gtk;

public class BeatBox.WarningLabel : EventBox {
	Label errorLabel;
	
	public WarningLabel() {
		errorLabel = new Label("");
		
		add(errorLabel);
		
		Gdk.Color c = Gdk.Color();
		Gdk.Color.parse("#FFFFFF", out c);
		modify_bg(StateType.NORMAL, c);
		
		errorLabel.xalign = 0.5f;
		errorLabel.justify = Justification.CENTER;
		errorLabel.set_markup("<span weight=\"bold\" size=\"larger\">Similar Song View</span>\nIn this view, BeatBox will automatically find songs similar to the one you are playing.\nYou can then start playing those songs, or save them for later.");
	}
	
	public void setWarning(string warning) {
		errorLabel.set_markup(warning);
	}
}
