project(
  'io.elementary.music',
  'vala', 'c',
  version: '8.0.0',
  meson_version: '>=0.58.0'
)

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

adw_dep = dependency('libadwaita-1', version: '>=1.4.0')
granite_dep = dependency('granite-7')
gstreamer_dep = dependency('gstreamer-1.0')
gstreamer_pbutils_dep = dependency('gstreamer-pbutils-1.0')
gstreamer_tag_dep = dependency('gstreamer-tag-1.0')
gtk_dep = dependency('gtk4')

dependencies = [
    adw_dep,
    granite_dep,
    gstreamer_dep,
    gstreamer_pbutils_dep,
    gstreamer_tag_dep,
    gtk_dep
]

gnome.post_install(glib_compile_schemas: true)

subdir('data')
subdir('po')
subdir('src')
