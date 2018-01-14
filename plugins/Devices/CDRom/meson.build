cdrom_dir = join_paths(plugindir, 'CDRom-Device')

cdrom_files = files(
  'CDDA.vala',
  'CDPlayer.vala',
  'CDRipper.vala',
  'CDRom.vala',
  'CDRomDevice.vala',
  'CDRomDeviceManager.vala',
  'CDView.vala',
  'CDViewWrapper.vala'
)

library(
  'cdrom-device',
  cdrom_files,
  dependencies: [ app_dep ],
  install: true,
  install_dir: cdrom_dir
)

install_data('cdrom-device.plugin', install_dir: cdrom_dir)
