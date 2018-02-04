/**
* A category, grouping multiples views together
*/
public class Noise.Category : Object {

    /**
    * The name of this category
    */
    public string name { get; construct set; }

    /**
    * The ID of this category.
    */
    public string id { get; construct set; }

    /**
    * Creates a new category. Register it with {@link Noise.ViewManager.add_manager}
    */
    public Category (string id, string name) {
        Object (id: id, name: name);
    }

    /**
    * Emitted when this category is removed
    */
    public signal void remove ();

    /**
    * Emitted when this category is hidden
    */
    public signal void hide ();

    /**
    * Emitted when this category gets displayed
    */
    public signal void show ();
}
