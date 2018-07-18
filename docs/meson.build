valadoc = find_program('valadoc')

basic_command = [
    valadoc,
    '--force',
    '--verbose',
    '--package-name',meson.project_name(),
    '--package-version', meson.project_version(),
    '--driver', meson.get_compiler('vala').version(),
    '--pkg', 'gee-0.8',
    '--pkg', 'gio-2.0',
    '--pkg', 'glib-2.0',
    '--pkg', 'gobject-2.0',
    '--pkg', 'libpeas-1.0',
    '--pkg', 'libpeas-gtk-1.0',
    '--pkg', 'granite',
    '--pkg', 'gstreamer-1.0',
    '--pkg', 'gstreamer-pbutils-1.0',
    '--pkg', 'gstreamer-tag-1.0',
    '--pkg', 'gtk+-3.0',
    '--pkg', 'libgda-5.0',
    '--pkg', 'taglib_c',
    '--pkg', 'zeitgeist-2.0',
    '--vapidir=' + join_paths(meson.source_root(), 'vapi'),
    '--importdir=' + join_paths(get_option('prefix'), get_option('datadir'), 'gtk-doc', 'html'),
    '--doclet=html',
    '--use-svg-images'
]

doc_target = custom_target(
    'core documentation',
    command: [
        basic_command,
        '-o', '@OUTPUT@',
        '@INPUT@'
    ],
    build_by_default: true,
    input: core_files,
    output: 'core'
)

all_doc_target = custom_target(
    'full documentation',
    command: [
        basic_command,
        '--internal',
        '-o', '@OUTPUT@',
        '@INPUT@'
    ],
    build_by_default: true,
    input: core_files + app_files,
    output: 'full'
)
