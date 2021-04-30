project(
  'io.elementary.music',
  'vala', 'c',
  version: '7.0.0'
)

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

gtk_dep = dependency('gtk+-3.0')
granite_dep = dependency('granite', version: '>=6.0.0')
handy_dep = dependency('libhandy-1', version: '>=1.0.0')

dependencies = [
    gtk_dep,
    granite_dep,
    handy_dep,
]

subdir('src')
