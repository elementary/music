cdrom_files = files(
  'CDDA.vala',
  'CDPlayer.vala',
  'CDRipper.vala',
  'CDRom.vala',
  'CDRomDevice.vala',
  'CDRomDeviceManager.vala',
  'CDView.vala'
)

shared_module(
  'cdrom-device',
  cdrom_files,
  dependencies: [ app_dep ],
  install: true,
  install_dir: plugindir
)

install_data('cdrom-device.plugin', install_dir: plugindir)
