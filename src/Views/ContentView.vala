using Gee;

public interface BeatBox.ContentView : Gtk.ScrolledWindow {
	
	public abstract void set_hint(ViewWrapper.Hint hint);
	public abstract ViewWrapper.Hint get_hint();
	public abstract void set_relative_id(int id);
	public abstract int get_relative_id();
	
	public abstract void set_show_next(Collection<int> songs);
	public abstract void populate_view();
	public abstract void set_as_current_list(int song_id, bool is_initial);
	public abstract void set_statusbar_text();
	
	public abstract void set_is_current(bool val);
	public abstract bool get_is_current();
	public abstract void set_is_current_view(bool val);
	public abstract bool get_is_current_view();
	
	public abstract Collection<int> get_songs();
	public abstract Collection<int> get_showing_songs();
	
	public abstract void update_songs(Collection<int> songs); // request to update displayed information
}
