project(
  'io.elementary.music',
  'vala', 'c',
  version: '7.0.0'
)

i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

gstreamer_dep = dependency('gstreamer-1.0')
gstreamer_tag_dep = dependency('gstreamer-tag-1.0')
gtk_dep = dependency('gtk4')

dependencies = [
    gstreamer_dep,
    gstreamer_tag_dep,
    gtk_dep,
]

subdir('data')
subdir('po')
subdir('src')
