project(
  'io.elementary.music',
  'vala', 'c',
  version: '7.0.0'
)

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

granite_dep = dependency('granite', version: '>=6.0.0')
gstreamer_dep = dependency('gstreamer-1.0')
gstreamer_tag_dep = dependency('gstreamer-tag-1.0')
gtk_dep = dependency('gtk+-3.0')
handy_dep = dependency('libhandy-1', version: '>=1.0.0')

dependencies = [
    granite_dep,
    gstreamer_dep,
    gstreamer_tag_dep,
    gtk_dep,
    handy_dep
]

subdir('data')
subdir('src')
