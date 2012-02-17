# check http://elementaryos.org/docs/developer-guide/cmake/simple-project

cmake_minimum_required (VERSION 2.6)
cmake_policy(VERSION 2.6)
project(BeatBox)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake )

find_package(PkgConfig)
pkg_check_modules(DEPS
    REQUIRED
    glib-2.0
    gtk+-3.0
    gdk-x11-3.0
    gee-1.0
    gstreamer-0.10
    gstreamer-interfaces-0.10
    gstreamer-pbutils-0.10
    gstreamer-cdda-0.10
    taglib_c
    gio-2.0
    sqlheavy-0.1
    libxml-2.0
    libnotify
    libsoup-2.4
    json-glib-1.0
    gio-unix-2.0
    granite
    libgpod-1.0
    libpeas-gtk-1.0
    libpeas-1.0)
# Check if we have sqlheavy-0.2

if(${SQLHEAVY_USE_2})
pkg_check_modules(SQLHEAVY sqlheavy-0.2)
set(ADD_PKG ${ADD_PKG} sqlheavy-0.2)
message("-- Will use sqlheavy-0.2")
else()
set(ADD_PKG ${ADD_PKG} sqlheavy-0.1)
pkg_check_modules(SQLHEAVY sqlheavy-0.1)
message("-- Will use sqlheavy-0.1")
endif()
pkg_check_modules(ZEITGEIST zeitgeist-1.0)
if(${ZEITGEIST_FOUND})
set(ADD_PKG ${ADD_PKG}
                zeitgeist-1.0)
set(ADD_OPTIONS ${ADD_OPTIONS}
        --define=HAVE_ZEITGEIST)
message("-- Zeitgeist enabled")
else()
message("-- Zeitgeist disabled")
endif()
pkg_check_modules(DBUS_MENU dbusmenu-glib-0.4)
if(${DBUS_MENU_FOUND})
set(ADD_PKG ${ADD_PKG}
        Dbusmenu-0.4)
set(ADD_OPTIONS ${ADD_OPTIONS}
        --define=HAVE_DBUSMENU)
message("-- DBus Menu enabled")
else()
message("-- DBus Menu disabled")
endif()
pkg_check_modules(INDICATE indicate-0.6)
if(${INDICATE_FOUND})
set(ADD_PKG ${ADD_PKG}
        Indicate-0.6)
set(ADD_OPTIONS ${ADD_OPTIONS}
        --define=HAVE_INDICATE)
message("-- Indicate enabled")
else()
message("-- Indicate disabled")
endif()

set (NORMAL_CFLAGS ${DEPS_CFLAGS} ${ZEITGEIST_CFLAGS} ${INDICATE_CFLAGS} ${DBUS_MENU_CFLAGS} ${SQLHEAVY_CFLAGS})
set (NORMAL_LIBRARIES ${DEPS_LIBRARIES} ${ZEITGEIST_LIBRARIES} ${DBUS_MENU_LIBRARIES} ${SQLHEAVY_LIBRARIES} ${INDICATE_LIBRARIES})
set (NORMAL_LINK_DIRS ${ZEITGEIST_LIBRARY_DIRS} ${SQLHEAVY_LIBRARY_DIRS} ${INDICATE_LIBRARY_DIRS} ${DBUS_MENU_LIBRARY_DIRS} ${DEPS_LIBRARY_DIRS})

add_subdirectory(vapi)
add_subdirectory(src)
add_subdirectory(data)
add_subdirectory(images)
add_subdirectory(schemas)
add_subdirectory(po)
add_subdirectory(core)
add_subdirectory(plugins)
