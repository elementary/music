/* a binding fix for ValueArray's */
[CCode (cname = "g_value_array_free")]
public extern GLib.DestroyNotify value_array_free;
