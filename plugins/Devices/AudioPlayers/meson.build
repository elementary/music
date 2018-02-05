audioplayer_dir = join_paths(plugindir, 'AudioPlayer-Device')

audioplayer_files = files(
  'AudioPlayer.vala',
  'AudioPlayerDevice.vala',
  'AudioPlayerDeviceManager.vala',
  'AudioPlayerLibrary.vala'
)

library(
  'audioplayer-device',
  audioplayer_files,
  dependencies: [ app_dep ],
  install: true,
  install_dir: audioplayer_dir
)

install_data('audioplayer-device.plugin', install_dir: audioplayer_dir)
