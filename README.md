# Music
[![Translation status](https://l10n.elementary.io/widgets/music/-/svg-badge.svg)](https://l10n.elementary.io/projects/music/?utm_source=widget)

## Building, Testing, and Installation

You'll need the following dependencies:
* cmake
* libclutter-gtk-1.0-dev
* libdbusmenu-glib-dev
* libdbusmenu-gtk3-dev
* libdbus-glib-1-dev
* libindicate-dev
* libgee-dev
* libglib2.0-dev
* libgpod-dev
* libgranite-dev
* libgstreamer0.10-dev
* libgstreamer-plugins-base0.10-dev
* libgtk-3-dev
* libjson-glib-dev
* libnotify-dev
* libpeas-dev
* libsoup2.4-dev
* libtagc0-dev
* libwebkitgtk-dev
* libxml2-dev
* libzeitgeist-dev
* valac

It's recommended to create a clean build environment

    mkdir build
    cd build/
    
Run `cmake` to configure the build environment and then `make` to build

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make
    
To install, use `make install`, then execute with `noise`

    sudo make install
    noise
