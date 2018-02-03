public class Noise.Category : Object {
    public string name { get; construct set; }
    public string id { get; construct set; }

    public Category (string id, string name) {
        Object (id: id, name: name);
    }

    public signal void remove ();
    public signal void hide ();
    public signal void show ();
}
