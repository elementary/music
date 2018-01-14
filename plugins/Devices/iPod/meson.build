ipod_dir = join_paths(plugindir, 'iPod-Device')

ipod_files = files(
  'iPod.vala',
  'iPodLibrary.vala',
  'iPodDevice.vala',
  'iPodDeviceManager.vala',
  'iPodStreamer.vala',
  'iPodMediaHelper.vala',
  'iPodPlaylistHelper.vala'
)

library(
  'ipod-device',
  app_files + ipod_files,
  dependencies: app_deps + [ dependency('libgpod-1.0') ],
  install: true,
  install_dir: ipod_dir
)

install_data('ipod-device.plugin', install_dir: ipod_dir)
