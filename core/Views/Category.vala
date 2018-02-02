public class Noise.Category : Object {
    public string name { get; construct set; }
    public string id { get; construct set; }
    public Icon icon { get; construct set; }

    public Category (string id, string name, Icon icon) {
        Object (id: id, name: name, icon: icon);
    }

    public signal void remove ();
}
