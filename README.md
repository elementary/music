# Music
[![Translation status](https://l10n.elementary.io/widgets/music/-/svg-badge.svg)](https://l10n.elementary.io/projects/music/?utm_source=widget)

![Screenshot](data/screenshot.png?raw=true)

## Building, Testing, and Installation

You'll need the following dependencies:
* meson
* libaccounts-glib-dev
* libclutter-gtk-1.0-dev
* libdbus-glib-1-dev
* libgda-5.0-dev
* libgee-0.8-dev
* libglib2.0-dev
* libgpod-dev
* libgranite-dev
* libsignon-glib-dev >= 2.0
* libgstreamer1.0-dev
* libgstreamer-plugins-base1.0-dev
* libgtk-3-dev >= 3.22
* libjson-glib-dev
* libnotify-dev
* libpeas-dev
* libsoup2.4-dev
* libtagc0-dev
* libxml2-dev
* libzeitgeist-2.0-dev
* valac

It's recommended to create a clean build environment. Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `io.elementary.music`

    sudo ninja install
    io.elementary.music

You can run tests with `ninja test`, and reset the build environment with `ninja clean`.

You can use these options to configure your build:
* `build-plugins`: `true` to build plugins or `false` to ony compile the core and the application
* `plugins`: any of `lastfm`, `audioplayer`, `cdrom` and `ipod`, separated by commas
* `prefix`: the installation prefix

To define their values, use `meson configure`

    # For instance, if you want to disable plugins:
    meson configure -Dbuild-plugins=false

## Developer Docs

Music includes valadoc documentation for developers, to autogenerate them from git master enable valadoc:

    meson configure -Ddocumentation=true

The compiled documentation in html format will appear in build/docs when you run ninja. Be aware that creating docs is very slow and it's a good idea to disable building them when you're not using them.

