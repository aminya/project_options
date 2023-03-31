# This module builds the documentation for the project.
# Based on https://gitlab.com/Pro1/doxygen-cmake-sphinx/-/blob/master/doc/CMakeLists.txt

cmake_minimum_required(VERSION 3.25)

project(
  project_options_docs
  VERSION 0.27.0
  DESCRIPTION "Documentation"
  LANGUAGES NONE)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include("../src/Index.cmake")
project_options(ENABLE_DOXYGEN)

find_package(Sphinx REQUIRED)
find_package(Python)

option(SPHINX_INFO "Build Info manual with Sphinx" OFF)
option(SPHINX_MAN "Build man pages with Sphinx" OFF)
option(SPHINX_HTML "Build html help with Sphinx" ON)
option(SPHINX_SINGLEHTML "Build html single page help with Sphinx" OFF)
set(COMPONENT "documentation")

set(SPHINX_FLAGS
    ""
    CACHE STRING "Flags to pass to sphinx-build")
separate_arguments(sphinx_flags UNIX_COMMAND "${SPHINX_FLAGS}")

mark_as_advanced(SPHINX_TEXT)
mark_as_advanced(SPHINX_FLAGS)

if(NOT SPHINX_INFO
   AND NOT SPHINX_MAN
   AND NOT SPHINX_HTML
   AND NOT SPHINX_SINGLEHTML
   AND NOT SPHINX_QTHELP
   AND NOT SPHINX_TEXT)
  return()
elseif(NOT SPHINX_EXECUTABLE)
  message(FATAL_ERROR "SPHINX_EXECUTABLE (sphinx-build) is not found!")
endif()

set(conf_copyright "MIT - Copyright (c) 2022-2100 Amin Yahyaabadi")
set(conf_docs "${CMAKE_CURRENT_SOURCE_DIR}") # Location of your index.rst
set(conf_path "${CMAKE_CURRENT_SOURCE_DIR}") # Location of your conf.py
set(conf_out_path "${CMAKE_CURRENT_BINARY_DIR}") # Location of the output directory
set(conf_version "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}")
set(conf_release "${PROJECT_VERSION}")
set(conf_name "project_options")
set(conf_author "Amin Yahyaabadi")
set(conf_brief
    "A general-purpose CMake library that provides functions that improve the CMake experience following the best practices."
)
set(conf_doxygen_input
    "\
  \"${CMAKE_SOURCE_DIR}/include\" \
  \"${CMAKE_SOURCE_DIR}/src\" \
  \"${CMAKE_SOURCE_DIR}/cmake\" \
")
configure_file(conf.py.in conf.py @ONLY)

set(doc_formats "")
if(SPHINX_HTML)
  list(APPEND doc_formats html)
  set(html_extra_commands COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_LIST_DIR}/root/
                          ${CMAKE_CURRENT_BINARY_DIR})
  file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/js/versions.js
       "var ar_versions = [{\"version\": \"build\", \"folder\": \"html\", \"has_pdf\": false}]")
endif()
if(SPHINX_MAN)
  list(APPEND doc_formats man)
endif()
if(SPHINX_SINGLEHTML)
  list(APPEND doc_formats singlehtml)
endif()
if(SPHINX_TEXT)
  list(APPEND doc_formats text)
endif()
if(SPHINX_INFO)
  find_program(
    MAKEINFO_EXECUTABLE
    NAMES makeinfo
    DOC "makeinfo tool")
  if(NOT MAKEINFO_EXECUTABLE)
    message(FATAL_ERROR "MAKEINFO_EXECUTABLE (makeinfo) not found!")
  endif()
  list(APPEND doc_formats texinfo)

  # Sphinx texinfo builder supports .info, .txt, .html and .pdf output.
  # SPHINX_INFO controls the .info output.
  set(texinfo_extra_commands
      COMMAND ${MAKEINFO_EXECUTABLE} --no-split -o ${CMAKE_CURRENT_BINARY_DIR}/texinfo/cmake.info
      ${CMAKE_CURRENT_BINARY_DIR}/texinfo/cmake.texi)
endif()

set(doc_format_outputs "")
set(doc_format_last "")
foreach(format ${doc_formats})
  set(doc_format_output "doc_format_${format}")
  set(doc_format_log "build-${format}.log")
  add_custom_command(
    OUTPUT ${doc_format_output}
    COMMAND
      ${SPHINX_EXECUTABLE} -c ${CMAKE_CURRENT_BINARY_DIR} -d ${CMAKE_CURRENT_BINARY_DIR}/doctrees -b ${format}
      ${sphinx_flags} ${CMAKE_CURRENT_LIST_DIR} ${CMAKE_CURRENT_BINARY_DIR}/${format} >
      ${CMAKE_CURRENT_BINARY_DIR}/${doc_format_log} # log stdout, pass stderr
      ${${format}_extra_commands}
    DEPENDS ${doc_format_last}
    COMMENT "sphinx-build ${format}: see ${CMAKE_CURRENT_BINARY_DIR}/${doc_format_log}"
    VERBATIM)
  set_property(SOURCE ${doc_format_output} PROPERTY SYMBOLIC 1)
  list(APPEND doc_format_outputs ${doc_format_output})
  set(doc_format_last ${doc_format_output})
endforeach()

add_custom_target(documentation ALL DEPENDS ${doc_format_outputs})

if(SPHINX_INFO)
  install(
    FILES ${CMAKE_CURRENT_BINARY_DIR}/texinfo/cmake.info
    DESTINATION ${CMAKE_INFO_DIR}
    ${COMPONENT})
endif()

if(SPHINX_MAN)
  file(
    GLOB man_rst
    RELATIVE ${CMAKE_SOURCE_DIR}/Help/manual
    ${CMAKE_SOURCE_DIR}/Help/manual/*.[1-9].rst)
  foreach(m ${man_rst})
    if("x${m}" MATCHES "^x(.+)\\.([1-9])\\.rst$")
      set(name "${CMAKE_MATCH_1}")
      set(sec "${CMAKE_MATCH_2}")
      set(skip FALSE)
      if(NOT CMakeHelp_STANDALONE)
        if(name STREQUAL "ccmake" AND NOT BUILD_CursesDialog)
          set(skip TRUE)
        elseif(name STREQUAL "cmake-gui" AND NOT BUILD_QtDialog)
          set(skip TRUE)
        endif()
      endif()
      if(NOT skip)
        install(
          FILES ${CMAKE_CURRENT_BINARY_DIR}/man/${name}.${sec}
          DESTINATION ${CMAKE_MAN_DIR}/man${sec}
          ${COMPONENT})
      endif()
      unset(skip)
    endif()
  endforeach()
endif()

if(SPHINX_HTML)
  install(
    DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/html
    DESTINATION ${CMAKE_DOC_DIR}
    ${COMPONENT}
    PATTERN .buildinfo EXCLUDE)
endif()

if(SPHINX_SINGLEHTML)
  install(
    DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/singlehtml
    DESTINATION ${CMAKE_DOC_DIR}
    ${COMPONENT}
    PATTERN .buildinfo EXCLUDE)
endif()
