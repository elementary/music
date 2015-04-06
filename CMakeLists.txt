# check http://elementaryos.org/docs/developer-guide/cmake/simple-project

cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.8)
project (noise C)
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

enable_testing()

set (GETTEXT_PACKAGE ${CMAKE_PROJECT_NAME})
set (RELEASE_NAME "Luna")
set (VERSION "0.3.1")
set (VERSION_INFO "Stable Release")

include (GNUInstallDirs)
set (DATADIR ${CMAKE_INSTALL_PREFIX}/share)
set (PKG_DATADIR ${DATADIR}/${CMAKE_PROJECT_NAME})
set (ICON_DIR ${DATADIR}/${CMAKE_PROJECT_NAME}/icons)
set (PLUGIN_DIR_UNPREFIXED ${CMAKE_INSTALL_LIBDIR}/${CMAKE_PROJECT_NAME}/plugins)
set (PLUGIN_DIR ${CMAKE_INSTALL_PREFIX}/${PLUGIN_DIR_UNPREFIXED})

add_definitions ("-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\"")

# Comment this out to enable C compiler warnings
add_definitions (-w)

# Add 'make dist' command for creating release tarball
set (CPACK_PACKAGE_VERSION ${VERSION})
set (CPACK_SOURCE_GENERATOR "TGZ")
set (CPACK_SOURCE_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}-${CPACK_PACKAGE_VERSION}")
set (CPACK_SOURCE_IGNORE_FILES "/build/;/.bzr/;/.bzrignore;~$;${CPACK_SOURCE_IGNORE_FILES}")

include (CPack)
add_custom_target (dist COMMAND ${CMAKE_MAKE_PROGRAM} package_source)

option (BUILD_SHARED_LIBS "Switch between shared and static libraries" ON)

if (BUILD_SHARED_LIBS)
  message ("-- Shared libraries enabled")
else ()
  message ("-- Shared libraries disabled")
endif ()

set (SRC_TARGET ${CMAKE_PROJECT_NAME})
set (CORE_LIBRARY_NAME ${SRC_TARGET}-core)

if (NOT BUILD_SHARED_LIBS)
  set (CORE_LIBRARY_NAME ${CORE_LIBRARY_NAME}-static)
endif ()

#
# *_PACKAGES are used with the vala compiler (not versioned.)
# *_PKG are used with PKG-Config and for linking, etc. (They can contain versions.)
#
# Both should contain *the same packages*, except for those whose VAPI file has
# a different name. In such case, *_PACKAGES would use the name of the VAPI while
# *_PKG would use the name of the package known by pkg-config.
#

set (CORE_PACKAGES
  glib-2.0
  gio-2.0
  gee-0.8
  libpeas-1.0
  libpeas-gtk-1.0
  gtk+-3.0
  granite
  gstreamer-1.0
  gstreamer-pbutils-1.0
  gstreamer-tag-1.0
)

set (CORE_PKG
  glib-2.0>=2.32
  gio-2.0
  gee-0.8
  libpeas-1.0
  libpeas-gtk-1.0
  gtk+-3.0>=3.11.6
  granite
  gstreamer-1.0
  gstreamer-tag-1.0
  gstreamer-pbutils-1.0
)

set (DEPS_PACKAGES
  ${CORE_LIBRARY_NAME}
  ${CORE_PACKAGES} # this is needed until we provide a ${CORE_LIBRARY_NAME}.deps file
  taglib_c
)

set (DEPS_PKG
  taglib_c
)

find_package (PkgConfig)

pkg_check_modules (CORE_DEPS REQUIRED ${CORE_PKG})
pkg_check_modules (DEPS REQUIRED ${DEPS_PKG} ${CORE_PKG})

set (BASIC_VALAC_OPTIONS
  --vapidir=${CMAKE_SOURCE_DIR}/vapi
  --target-glib=2.32
  --thread
  # Remove it when vala bindings are no more experimental (see https://bugzilla.gnome.org/show_bug.cgi?id=719597)
  --enable-experimental
)

set (GLOBAL_VALAC_OPTIONS
  --vapidir=${CMAKE_BINARY_DIR}/core
  --vapidir=${CMAKE_BINARY_DIR}/src
  ${BASIC_VALAC_OPTIONS}
)

#
# SQLHeavy: Use version 0.2 if it is available; otherwise, fall back to 0.1
#
pkg_check_modules (SQLHEAVY2 QUIET sqlheavy-0.2)
if (SQLHEAVY2_FOUND)
  message ("-- Will use sqlheavy-0.2")
  set (DEPS_PACKAGES ${DEPS_PACKAGES} sqlheavy-0.2)
  set (SQLHEAVY_CFLAGS ${SQLHEAVY2_CFLAGS})
  set (SQLHEAVY_LIBRARY_DIRS ${SQLHEAVY2_LIBRARY_DIRS})
  set (SQLHEAVY_LIBRARIES ${SQLHEAVY2_LIBRARIES})
else ()
  message ("-- Will use sqlheavy-0.1")
  pkg_check_modules (SQLHEAVY REQUIRED sqlheavy-0.1)
  set (DEPS_PACKAGES ${DEPS_PACKAGES} sqlheavy-0.1)
endif ()

set (DEPS_CFLAGS ${DEPS_CFLAGS} ${SQLHEAVY_CFLAGS})
set (DEPS_LIBRARIES ${DEPS_LIBRARIES} ${SQLHEAVY_LIBRARIES})
set (DEPS_LIBRARY_DIRS ${DEPS_LIBRARY_DIRS} ${SQLHEAVY_LIBRARY_DIRS})

#
# Libnotify
#
pkg_check_modules (LIBNOTIFY QUIET libnotify)
if (LIBNOTIFY_FOUND)
  message ("-- libnotify enabled")

  set (GLOBAL_VALAC_OPTIONS ${GLOBAL_VALAC_OPTIONS} --define=HAVE_LIBNOTIFY)

  set (DEPS_PACKAGES ${DEPS_PACKAGES} libnotify)

  set (DEPS_CFLAGS ${DEPS_CFLAGS} ${LIBNOTIFY_CFLAGS})
  set (DEPS_LIBRARIES ${DEPS_LIBRARIES} ${LIBNOTIFY_LIBRARIES})
  set (DEPS_LIBRARY_DIRS ${DEPS_LIBRARY_DIRS} ${LIBNOTIFY_LIBRARY_DIRS})
else ()
  message ("-- libnotify disabled")
endif ()

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.26" MINIMUM)
include (ValaPrecompile)

set (DEPS_LIBRARIES ${DEPS_LIBRARIES} -lm)
add_subdirectory (schemas)
add_subdirectory (core)

# 'src' and 'plugins' depend on the core library
include_directories (${CMAKE_BINARY_DIR}/core)
set (DEPS_LIBRARIES ${DEPS_LIBRARIES} ${CORE_LIBRARY_NAME})

add_subdirectory (src)
add_subdirectory (plugins)
add_subdirectory (po)
add_subdirectory (data)
add_subdirectory (images)


# Tests

add_test (core core/tests/noise-core_tests)
