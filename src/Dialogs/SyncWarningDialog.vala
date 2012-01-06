using Gtk;
using Gee;

public class BeatBox.SyncWarningDialog : Window {
	LibraryManager lm;
	LibraryWindow lw;
	Device d;
	LinkedList<int> to_sync;
	LinkedList<int> to_remove;
	
	private VBox content;
	private HBox padding;
	
	Button importMedias;
	Button sync;
	Button cancel;
	
	public SyncWarningDialog(LibraryManager lm, LibraryWindow lw, Device d, LinkedList<int> to_sync, LinkedList<int> removed) {
		this.lm = lm;
		this.lw = lw;
		this.d = d;
		this.to_sync = to_sync;
		this.to_remove = removed;
		
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
		importMedias = new Button.with_label("Import medias to Library");
		sync = new Button.with_label("Continue Syncing");
		cancel = new Button.with_label("Stop Syncing");
		
		// pretty up labels
		title.xalign = 0.0f;
		title.set_markup("<span weight=\"bold\" size=\"larger\">Sync will remove " + to_remove.size.to_string() + " medias from " + d.getDisplayName() + "</span>");
		info.xalign = 0.0f;
		info.set_line_wrap(true);
		info.set_markup("If you continue to sync, medias will be removed from " + d.getDisplayName() + " since they are not on the sync list. Would you like to import them to your library first?");
		
		importMedias.set_sensitive(!lm.doing_file_operations());
		sync.set_sensitive(!lm.doing_file_operations());
		
		/* set up controls layout */
		HBox information = new HBox(false, 0);
		VBox information_text = new VBox(false, 0);
		information.pack_start(warning, false, false, 10);
		information_text.pack_start(title, false, true, 10);
		information_text.pack_start(info, false, true, 0);
		information.pack_start(information_text, true, true, 10);
		
		HButtonBox bottomButtons = new HButtonBox();
		bottomButtons.set_layout(ButtonBoxStyle.END);
		bottomButtons.pack_end(importMedias, false, false, 0);
		bottomButtons.pack_end(sync, false, false, 0);
		bottomButtons.pack_end(cancel, false, false, 10);
		bottomButtons.set_spacing(10);
		
		content.pack_start(information, false, true, 0);
		content.pack_start(bottomButtons, false, true, 10);
		
		padding.pack_start(content, true, true, 10);
		
		importMedias.clicked.connect(importMediasClicked);
		sync.clicked.connect(syncClicked);
		cancel.clicked.connect( () => { 
			this.destroy(); 
		});
		
		lm.file_operations_started.connect(file_operations_started);
		lm.file_operations_done.connect(file_operations_done);
		
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
	
	public void importMediasClicked() {
		d.transfer_to_library(to_remove);
		// TODO: After transfer, do sync
		
		this.destroy();
	}
	
	public void syncClicked() {
		d.sync_medias(to_sync);
		
		this.destroy();
	}
	
	public void file_operations_done() {
		importMedias.set_sensitive(true);
		sync.set_sensitive(true);
	}
	
	public void file_operations_started() {
		importMedias.set_sensitive(false);
		sync.set_sensitive(false);
	}
	
}
