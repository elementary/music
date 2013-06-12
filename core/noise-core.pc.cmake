prefix=@PREFIX@
exec_prefix=@DOLLAR@{prefix}
libdir=@DOLLAR@{prefix}/lib
includedir=@DOLLAR@{prefix}/include/
 
Name: Noise
Description: Noise headers  
Version: 0.2  
Libs: -lnoise-core
Cflags: -I@DOLLAR@{includedir}/noise-core
Requires: glib-2.0 gio-2.0 gee-1.0 libpeas-1.0 libpeas-gtk-1.0 gtk+-3.0 granite gstreamer-0.10 gstreamer-interfaces-0.10 gstreamer-tag-0.10 gstreamer-pbutils-0.10

