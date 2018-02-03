public class Noise.SwitchableView : View {
    public Gtk.Stack stack { get; private set; }

    public Gee.ArrayList<View> children { get; set; }

    construct {
        children = new Gee.ArrayList<View> ();

        stack = new Gtk.Stack ();
        add (stack);
    }

    public void add_view (View view) {
        children.add (view);
        stack.add_titled (view, view.id, view.title);
    }

    public override bool filter (string search) {
        return ((View)stack.visible_child).filter (search);
    }
}
