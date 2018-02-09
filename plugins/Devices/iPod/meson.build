ipod_files = files(
  'iPod.vala',
  'iPodDevice.vala',
  'iPodDeviceManager.vala',
  'iPodLibrary.vala',
  'iPodMediaHelper.vala',
  'iPodPlaylistHelper.vala',
  'iPodStreamer.vala'
)

shared_module(
  'ipod-device',
  ipod_files,
  vala_args: ['--vapidir', join_paths(meson.current_source_dir(), 'vapi')],
  dependencies: [
    app_dep,
    dependency('libgpod-1.0')
  ],
  install: true,
  install_dir: plugindir
)

install_data('ipod-device.plugin', install_dir: plugindir)
