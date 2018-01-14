cdrom_dir = join_paths(plugindir, 'CDRom-Device')

cdrom_files = files(
  'CDRom.vala',
  'CDRomDevice.vala',
  'CDRomDeviceManager.vala',
  'CDDA.vala',
  'CDRipper.vala',
  'CDPlayer.vala',
  'CDViewWrapper.vala',
  'CDView.vala'
)

library(
  'cdrom-device',
  app_files + cdrom_files,
  dependencies: app_deps,
  install: true,
  install_dir: cdrom_dir
)

install_data('cdrom-device.plugin', install_dir: cdrom_dir)
