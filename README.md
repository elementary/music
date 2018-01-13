# Music
[![Translation status](https://l10n.elementary.io/widgets/music/-/svg-badge.svg)](https://l10n.elementary.io/projects/music/?utm_source=widget)

## Building, Testing, and Installation

You'll need the following dependencies:
* cmake
* libaccounts-glib-dev
* libclutter-gtk-1.0-dev
* libdbus-glib-1-dev
* libgda-5.0-dev
* libgee-0.8-dev
* libglib2.0-dev
* libgpod-dev
* libgranite-dev
* libgsignon-glib-dev
* libgstreamer1.0-dev
* libgstreamer-plugins-base1.0-dev
* libgtk-3-dev
* libjson-glib-dev
* libnotify-dev
* libpeas-dev
* libsoup2.4-dev
* libtagc0-dev
* libxml2-dev
* libzeitgeist-2.0-dev
* valac

It's recommended to create a clean build environment

    mkdir build
    cd build/

Run `cmake` to configure the build environment and then `make` to build

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make

To install, use `make install`, then execute with `io.elementary.music`

    sudo make install
    io.elementary.music
