# check http://elementaryos.org/docs/developer-guide/cmake/simple-project

cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.8)
project (noise C)
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

enable_testing()

set (GETTEXT_PACKAGE ${CMAKE_PROJECT_NAME})
set (RELEASE_NAME "Luna")
set (VERSION "0.4.2")
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

option (BUILD_SHARED_LIBS "Switch between shared and static libraries" ON)
option (BUILD_FOR_ELEMENTARY "Noise name will be replaced by Music" ON)

set (APP_NAME "Noise")
if (BUILD_FOR_ELEMENTARY)
    set (APP_NAME "Music")
endif ()

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
  glib-2.0>=2.39
  gio-2.0
  gee-0.8
  libpeas-1.0
  libpeas-gtk-1.0
  gtk+-3.0>=3.11.6
  granite>=0.5
  gstreamer-1.0
  gstreamer-tag-1.0
  gstreamer-pbutils-1.0
)

set (DEPS_PACKAGES
  ${CORE_LIBRARY_NAME}
  ${CORE_PACKAGES} # this is needed until we provide a ${CORE_LIBRARY_NAME}.deps file
  libgda-5.0
  taglib_c
  zeitgeist-2.0
)

set (DEPS_PKG
  libgda-5.0
  taglib_c
  zeitgeist-2.0
)

find_package (PkgConfig)

pkg_check_modules (CORE_DEPS REQUIRED ${CORE_PKG})
pkg_check_modules (DEPS REQUIRED ${DEPS_PKG} ${CORE_PKG})

set (BASIC_VALAC_OPTIONS
  --vapidir=${CMAKE_SOURCE_DIR}/vapi
  --target-glib=2.39
  --thread
)

set (GLOBAL_VALAC_OPTIONS
  --vapidir=${CMAKE_BINARY_DIR}/core
  --vapidir=${CMAKE_BINARY_DIR}/src
  ${BASIC_VALAC_OPTIONS}
)

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.26" MINIMUM)
include (ValaPrecompile)

set (DEPS_LIBRARIES ${DEPS_LIBRARIES} -lm)
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
include (CTest)
if (BUILD_TESTING)
    add_test (core core/tests/noise-core_tests)
    add_test (NAME validate-desktop-file COMMAND desktop-file-validate ${CMAKE_BINARY_DIR}/data/org.pantheon.noise.desktop)
    add_test (NAME validate-appdata COMMAND appstreamcli validate ${CMAKE_BINARY_DIR}/data/org.pantheon.noise.appdata.xml)
endif ()
