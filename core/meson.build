core_name = app_name + '-core'

config = configuration_data()
config.set('app_name', short_name)
config.set('datadir', datadir)
config.set('pkg_datadir', pkg_datadir)
config.set('gettext_package', app_name)
config.set('release_name', release_name)
config.set('version', version)
config.set('version_info', version_info)
config.set('icondir', icondir)
config.set('plugindir', plugindir)
configure_file(input : 'Build.vala', output: 'Build.vala', configuration: config)

core_files = files(
  'PluginManager.vala',
  'Settings.vala',
  'EqualizerPreset.vala',
  'LibraryWindowInterface.vala',
  'Library.vala',
  'LibrariesManager.vala',
  'NotificationManager.vala',
  'Media.vala',
  'Album.vala',
  'Resources.vala',
  'Devices/Device.vala',
  'Devices/NetworkDevice.vala',
  'Devices/DeviceManager.vala',
  'Playlists/Playlist.vala',
  'Playlists/StaticPlaylist.vala',
  'Playlists/SmartPlaylist.vala',
  'Playlists/SmartQuery.vala',
  'Utils/FileUtils.vala',
  'Utils/TimeUtils.vala',
  'Utils/String.vala',
  'Utils/CompareFunctionHolder.vala',
  'Utils/PlaylistsUtils.vala',
  'Utils/Icon.vala',
  'Utils/Search.vala',
  'GStreamer/Pipeline.vala',
  'GStreamer/Equalizer.vala',
  'GStreamer/Playback.vala',
  'Widgets/AlbumImage.vala',
  'Build.vala'
)

core_deps = [
  dependency('glib-2.0', version: '>=2.39'),
  dependency('gobject-2.0'),
  dependency('gio-2.0'),
  dependency('gee-0.8'),
  dependency('libpeas-1.0'),
  dependency('libpeas-gtk-1.0'),
  dependency('gtk+-3.0', version: '>=3.11.6'),
  dependency('granite', version: '>=0.5'),
  dependency('gstreamer-1.0'),
  dependency('gstreamer-pbutils-1.0'),
  dependency('gstreamer-tag-1.0')
]

core_lib = library(
  core_name,
  core_files,
  dependencies: core_deps,
  install: true,
  install_dir: [true, true, true]
)

install_data('@0@.deps'.format(core_name), install_dir: 'share/vala/vapi')

core = declare_dependency(include_directories: include_directories('.'), link_with: core_lib)

pkgconfig = import('pkgconfig')
pkgconfig.generate(
  requires: 'glib-2.0 gobject-2.0 gio-2.0 libpeas-1.0 libpeas-gtk-1.0 gtk+-3.0 granite gstreamer-1.0 gstreamer-pbutils-1.0 gstreamer-tag-1.0',
  libraries: core_lib,
  version: version,
  name: 'elementary Music core',
  filebase: core_name,
  description: 'Library to write plugins for elementary Music'
)

subdir('Tests')
