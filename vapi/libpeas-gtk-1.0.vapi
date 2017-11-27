/* libpeas-gtk-1.0.vapi generated by vapigen, do not modify. */

[CCode (cprefix = "PeasGtk", gir_namespace = "PeasGtk", gir_version = "1.0", lower_case_cprefix = "peas_gtk_")]
namespace PeasGtk {
    [CCode (cheader_filename = "libpeas-gtk/peas-gtk.h", type_id = "peas_gtk_plugin_manager_get_type ()")]
    public class PluginManager : Gtk.Box, Atk.Implementor, Gtk.Buildable, Gtk.Orientable {
        [CCode (has_construct_function = false, type = "GtkWidget*")]
        public PluginManager (Peas.Engine? engine);
        public unowned Gtk.Widget get_view ();
        [NoAccessorMethod]
        public Peas.Engine engine { owned get; construct; }
        public PeasGtk.PluginManagerView view { get; construct; }
    }
    [CCode (cheader_filename = "libpeas-gtk/peas-gtk.h", type_id = "peas_gtk_plugin_manager_view_get_type ()")]
    public class PluginManagerView : Gtk.TreeView, Atk.Implementor, Gtk.Buildable, Gtk.Scrollable {
        [CCode (has_construct_function = false, type = "GtkWidget*")]
        public PluginManagerView (Peas.Engine? engine);
        public unowned Peas.PluginInfo get_selected_plugin ();
        [Version (deprecated = true, deprecated_since = "1.2")]
        public bool get_show_builtin ();
        public void set_selected_plugin (Peas.PluginInfo info);
        [Version (deprecated = true, deprecated_since = "1.2")]
        public void set_show_builtin (bool show_builtin);
        [NoAccessorMethod]
        public Peas.Engine engine { owned get; construct; }
        [Version (deprecated = true, deprecated_since = "1.2")]
        public bool show_builtin { get; set; }
        public virtual signal void populate_popup (Gtk.Menu menu);
    }
    [CCode (cheader_filename = "libpeas-gtk/peas-gtk.h", type_cname = "PeasGtkConfigurableInterface", type_id = "peas_gtk_configurable_get_type ()")]
    public interface Configurable : GLib.Object {
        public abstract Gtk.Widget create_configure_widget ();
    }
}
