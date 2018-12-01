cmake_minimum_required(VERSION 3.9)

project(proto_test)

find_package(Protobuf REQUIRED)

# Represents a proto file and associated include directory needed for
# generation of source files from the corresponding proto files. Also
# can be used to install proto files and exported.
#
# Example:
#
# ```
# add_proto(messages_proto messages.proto)
# add_library(example_project::messages_proto ALIAS messages_proto)
#
# target_include_directories(
#    messages_proto
#    INTERFACE
#        # This is for builds within the same package.
#        $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}>)
#
# target_link_libraries(
#    messages_proto
#    INTERFACE
#        # The required directories will be added for proto include.
#        example_dependency::bits_proto)
#
# install(TARGETS
#     messages_proto
#     EXPORT exports
#     # Augments INTERFACE_INCLUDE_DIRECTORIES on the exported target, so it
#     # can be used by consuming libraries.
#     INCLUDES DESTINATION proto
#
# install(FILES
#     $<TARGET_PROPERTY:messages_proto,INTERFACE_SOURCES>
#     DESTINATION proto)
# ```
function(add_proto library_name)
    add_library(${library_name} INTERFACE)

    # Ideally we could use this and do the install, export, and setting
    # of install include path in one `install` directive, but PUBLIC_HEADER
    # is not allowed on interface libraries.
    #set_target_properties(
    #    ${library_name}
    #    PROPERTIES
    #        PUBLIC_HEADER "${ARGV}")
    # Same result as above.
    #set_property(TARGET
    #    ${library_name}
    #    PROPERTY PUBLIC_HEADER "${ARGV}")

    # Convert sources to absolute path otherwise install(FILES ...) considers
    # them relative to CMAKE_CURRENT_BINARY_DIR.
    foreach(fil ${ARGN})
        get_filename_component(abs_fil ${fil} ABSOLUTE)
        list(APPEND _add_proto_sources ${abs_fil})
    endforeach()

    # These cannot be installed with install(TARGETS ...), so we suggest in the
    # example to use install(FILES ...) with a generator expression.
    target_sources(
        ${library_name}
        INTERFACE
            ${_add_proto_sources})
endfunction()

# Represents a compiled static library suitable for consumption in the
# application. The target can also be installed and exported.
#
# Example:
#
# ```
# add_proto_cpp_library(messages messages.proto)
#
# target_link_libraries(
#     messages
#     # Associated include directories are used in the cpp file generation
#     # step.
#     PRIVATE
#         # From example above.
#         example_project::messages_proto)
# ```
function(add_proto_cpp_library library_name)
    # XXX: In order to get this to work with a library added via `add_proto`
    #  above it would be necessary to extract the source proto files from it,
    #  however then we'd need to somehow extract the property and format the
    #  output filenames for `add_custom_command`. Since OUTPUT doesn't support
    #  generator expressions we can just leave this as-is for now...
    add_library(${library_name} STATIC)

    # Helper variable.
    set(include_dirs "$<TARGET_PROPERTY:${library_name},INCLUDE_DIRECTORIES>")
    # Create -I<path> for each path in include_dirs. Paths must not have
    # spaces.
    #
    # XXX: To support paths with spaces we would need to re-implement
    #  protobuf_generate_cpp except pass COMMAND_EXPAND_LISTS to
    #  add_custom_command, then use ,;-I below, per the example in the CMake
    #  docs.
    set(_protobuf_include_path
        "$<$<BOOL:${include_dirs}>:-I$<JOIN:${include_dirs}, -I>>")

    # Pass-thru any files.
    protobuf_generate_cpp(
        ${library_name}_SOURCES ${library_name}_HEADERS ${ARGN})

    target_sources(
        ${library_name}
        PRIVATE
            ${${library_name}_SOURCES}
            ${${library_name}_HEADERS})

    set_target_properties(
        ${library_name}
        PROPERTIES
            # To allow installation with PUBLIC_HEADER DESTINATION ... in
            # `install` directive.
            PUBLIC_HEADER "${${library_name}_HEADERS}")

    # For targets that are part of the build.
    target_include_directories(
        ${library_name}
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>)
endfunction()

set(CMAKE_CXX_STANDARD 11)

add_proto(address_proto AddressBook.proto)
add_library(proto_test::address_proto ALIAS address_proto)

add_proto_cpp_library(addresses AddressBook.proto)
target_include_directories(
    addresses
    PUBLIC
    ${PROTOBUF_INCLUDE_DIR})

install(TARGETS
    address_proto
    EXPORT exports
    INCLUDES DESTINATION proto)

install(FILES
    $<TARGET_PROPERTY:proto_test::address_proto,INTERFACE_SOURCES>
    DESTINATION proto)
