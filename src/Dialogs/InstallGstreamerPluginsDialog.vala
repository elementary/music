using Gtk;
using Gee;

public class BeatBox.InstallGstreamerPluginsDialog : Window {
	LibraryManager lm;
	LibraryWindow lw;
	Gst.Message message;
	string detail;
	
	private VBox content;
	private HBox padding;
	
	Button installPlugin;
	Button doNothing;
	
	public InstallGstreamerPluginsDialog(LibraryManager lm, LibraryWindow lw, Gst.Message message) {
		this.lm = lm;
		this.lw = lw;
		this.message = message;
		this.detail = Gst.missing_plugin_message_get_description(message);
		
		this.set_title("BeatBox");
		
		// set the size based on saved gconf settings
		//this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(lw);
		this.destroy_with_parent = true;
		
		set_default_size(475, -1);
		resizable = false;
		
		content = new VBox(false, 10);
		padding = new HBox(false, 20);
		
		// initialize controls
		Image warning = new Image.from_stock(Gtk.Stock.DIALOG_ERROR, Gtk.IconSize.DIALOG);
		Label title = new Label("");
		Label info = new Label("");
		installPlugin = new Button.with_label("Install Plugin");
		doNothing = new Button.with_label("Do Nothing");
		
		// pretty up labels
		title.xalign = 0.0f;
		title.set_markup("<span weight=\"bold\" size=\"larger\">Required GStreamer plugin not installed</span>");
		info.xalign = 0.0f;
		info.set_line_wrap(false);
		info.set_markup("The plugin for media type \"<b>" + detail + "</b>\" is not installed.\n What would you like to do?");
		
		/* set up controls layout */
		HBox information = new HBox(false, 0);
		VBox information_text = new VBox(false, 0);
		information.pack_start(warning, false, false, 10);
		information_text.pack_start(title, false, true, 10);
		information_text.pack_start(info, false, true, 0);
		information.pack_start(information_text, true, true, 10);
		
		HButtonBox bottomButtons = new HButtonBox();
		bottomButtons.set_layout(ButtonBoxStyle.END);
		bottomButtons.pack_end(installPlugin, false, false, 0);
		bottomButtons.pack_end(doNothing, false, false, 10);
		bottomButtons.set_spacing(10);
		
		content.pack_start(information, false, true, 0);
		content.pack_start(bottomButtons, false, true, 10);
		
		padding.pack_start(content, true, true, 10);
		
		installPlugin.clicked.connect(installPluginClicked);
		doNothing.clicked.connect( () => { this.destroy(); });
		
		add(padding);
		show_all();
	}
	
	public static Gtk.Alignment wrap_alignment (Gtk.Widget widget, int top, int right, int bottom, int left) {
		var alignment = new Gtk.Alignment(0.0f, 0.0f, 1.0f, 1.0f);
		alignment.top_padding = top;
		alignment.right_padding = right;
		alignment.bottom_padding = bottom;
		alignment.left_padding = left;
		
		alignment.add(widget);
		return alignment;
	}
	
	public void installPluginClicked() {
		var installer = Gst.missing_plugin_message_get_installer_detail(message);
		var context = new Gst.InstallPluginsContext();
			
		Gst.install_plugins_async({installer}, context, (Gst.InstallPluginsResultFunc)install_plugins_finished);
		
		this.hide();
	}
	
	public void install_plugins_finished(Gst.InstallPluginsReturn result) {
		stdout.printf("install of plugins finished.. updating registry\n");
		Gst.update_registry();
	}
	
}
