tests_name = app_name + '-tests'

config = configuration_data()
config.set('source_dir', meson.source_root())
tests_conf = configure_file(input : 'Config.vala', output: 'Config.vala', configuration: config)

tests_files = files(
  join_paths(meson.build_root(), '@0@'.format(tests_conf)),
  'Tests.vala'
)

tests_deps = core_deps + [ core ]

tests = executable(
  tests_name,
  tests_files,
  dependencies: tests_deps
)

test('Core tests', tests)
