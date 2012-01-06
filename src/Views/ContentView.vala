using Gee;

public interface BeatBox.ContentView : Gtk.ScrolledWindow {
	
	public signal void import_requested(LinkedList<int> to_import);
	
	public abstract void set_hint(ViewWrapper.Hint hint);
	public abstract ViewWrapper.Hint get_hint();
	public abstract void set_relative_id(int id);
	public abstract int get_relative_id();
	
	public abstract void set_show_next(Collection<int> medias);
	public abstract void populate_view();
	public abstract void set_as_current_list(int media_id, bool is_initial);
	public abstract void set_statusbar_text();
	
	public abstract void set_is_current(bool val);
	public abstract bool get_is_current();
	public abstract void set_is_current_view(bool val);
	public abstract bool get_is_current_view();
	
	public abstract Collection<int> get_medias();
	public abstract Collection<int> get_showing_medias();
	
	public abstract void update_medias(Collection<int> medias); // request to update displayed information
}
