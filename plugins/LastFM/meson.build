lastfm_dir = join_paths(plugindir, 'LastFM')

lastfm_deps = [
  app_dep,
  dependency('json-glib-1.0'),
  dependency('libaccounts-glib'),
  dependency('libgsignon-glib'),
  dependency('libsoup-2.4')
]

lastfm_files = files(
  'Core.vala',
  'LastFM.vala',
  'SimilarMedia.vala',
  'SimilarMediaView.vala',
  'Tag.vala'
)

lastfm = library(
  'lastfm',
  lastfm_files,
  dependencies: lastfm_deps,
  install: true,
  install_dir: lastfm_dir
)

install_data('lastfm.plugin', install_dir: lastfm_dir)

install_data('noise-lastfm.application', install_dir: join_paths(datadir, 'accounts', 'applications'))
