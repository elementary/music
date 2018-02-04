/**
* A view which itself contains multiples views.
*
* It is controlled by the view selector in the header bar.
*
* Its children don't need to define a category, only an ID, icon and title.
*/
public class Noise.SwitchableView : View {
    public Gtk.Stack stack { get; private set; }

    public Gee.ArrayList<View> children { get; set; }

    construct {
        children = new Gee.ArrayList<View> ();

        stack = new Gtk.Stack ();
        add (stack);
    }

    /**
    * Add a child view
    */
    public void add_view (View view) {
        children.add (view);
        stack.add_titled (view, view.id, view.title);
    }

    public override bool filter (string search) {
        return ((View)stack.visible_child).filter (search);
    }
}
