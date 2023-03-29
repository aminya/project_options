include_guard()

# Uses ycm (permissive BSD-3-Clause license) and ForwardArguments (permissive MIT license)

function(get_property_of_targets)
  set(options)
  set(one_value_args OUTPUT PROPERTY)
  set(multi_value_args TARGETS)
  cmake_parse_arguments(args "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})

  set(value)
  foreach(target IN LISTS args_TARGETS)
    get_target_property(current_property ${target} ${args_PROPERTY})
    if (current_property)
      list(APPEND value ${current_property})
    endif()
  endforeach()
  set(${args_OUTPUT} ${value})
endfunction()

#[[.rst:

.. include:: ../../docs/src/package_project.md
   :parser: myst_parser.sphinx_

#]]
function(package_project)
  # default to false
  set(_options ARCH_INDEPENDENT)
  set(_oneValueArgs
      # default to the project_name:
      NAME
      COMPONENT
      # default to project version:
      VERSION
      # default to semver
      COMPATIBILITY
      # default to ${CMAKE_BINARY_DIR}/${NAME}
      CONFIG_EXPORT_DESTINATION
      # default to ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_DATADIR}/${NAME} suitable for vcpkg, etc.
      CONFIG_INSTALL_DESTINATION)
  set(_multiValueArgs
      # recursively found for the current folder if not specified
      TARGETS
      # a list of public/interface include directories or files
      INTERFACE_INCLUDES
      PUBLIC_INCLUDES
      # the names of the INTERFACE/PUBLIC dependencies that are found using `CONFIG`
      INTERFACE_DEPENDENCIES_CONFIGURED
      PUBLIC_DEPENDENCIES_CONFIGURED
      # the INTERFACE/PUBLIC dependencies that are found by any means using `find_dependency`.
      # the arguments must be specified within double quotes (e.g. "<dependency> 1.0.0 EXACT" or "<dependency> CONFIG").
      INTERFACE_DEPENDENCIES
      PUBLIC_DEPENDENCIES
      # the names of the PRIVATE dependencies that are found using `CONFIG`. Only included when BUILD_SHARED_LIBS is OFF.
      PRIVATE_DEPENDENCIES_CONFIGURED
      # PRIVATE dependencies that are only included when BUILD_SHARED_LIBS is OFF
      PRIVATE_DEPENDENCIES)

  cmake_parse_arguments(
    _PackageProject
    "${_options}"
    "${_oneValueArgs}"
    "${_multiValueArgs}"
    "${ARGN}")

  # Set default options
  include(GNUInstallDirs) # Define GNU standard installation directories such as CMAKE_INSTALL_DATADIR

  # set default packaged targets
  if(NOT _PackageProject_TARGETS)
    get_all_installable_targets(_PackageProject_TARGETS)
    message(STATUS "package_project: considering ${_PackageProject_TARGETS} as the exported targets")
  endif()

  # default to the name of the project or the given name
  if("${_PackageProject_NAME}" STREQUAL "")
    set(_PackageProject_NAME ${PROJECT_NAME})
  endif()
  # ycm args
  set(_PackageProject_NAMESPACE "${_PackageProject_NAME}::")
  set(_PackageProject_VARS_PREFIX ${_PackageProject_NAME})
  set(_PackageProject_EXPORT ${_PackageProject_NAME})

  # default version to the project version
  if("${_PackageProject_VERSION}" STREQUAL "")
    set(_PackageProject_VERSION ${PROJECT_VERSION})
  endif()

  # default compatibility to SameMajorVersion
  if("${_PackageProject_COMPATIBILITY}" STREQUAL "")
    set(_PackageProject_COMPATIBILITY "SameMajorVersion")
  endif()

  # default to the build_directory/project_name
  if("${_PackageProject_CONFIG_EXPORT_DESTINATION}" STREQUAL "")
    set(_PackageProject_CONFIG_EXPORT_DESTINATION "${CMAKE_BINARY_DIR}/${_PackageProject_NAME}")
  endif()
  set(_PackageProject_EXPORT_DESTINATION "${_PackageProject_CONFIG_EXPORT_DESTINATION}")

  # use datadir (works better with vcpkg, etc)
  if("${_PackageProject_CONFIG_INSTALL_DESTINATION}" STREQUAL "")
    set(_PackageProject_CONFIG_INSTALL_DESTINATION "${CMAKE_INSTALL_DATADIR}/${_PackageProject_NAME}")
  endif()
  # ycm args
  set(_PackageProject_INSTALL_DESTINATION "${_PackageProject_CONFIG_INSTALL_DESTINATION}")

  # includes in target properties
  get_property_of_targets(TARGETS ${_PackageProject_TARGETS}
    PROPERTY PROJECT_OPTIONS_INTERFACE_DIRECTORY
    OUTPUT _PackageProject_PROPERTY_INTERFACE_DIRECTORY
  )

  # Installation of the public/interface includes
  set(_PackageProject_PUBLIC_INCLUDES "${_PackageProject_PUBLIC_INCLUDES}"
                                      "${_PackageProject_INTERFACE_INCLUDES}"
                                      "${_PackageProject_PROPERTY_INTERFACE_DIRECTORY}")
  if(NOT
     "${_PackageProject_PUBLIC_INCLUDES}"
     STREQUAL
     "")
    foreach(_INC ${_PackageProject_PUBLIC_INCLUDES})
      # make include absolute
      if(NOT IS_ABSOLUTE ${_INC})
        set(_INC "${CMAKE_CURRENT_SOURCE_DIR}/${_INC}")
      endif()
      # install include
      if(IS_DIRECTORY ${_INC})
        # the include directories are directly installed to the install destination. If you want an `include` folder in the install destination, name your include directory as `include` (or install it manually using `install()` command).
        install(DIRECTORY ${_INC} DESTINATION "./")
      else()
        install(FILES ${_INC} DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")
      endif()
    endforeach()
  endif()

  # public dependencies in target properties
  get_property_of_targets(TARGETS ${_PackageProject_TARGETS}
    PROPERTY PROJECT_OPTIONS_PUBLIC_DEPENDENCIES
    OUTPUT _PackageProject_PROPERTY_PUBLIC_DEPENDENCIES
  )
  # interface dependencies in target properties
  get_property_of_targets(TARGETS ${_PackageProject_TARGETS}
    PROPERTY PROJECT_OPTIONS_INTERFACE_DEPENDENCIES
    OUTPUT _PackageProject_PROPERTY_INTERFACE_DEPENDENCIES
  )

  # Append the configured public dependencies
  set(_PackageProject_PUBLIC_DEPENDENCIES_CONFIGURED "${_PackageProject_PUBLIC_DEPENDENCIES_CONFIGURED}"
                                                     "${_PackageProject_PROPERTY_PUBLIC_DEPENDENCIES}"
                                                     "${_PackageProject_INTERFACE_DEPENDENCIES_CONFIGURED}"
                                                     "${_PackageProject_PROPERTY_INTERFACE_DEPENDENCIES}")
  if(NOT
     "${_PackageProject_PUBLIC_DEPENDENCIES_CONFIGURED}"
     STREQUAL
     "")
    set(_PUBLIC_DEPENDENCIES_CONFIG)
    foreach(DEP ${_PackageProject_PUBLIC_DEPENDENCIES_CONFIGURED})
      list(APPEND _PUBLIC_DEPENDENCIES_CONFIG "${DEP} CONFIG")
    endforeach()
  endif()
  list(APPEND _PackageProject_PUBLIC_DEPENDENCIES ${_PUBLIC_DEPENDENCIES_CONFIG})
  # ycm arg
  set(_PackageProject_DEPENDENCIES ${_PackageProject_PUBLIC_DEPENDENCIES} ${_PackageProject_INTERFACE_DEPENDENCIES})

  # private dependencies in target properties
  get_property_of_targets(TARGETS ${_PackageProject_TARGETS}
    PROPERTY PROJECT_OPTIONS_PRIVATE_DEPENDENCIES
    OUTPUT _PackageProject_PROPERTY_PRIVATE_DEPENDENCIES
  )
  
  # Append the configured private dependencies
    set(_PackageProject_PRIVATE_DEPENDENCIES_CONFIGURED "${_PackageProject_PRIVATE_DEPENDENCIES_CONFIGURED}"
                                                        "${_PackageProject_PROPERTY_PRIVATE_DEPENDENCIES}")
  if(NOT
     "${_PackageProject_PRIVATE_DEPENDENCIES_CONFIGURED}"
     STREQUAL
     "")
    set(_PRIVATE_DEPENDENCIES_CONFIG)
    foreach(DEP ${_PackageProject_PRIVATE_DEPENDENCIES_CONFIGURED})
      list(APPEND _PRIVATE_DEPENDENCIES_CONFIG "${DEP} CONFIG")
    endforeach()
  endif()
  # ycm arg
  list(APPEND _PackageProject_PRIVATE_DEPENDENCIES ${_PRIVATE_DEPENDENCIES_CONFIG})

  # Installation of package (compatible with vcpkg, etc)
  set(_targets_list ${_PackageProject_TARGETS})
  unset(_PackageProject_TARGETS) # to avoid ycm conflict

  if(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.23.0")
    # required in CMake 3.23 and more
    set(FILE_SET_ARGS "FILE_SET" "HEADERS")
  endif()

  install(
    TARGETS ${_targets_list}
    EXPORT ${_PackageProject_EXPORT}
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}" COMPONENT shlib
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}" COMPONENT lib
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}" COMPONENT bin
    PUBLIC_HEADER
      DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${_PackageProject_NAME}"
      COMPONENT dev
      ${FILE_SET_ARGS})

  # download ForwardArguments
  FetchContent_Declare(_fargs URL https://github.com/polysquare/cmake-forward-arguments/archive/refs/tags/v1.0.0.zip)
  FetchContent_GetProperties(_fargs)
  if(NOT _fargs_POPULATED)
    FetchContent_Populate(_fargs)
  endif()
  include("${_fargs_SOURCE_DIR}/ForwardArguments.cmake")

  # prepare the forward arguments for ycm
  set(_FARGS_LIST)
  cmake_forward_arguments(
    _PackageProject
    _FARGS_LIST
    OPTION_ARGS
    "${_options};"
    SINGLEVAR_ARGS
    "${_oneValueArgs};EXPORT_DESTINATION;INSTALL_DESTINATION;NAMESPACE;VARS_PREFIX;EXPORT"
    MULTIVAR_ARGS
    "${_multiValueArgs};DEPENDENCIES;PRIVATE_DEPENDENCIES")

  # download ycm
  FetchContent_Declare(_ycm URL https://github.com/robotology/ycm/archive/refs/tags/v0.13.0.zip)
  FetchContent_GetProperties(_ycm)
  if(NOT _ycm_POPULATED)
    FetchContent_Populate(_ycm)
  endif()
  include("${_ycm_SOURCE_DIR}/modules/InstallBasicPackageFiles.cmake")

  install_basic_package_files(${_PackageProject_NAME} "${_FARGS_LIST}")

  # install the usage file
  set(_targets_str "")
  foreach(_target ${_targets_list})
    set(_targets_str "${_targets_str} ${_PackageProject_NAMESPACE}${_target}")
  endforeach()
  set(USAGE_FILE_CONTENT
      "# The package ${_PackageProject_NAME} provides the following CMake targets:

    find_package(${_PackageProject_NAME} CONFIG REQUIRED)
    target_link_libraries(main PRIVATE ${_targets_str})
  ")
  file(WRITE "${_PackageProject_EXPORT_DESTINATION}/usage" "${USAGE_FILE_CONTENT}")
  install(FILES "${_PackageProject_EXPORT_DESTINATION}/usage"
          DESTINATION "${_PackageProject_CONFIG_INSTALL_DESTINATION}")
  install(CODE "MESSAGE(STATUS \"${USAGE_FILE_CONTENT}\")")

  include("${_ycm_SOURCE_DIR}/modules/AddUninstallTarget.cmake")
endfunction()

function(set_or_append_target_property target property new_values)
  get_target_property(all_values ${target} ${property})

  if(NOT all_values) # If the property hasn't set
    set(all_values "${new_values}")
  else()
    list(APPEND all_values ${new_values})
  endif()

  set_target_properties(${target}
    PROPERTIES ${property} "${all_values}"
  )
endfunction()

#[[.rst:

.. include:: ../../docs/src/target_include_interface_directory.md
   :parser: myst_parser.sphinx_

#]]
function(target_include_interface_directory target include_dir)
  # Make include_dir absolute
  cmake_path(IS_RELATIVE include_dir is_relative)
  if(is_relative)
    set(include_dir "${CMAKE_CURRENT_SOURCE_DIR}/${include_dir}")
  endif()

  # Append include_dir to target property PROJECT_OPTIONS_INTERFACE_DIRECTORY
  set_or_append_target_property(${target}
    "PROJECT_OPTIONS_INTERFACE_DIRECTORY" ${include_dir}
  )

  # Include the interface directory
  get_target_property(has_source_files ${target} SOURCES)
  if(NOT has_source_files) # header-only library, aka `add_library(<name> INTERFACE)`
    target_include_directories(${target}
      INTERFACE
      $<BUILD_INTERFACE:${include_dir}>
      $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    )
  else()
    target_include_directories(${target}
      PUBLIC
      $<BUILD_INTERFACE:${include_dir}>
      $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    )
  endif()
endfunction()

#[[.rst:

.. include:: ../../docs/src/target_find_dependencies.md
   :parser: myst_parser.sphinx_

#]]
function(target_find_dependencies target)
  set(options)
  set(one_value_args)
  set(multi_value_args PRIVATE PUBLIC INTERFACE)
  cmake_parse_arguments(args "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})

  # Call find_package to all newly added dependencies
  foreach(dependency IN LISTS args_PRIVATE args_PUBLIC args_INTERFACE)
    find_package(${dependency} REQUIRED)
  endforeach()

  set_or_append_target_property(${target}
    "PROJECT_OPTIONS_PRIVATE_DEPENDENCIES" "${args_PRIVATE}"
  )
  set_or_append_target_property(${target}
    "PROJECT_OPTIONS_PUBLIC_DEPENDENCIES" "${args_PUBLIC}"
  )
  set_or_append_target_property(${target}
    "PROJECT_OPTIONS_INTERFACE_DEPENDENCIES" "${args_INTERFACE}"
  )
endfunction()
