core_name = meson.project_name() + '-core'
core_version = '0.1'

config = configuration_data()
config.set('APP_ID', meson.project_name())
config.set('EXEC_NAME', meson.project_name())
config.set('DATADIR', datadir)
config.set('GETTEXT_PACKAGE', meson.project_name())
config.set('VERSION', meson.project_version())
config.set('PLUGINDIR', plugindir)
build_config = configure_file(input : 'Config.vala.in', output: '@BASENAME@', configuration: config)

core_files = files(
  'Album.vala',
  'EqualizerPreset.vala',
  'LibrariesManager.vala',
  'Library.vala',
  'LibraryWindowInterface.vala',
  'Media.vala',
  'NotificationManager.vala',
  'PluginInterface.vala',
  'PluginManager.vala',
  'Resources.vala',
  'Settings.vala',
  'Devices/Device.vala',
  'Devices/DeviceManager.vala',
  'Devices/NetworkDevice.vala',
  'GStreamer/Pipeline.vala',
  'GStreamer/Equalizer.vala',
  'GStreamer/Playback.vala',
  'Playlists/Playlist.vala',
  'Playlists/SmartPlaylist.vala',
  'Playlists/SmartQuery.vala',
  'Playlists/StaticPlaylist.vala',
  'Utils/CompareFunctionHolder.vala',
  'Utils/FileUtils.vala',
  'Utils/Icon.vala',
  'Utils/PlaylistsUtils.vala',
  'Utils/Search.vala',
  'Utils/String.vala',
  'Utils/TimeUtils.vala',
  'Widgets/AlbumImage.vala',
  join_paths(meson.build_root(), '@0@'.format(build_config))
)

core_deps = [
  dependency('gee-0.8'),
  dependency('gio-2.0'),
  dependency('glib-2.0', version: '>=2.39'),
  dependency('gobject-2.0'),
  dependency('libpeas-1.0'),
  dependency('libpeas-gtk-1.0'),
  dependency('granite', version: '>=0.5'),
  dependency('gstreamer-1.0'),
  dependency('gstreamer-pbutils-1.0'),
  dependency('gstreamer-tag-1.0'),
  dependency('gtk+-3.0', version: '>=3.22')
]

core_lib = shared_library(
  core_name,
  core_files,
  version: core_version,
  dependencies: core_deps,
  install: true,
  install_dir: [true, true, true]
)

install_data('@0@.deps'.format(core_name), install_dir: join_paths('share', 'vala', 'vapi'))

core = declare_dependency(include_directories: include_directories('.'), link_with: core_lib)

pkgconfig = import('pkgconfig')
pkgconfig.generate(
  requires: 'glib-2.0 gobject-2.0 gio-2.0 libpeas-1.0 libpeas-gtk-1.0 gtk+-3.0 granite gstreamer-1.0 gstreamer-pbutils-1.0 gstreamer-tag-1.0',
  libraries: core_lib,
  version: meson.project_version(),
  name: 'elementary Music core',
  filebase: core_name,
  description: 'Library to write plugins for elementary Music'
)

subdir('Tests')
