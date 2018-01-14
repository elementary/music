ipod_dir = join_paths(plugindir, 'iPod-Device')

ipod_files = files(
  'iPod.vala',
  'iPodDevice.vala',
  'iPodDeviceManager.vala',
  'iPodLibrary.vala',
  'iPodMediaHelper.vala',
  'iPodPlaylistHelper.vala',
  'iPodStreamer.vala'
)

library(
  'ipod-device',
  ipod_files,
  dependencies: [
    app_dep,
    dependency('libgpod-1.0')
  ],
  install: true,
  install_dir: ipod_dir
)

install_data('ipod-device.plugin', install_dir: ipod_dir)
