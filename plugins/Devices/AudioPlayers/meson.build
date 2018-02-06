audioplayer_files = files(
  'AudioPlayer.vala',
  'AudioPlayerDevice.vala',
  'AudioPlayerDeviceManager.vala',
  'AudioPlayerLibrary.vala'
)

shared_module(
  'audioplayer-device',
  audioplayer_files,
  dependencies: [ app_dep ],
  install: true,
  install_dir: plugindir
)

install_data('audioplayer-device.plugin', install_dir: plugindir)
