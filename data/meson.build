icon_sizes = ['16', '24', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        join_paths('icons', i, 'multimedia-audio-player.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
    )
    install_data(
        join_paths('icons', i, 'multimedia-audio-player.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2', 'apps')
    )
endforeach

gnome = import('gnome')
icon_res = gnome.compile_resources(
  'music-icon-resources',
  files('icons/icons.gresource.xml'),
  source_dir: [ join_paths(meson.source_root(), 'data', 'icons') ]
)

install_data(
    meson.project_name() + '.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

i18n = import('i18n')
desktop_file = i18n.merge_file(
    'desktop',
    input: meson.project_name() + '.desktop.in',
    output: meson.project_name() + '.desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications'),
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    type: 'desktop'
)

appdata_file = i18n.merge_file(
    'appdata',
    input: meson.project_name() + '.appdata.xml.in',
    output: meson.project_name() + '.appdata.xml',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo'),
    po_dir: join_paths(meson.source_root(), 'po', 'extra')
)

test(
    'Validate desktop file',
    find_program('desktop-file-validate'),
    args: desktop_file
)

test(
    'Validate appdata file',
    find_program('appstreamcli'),
    args: ['validate', appdata_file]
)
