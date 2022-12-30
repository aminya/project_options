include_guard()

# Enable doxygen doc builds of source
function(enable_doxygen DOXYGEN_THEME)
  # If not specified, use the top readme file as the first page
  if((NOT DOXYGEN_USE_MDFILE_AS_MAINPAGE) AND EXISTS "${PROJECT_SOURCE_DIR}/README.md")
    set(DOXYGEN_USE_MDFILE_AS_MAINPAGE "${PROJECT_SOURCE_DIR}/README.md")
  endif()

  # set better defaults for doxygen
  is_verbose(_is_verbose)
  if(NOT ${_is_verbose})
    set(DOXYGEN_QUIET YES)
  endif()
  if(NOT DEFINED DOXYGEN_CALLER_GRAPH)
    set(DOXYGEN_CALLER_GRAPH YES)
  endif()
  if(NOT DEFINED DOXYGEN_CALL_GRAPH)
    set(DOXYGEN_CALL_GRAPH YES)
  endif()
  if(NOT DEFINED DOXYGEN_EXTRACT_ALL)
    set(DOXYGEN_EXTRACT_ALL YES)
  endif()
  if(NOT DEFINED DOXYGEN_GENERATE_TREEVIEW)
    set(DOXYGEN_GENERATE_TREEVIEW YES)
  endif()
  # svg files are much smaller than jpeg and png, and yet they have higher quality
  if(NOT DEFINED DOXYGEN_DOT_IMAGE_FORMAT)
    set(DOXYGEN_DOT_IMAGE_FORMAT svg)
  endif()
  if(NOT DEFINED DOXYGEN_DOT_TRANSPARENT)
    set(DOXYGEN_DOT_TRANSPARENT YES)
  endif()

  # If not specified, exclude the vcpkg files and the files CMake downloads under _deps (like project_options)
  if(NOT DOXYGEN_EXCLUDE_PATTERNS)
    set(DOXYGEN_EXCLUDE_PATTERNS "${CMAKE_CURRENT_BINARY_DIR}/vcpkg_installed/*" "${CMAKE_CURRENT_BINARY_DIR}/_deps/*")
  endif()

  if("${DOXYGEN_THEME}" STREQUAL "")
    set(DOXYGEN_THEME "awesome-sidebar")
  endif()

  if("${DOXYGEN_THEME}" STREQUAL "awesome" OR "${DOXYGEN_THEME}" STREQUAL "awesome-sidebar")
    # use a modern doxygen theme
    # https://github.com/jothepro/doxygen-awesome-css v2.0.2
    FetchContent_Declare(_doxygen_theme
                         URL https://github.com/jothepro/doxygen-awesome-css/archive/refs/tags/v2.0.2.zip)
    FetchContent_MakeAvailable(_doxygen_theme)
    if("${DOXYGEN_THEME}" STREQUAL "awesome" OR "${DOXYGEN_THEME}" STREQUAL "awesome-sidebar")
      set(DOXYGEN_HTML_EXTRA_STYLESHEET "${_doxygen_theme_SOURCE_DIR}/doxygen-awesome.css")
    endif()
    if("${DOXYGEN_THEME}" STREQUAL "awesome-sidebar")
      set(DOXYGEN_HTML_EXTRA_STYLESHEET ${DOXYGEN_HTML_EXTRA_STYLESHEET}
                                        "${_doxygen_theme_SOURCE_DIR}/doxygen-awesome-sidebar-only.css")
    endif()
  elseif("${DOXYGEN_THEME}" STREQUAL "original")
    # use the original doxygen theme
  else()
    # use custom doxygen theme

    # if any of the custom theme files are not found, the theme is reverted to original
    set(OLD_DOXYGEN_HTML_EXTRA_STYLESHEET ${DOXYGEN_HTML_EXTRA_STYLESHEET})
    foreach(file ${DOXYGEN_THEME})
      if(NOT EXISTS ${file})
        message(WARNING "Could not find doxygen theme file '${file}'. Using original theme.")
        set(DOXYGEN_HTML_EXTRA_STYLESHEET ${OLD_DOXYGEN_HTML_EXTRA_STYLESHEET})
        break()
      else()
        set(DOXYGEN_HTML_EXTRA_STYLESHEET ${DOXYGEN_HTML_EXTRA_STYLESHEET} "${file}")
      endif()
    endforeach()
  endif()

  # find doxygen and dot if available
  find_package(Doxygen REQUIRED OPTIONAL_COMPONENTS dot)

  # add doxygen-docs target
  message(STATUS "Adding `doxygen-docs` target that builds the documentation.")
  doxygen_add_docs(doxygen-docs ALL ${PROJECT_SOURCE_DIR}
                   COMMENT "Generating documentation - entry file: ${CMAKE_CURRENT_BINARY_DIR}/html/index.html")
endfunction()
