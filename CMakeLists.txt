

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.26" MINIMUM)
include (ValaPrecompile)

set (DEPS_LIBRARIES ${DEPS_LIBRARIES} -lm)
add_subdirectory (core)

# 'src' and 'plugins' depend on the core library
include_directories (${CMAKE_BINARY_DIR}/core)
set (DEPS_LIBRARIES ${DEPS_LIBRARIES} ${CORE_LIBRARY_NAME})

add_subdirectory (src)
add_subdirectory (plugins)
add_subdirectory (po)
add_subdirectory (data)
add_subdirectory (images)


# Tests

add_test (core core/tests/${CORE_LIBRARY_NAME}_tests)
