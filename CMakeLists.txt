cmake_minimum_required(VERSION 3.9)
project(aabbcc
  VERSION 0.1.0
  LANGUAGES CXX)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")
set(CMAKE_INCLUDE_CURRENT_DIR ON)
include(GNUInstallDirs) # Define CMAKE_INSTALL_xxx: LIBDIR, INCLUDEDIR

option(AABBCC_BUILD_DEMOS "Build demos" OFF)
mark_as_advanced(AABBCC_BUILD_DEMOS)

option(AABBCC_GENERATE_HEADER_ONLY "Generate a header-only file" OFF)
mark_as_advanced(AABBCC_GENERATE_HEADER_ONLY)

set(aabbcc_include_dir src)
set(header_file_ ${CMAKE_CURRENT_SOURCE_DIR}/src/AABB.h)
set(source_file_ ${CMAKE_CURRENT_SOURCE_DIR}/src/AABB.cc)

add_library(aabbcc ${source_file_})
set(aabbcc_export_file "${PROJECT_BINARY_DIR}/aabbccTargets.cmake")

target_include_directories(aabbcc PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${aabbcc_include_dir}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)

install(TARGETS aabbcc
        EXPORT aabbccTargets
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        )

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/${aabbcc_include_dir}/AABB.h
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/aabbcc)

# export to the build tree
export( TARGETS aabbcc
  NAMESPACE aabbcc::
  APPEND FILE ${aabbcc_export_file})

if(AABBCC_BUILD_DEMOS)
    add_subdirectory(demos)
endif()

if(AABBCC_GENERATE_HEADER_ONLY)
  set(header_only_configure_file_input_ ${CMAKE_CURRENT_SOURCE_DIR}/cmake/header-only.h.in)
  set(header_only_configure_file_output_ AABB.h)
  add_custom_target(header-only
    COMMAND ${CMAKE_COMMAND}
    -Dheader_file_=${header_file_}
    -Dsource_file_=${source_file_}
    -Dconfigure_file_input_=${header-only_configure_file_input}
    -Dheader_only_configure_file_input_=${header_only_configure_file_input_}
    -Dheader_only_configure_file_output_=${header_only_configure_file_output_}
    -P ${CMAKE_CURRENT_LIST_DIR}/cmake/generate_header_only.cmake)
endif()

# Install targets and config files
set(install_cmake_dir "${CMAKE_INSTALL_LIBDIR}/cmake/aabbcc")
install (EXPORT aabbccTargets
  NAMESPACE aabbcc::
  DESTINATION ${install_cmake_dir} )

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/cmake/aabbccConfig.cmake
              ${CMAKE_CURRENT_BINARY_DIR}/aabbccConfigVersion.cmake
              DESTINATION ${install_cmake_dir} )

include(CMakePackageConfigHelpers)
write_basic_package_version_file(aabbccConfigVersion.cmake
  VERSION ${aabbcc_VERSION}
  COMPATIBILITY SameMajorVersion)

# Build tree
set(aabbcc_TARGETS_FILE ${aabbcc_export_file})
configure_package_config_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/cmake/aabbccConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/aabbccConfig.cmake
  INSTALL_DESTINATION ${install_cmake_dir}
  PATH_VARS aabbcc_TARGETS_FILE
  NO_CHECK_REQUIRED_COMPONENTS_MACRO # aabbcc does not provide components
  INSTALL_PREFIX ${CMAKE_CURRENT_BINARY_DIR}
  )

# Install tree
set(aabbcc_TARGETS_FILE ${CMAKE_INSTALL_PREFIX}/${install_cmake_dir}/aabbccTargets.cmake)
configure_package_config_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/cmake/aabbccConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/cmake/aabbccConfig.cmake
  INSTALL_DESTINATION ${install_cmake_dir}
  PATH_VARS aabbcc_TARGETS_FILE
  NO_CHECK_REQUIRED_COMPONENTS_MACRO # aabbcc does not provide components
  )

