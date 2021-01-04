# Example of usage from any other CMakeLists.
# Use absolute paths for variables refering to files.
#  add_custom_target(header-only
#    COMMAND ${CMAKE_COMMAND}
#    -Dheader_file_=${header_file_}
#    -Dsource_file_=${source_file_}
#    -Dconfigure_file_input_=${header-only_configure_file_input}
#    -Dheader_only_configure_file_input_=${header_only_configure_file_input_}
#    -Dheader_only_configure_file_output_=${header_only_configure_file_output_}
#    -P ${CMAKE_CURRENT_LIST_DIR}/cmake/generate_header_only.cmake)
#
file(READ "${header_file_}" HEADER_FILE)
STRING(REPLACE "#endif /* _AABB_H */" " " HEADER_FILE_HEAD ${HEADER_FILE})
file(READ "${source_file_}" SOURCE_FILE)
STRING(REPLACE "#include \"AABB.h\"" " " SOURCE_FILE_TAIL ${SOURCE_FILE})
configure_file(${header_only_configure_file_input_} ${header_only_configure_file_output_})
