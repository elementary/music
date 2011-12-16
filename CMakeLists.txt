# check http://elementaryos.org/docs/developer-guide/cmake/simple-project

cmake_minimum_required (VERSION 2.6)
cmake_policy(VERSION 2.6)

project(BeatBox)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake )

configure_file(${CMAKE_SOURCE_DIR}/config.h.cmake ${CMAKE_BINARY_DIR}/config.h)
add_definitions(-include config.h)

add_subdirectory(vapi)
add_subdirectory(src)
add_subdirectory(data)
add_subdirectory(images)
add_subdirectory(schemas)
