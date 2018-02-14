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

shared_module(
  'lastfm',
  lastfm_files,
  dependencies: lastfm_deps,
  install: true,
  install_dir: plugindir
)

install_data('noise-lastfm.application', install_dir: join_paths(datadir, 'accounts', 'applications'))
