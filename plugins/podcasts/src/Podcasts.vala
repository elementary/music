public class Noise.Plugins.Podcasts : Noise.Plugins.Activatable, Object
{
    public Iface object { set; owned get; }
    public void activate () {
        print ("Hello World!\n");
    }
    public void deactivate () {
        print ("Bye World!\n");
    }
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module) {
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type (typeof (Noise.Plugins.Activatable),
                                     typeof (Noise.Plugins.Podcasts));
}
