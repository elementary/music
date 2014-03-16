prefix=@PREFIX@
exec_prefix=@DOLLAR@{prefix}
libdir=@DOLLAR@{prefix}/@CMAKE_INSTALL_LIBDIR@
includedir=@DOLLAR@{prefix}/@CMAKE_INSTALL_INCLUDEDIR@/
plugindir=@DOLLAR@{prefix}/@PLUGIN_DIR_UNPREFIXED@
 
Name: Noise
Description: Noise headers  
Version: @VERSION@  
Libs: -lnoise-core
Cflags: -I@DOLLAR@{includedir}/noise-core
Requires: glib-2.0 gio-2.0 gee-0.8 libpeas-1.0 libpeas-gtk-1.0 gtk+-3.0 granite gstreamer-1.0 gstreamer-pbutils-1.0 gstreamer-tag-1.0