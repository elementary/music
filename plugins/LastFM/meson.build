lastfm_dir = join_paths(plugindir, 'LastFM')

lastfm_deps = [
  app_dep,
  dependency('json-glib-1.0'),
  dependency('libsoup-2.4'),
  dependency('libaccounts-glib'),
  dependency('libgsignon-glib')
]

lastfm_files = files(
  'LastFM.vala',
  'Core.vala',
  'Tag.vala',
  'SimilarMedia.vala',
  'SimilarMediaView.vala'
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
