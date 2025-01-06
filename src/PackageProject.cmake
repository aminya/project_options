include_guard()

include("${CMAKE_CURRENT_LIST_DIR}/Utilities.cmake")

# Uses ycm (permissive BSD-3-Clause license) and ForwardArguments (permissive MIT license)

function(get_property_of_targets)
  set(_options)
  set(_oneValueArgs OUTPUT PROPERTY)
  set(_multiValueArgs TARGETS)
  cmake_parse_arguments(args "${_options}" "${_oneValueArgs}" "${_multiValueArgs}" ${ARGN})

  set(_Value)
  foreach(_Target IN LISTS args_TARGETS)
    get_target_property(_Current_property ${_Target} ${args_PROPERTY})
    if(_Current_property)
      list(APPEND _Value ${_Current_property})
    endif()
  endforeach()
  convert_genex_semicolons("${_Value}" _Value)
  list(REMOVE_DUPLICATES _Value)
  set(${args_OUTPUT} ${_Value} PARENT_SCOPE)
endfunction()

#[[.rst:

``package_project``
===================

A function that packages the project for external usage (e.g. from
vcpkg, Conan, etc).

The following arguments specify the package:

-  ``TARGETS``: the targets you want to package. It is recursively found
   for the current folder if not specified

-  ``INTERFACE_INCLUDES`` or ``PUBLIC_INCLUDES``: a list of
   interface/public include directories or files.

   NOTE: The given include directories are directly installed to the
   install destination. To have an ``include`` folder in the install
   destination with the content of your include directory, name your
   directory ``include``.

-  ``INTERFACE_DEPENDENCIES_CONFIGURED`` or
   ``PUBLIC_DEPENDENCIES_CONFIGURED``: the names of the interface/public
   dependencies that are found using ``CONFIG``.

-  ``INTERFACE_DEPENDENCIES`` or ``PUBLIC_DEPENDENCIES``: the
   interface/public dependencies that will be found by any means using
   ``find_dependency``. The arguments must be specified within quotes
   (e.g.\ ``"<dependency> 1.0.0 EXACT"`` or ``"<dependency> CONFIG"``).

-  ``PRIVATE_DEPENDENCIES_CONFIGURED``: the names of the PRIVATE
   dependencies found using ``CONFIG``. Only included when
   ``BUILD_SHARED_LIBS`` is ``OFF``.

-  ``PRIVATE_DEPENDENCIES``: the PRIVATE dependencies found by any means
   using ``find_dependency``. Only included when ``BUILD_SHARED_LIBS``
   is ``OFF``

Other arguments that are automatically found and manually specifying
them is not recommended:

-  ``NAME``: the name of the package. Defaults to ``${PROJECT_NAME}``.

-  ``VERSION``: the version of the package. Defaults to
   ``${PROJECT_VERSION}``.

-  ``COMPATIBILITY``: the compatibility version of the package. Defaults
   to ``SameMajorVersion``.

-  ``CONFIG_EXPORT_DESTINATION``: the destination for exporting the
   configuration files. Defaults to ``${CMAKE_BINARY_DIR}/${NAME}``

-  ``CONFIG_INSTALL_DESTINATION``: the destination for installation of
   the configuration files. Defaults to
   ``${CMAKE_INSTALL_DATADIR}/${NAME}``


]]
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
      CONFIG_INSTALL_DESTINATION
  )
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
      PRIVATE_DEPENDENCIES
  )

  cmake_parse_arguments(_PackageProject "${_options}" "${_oneValueArgs}" "${_multiValueArgs}" "${ARGN}")

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
  set(_PackageProject_SET "${_PackageProject}_deps_set")

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

  # target properties
  macro(_Get_property property)
    get_property_of_targets(
      TARGETS
      ${_PackageProject_TARGETS}
      PROPERTY
      "PROJECT_OPTIONS_${property}"
      OUTPUT
      "PROPERTY_${property}"
    )
  endmacro()
  _get_property(INTERFACE_DIRECTORIES)
  _get_property(INTERFACE_DEPENDENCIES)
  _get_property(PUBLIC_DEPENDENCIES)
  _get_property(PRIVATE_DEPENDENCIES)
  _get_property(INTERFACE_CONFIG_DEPENDENCIES)
  _get_property(PUBLIC_CONFIG_DEPENDENCIES)
  _get_property(PRIVATE_CONFIG_DEPENDENCIES)

  # Installation of the public/interface includes
  set(_PackageProject_PUBLIC_INCLUDES
      "${_PackageProject_PUBLIC_INCLUDES}" "${_PackageProject_INTERFACE_INCLUDES}"
      "${PROPERTY_INTERFACE_DIRECTORIES}"
  )
  if(NOT "${_PackageProject_PUBLIC_INCLUDES}" STREQUAL "")
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

  # Append the configured public dependencies
  set(_PackageProject_PUBLIC_DEPENDENCIES_CONFIGURED
      "${_PackageProject_PUBLIC_DEPENDENCIES_CONFIGURED}" "${PROPERTY_PUBLIC_CONFIG_DEPENDENCIES}"
      "${_PackageProject_INTERFACE_DEPENDENCIES_CONFIGURED}" "${PROPERTY_INTERFACE_CONFIG_DEPENDENCIES}"
  )
  list(REMOVE_DUPLICATES _PackageProject_PUBLIC_DEPENDENCIES_CONFIGURED)
  if(NOT "${_PackageProject_PUBLIC_DEPENDENCIES_CONFIGURED}" STREQUAL "")
    set(_PUBLIC_DEPENDENCIES_CONFIG)
    foreach(DEP ${_PackageProject_PUBLIC_DEPENDENCIES_CONFIGURED})
      list(APPEND _PUBLIC_DEPENDENCIES_CONFIG "${DEP} CONFIG")
    endforeach()
  endif()

  list(APPEND _PackageProject_PUBLIC_DEPENDENCIES ${_PUBLIC_DEPENDENCIES_CONFIG}
       ${PROPERTY_PUBLIC_DEPENDENCIES}
  )

  # ycm arg
  set(_PackageProject_DEPENDENCIES
      ${_PackageProject_PUBLIC_DEPENDENCIES} ${_PackageProject_INTERFACE_DEPENDENCIES}
      ${PROPERTY_INTERFACE_DEPENDENCIES}
  )

  # Append the configured private dependencies
  set(_PackageProject_PRIVATE_DEPENDENCIES_CONFIGURED "${_PackageProject_PRIVATE_DEPENDENCIES_CONFIGURED}"
                                                      "${PROPERTY_PRIVATE_CONFIG_DEPENDENCIES}"
  )
  list(REMOVE_DUPLICATES _PackageProject_PRIVATE_DEPENDENCIES_CONFIGURED)
  if(NOT "${_PackageProject_PRIVATE_DEPENDENCIES_CONFIGURED}" STREQUAL "")
    set(_PRIVATE_DEPENDENCIES_CONFIG)
    foreach(DEP ${_PackageProject_PRIVATE_DEPENDENCIES_CONFIGURED})
      list(APPEND _PRIVATE_DEPENDENCIES_CONFIG "${DEP} CONFIG")
    endforeach()
  endif()
  # ycm arg
  list(APPEND _PackageProject_PRIVATE_DEPENDENCIES ${_PRIVATE_DEPENDENCIES_CONFIG}
       ${PROPERTY_PRIVATE_DEPENDENCIES}
  )

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
    RUNTIME_DEPENDENCY_SET ${_PackageProject_SET}
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}" COMPONENT shlib
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}" COMPONENT lib
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}" COMPONENT bin
    PUBLIC_HEADER DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${_PackageProject_NAME}" COMPONENT dev
                  ${FILE_SET_ARGS}
  )
  set(runtime_dirs)
  if(CONAN_RUNTIME_LIB_DIRS)
    list(APPEND runtime_dirs ${CONAN_RUNTIME_LIB_DIRS})
  endif()
  if(runtime_dirs)
    install(RUNTIME_DEPENDENCY_SET ${_PackageProject_SET}
      PRE_EXCLUDE_REGEXES
        [[api-ms-win-.*]]
        [[ext-ms-.*]]
        [[kernel32\.dll]]
        [[(libc|libgcc_s|libgcc_s_seh|libm|libstdc\+\+|libc\+\+|libunwind)(-[0-9.]+)?\..*]]
      POST_EXCLUDE_REGEXES
        [[.*(\\|/)system32(\\|/).*\.dll]] # according to https://discourse.cmake.org/t/migration-experiences-comparison-runtime-dependency-set-vs-fixup-bundle-bundleutilities/11323/6
        [[^/lib.*]]
        [[^/usr/lib.*]]
      DIRECTORIES
        ${runtime_dirs}
    )
  endif()

  # download ForwardArguments
  FetchContent_Declare(
    _fargs URL https://github.com/polysquare/cmake-forward-arguments/archive/refs/tags/v1.0.0.zip
               SOURCE_SUBDIR this-directory-does-not-exist
  )
  FetchContent_GetProperties(_fargs)
  if(NOT _fargs_POPULATED)
    FetchContent_MakeAvailable(_fargs)
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
    "${_multiValueArgs};DEPENDENCIES;PRIVATE_DEPENDENCIES"
  )

  # download ycm
  FetchContent_Declare(
    _ycm URL https://github.com/robotology/ycm/archive/refs/tags/v0.13.0.zip SOURCE_SUBDIR
             this-directory-does-not-exist
  )
  FetchContent_GetProperties(_ycm)
  if(NOT _ycm_POPULATED)
    FetchContent_MakeAvailable(_ycm)
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
  "
  )
  file(WRITE "${_PackageProject_EXPORT_DESTINATION}/usage" "${USAGE_FILE_CONTENT}")
  install(FILES "${_PackageProject_EXPORT_DESTINATION}/usage"
          DESTINATION "${_PackageProject_CONFIG_INSTALL_DESTINATION}"
  )
  install(CODE "MESSAGE(STATUS \"${USAGE_FILE_CONTENT}\")")

  include("${_ycm_SOURCE_DIR}/modules/AddUninstallTarget.cmake")
endfunction()

#[[.rst:

``target_include_interface_directories``
=================================================

.. code:: cmake

   target_include_interface_directories(<target_name> [<include_dir> ...])

This function includes ``include_dir`` as the header interface directory
of ``target_name``. If the given ``include_dir`` path is relative, the
function assumes the path is
``${CMAKE_CURRENT_SOURCE_DIR}/${include_dir}`` (i.e. the path is related
to the path of CMakeLists.txt which calls the function).

A property named ``PROJECT_OPTIONS_INTERFACE_DIRECTORIES`` will be
created in ``target_name`` to represent the header directory path. When
adding the target to ``package_project``, directories in this property
will be automatically added.

You can call this function with the same ``target_name`` multiple times
to add more header interface directories.

.. code:: cmake

   add_library(my_header_lib INTERFACE)
   target_include_interface_directories(my_header_lib "${CMAKE_CURRENT_SOURCE_DIR}/include")
   target_include_interface_directories(my_header_lib ../include)

   add_library(my_lib)
   target_sources(my_lib PRIVATE function.cpp)
   target_include_interface_directories(my_lib include ../include)

   package_project(TARGETS my_header_lib my_lib)


]]
function(target_include_interface_directories target)
  function(target_include_interface_directory target include_dir)
    # Make include_dir absolute
    cmake_path(IS_RELATIVE include_dir _IsRelative)
    if(_IsRelative)
      set(include_dir "${CMAKE_CURRENT_SOURCE_DIR}/${include_dir}")
    endif()

    # Append include_dir to target property PROJECT_OPTIONS_INTERFACE_DIRECTORIES
    set_property(TARGET ${target} APPEND PROPERTY "PROJECT_OPTIONS_INTERFACE_DIRECTORIES" ${include_dir})

    # Include the interface directory
    get_target_property(_HasSourceFiles ${target} SOURCES)
    if(NOT _HasSourceFiles) # header-only library, aka `add_library(<name> INTERFACE)`
      target_include_directories(
        ${target} INTERFACE $<BUILD_INTERFACE:${include_dir}>
                            $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
      )
    else()
      target_include_directories(
        ${target} PUBLIC $<BUILD_INTERFACE:${include_dir}> $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
      )
    endif()
  endfunction()

  foreach(_IncludeDir IN LISTS ARGN)
    target_include_interface_directory(${target} ${_IncludeDir})
  endforeach()
endfunction()

#[=[.rst:

``target_find_dependencies``
=====================================

.. code:: cmake

   target_find_dependencies(<target_name>
     [
      <INTERFACE|PUBLIC|PRIVATE|INTERFACE_CONFIG|PUBLIC_CONFIG|PRIVATE_CONFIG>
      [dependency1...]
     ]...
     [
      <INTERFACE|PUBLIC|PRIVATE|INTERFACE_CONFIG|PUBLIC_CONFIG|PRIVATE_CONFIG>
      [PACKAGE <dependency_name> [find_package() argument1...]]...
     ]...
   )

This macro calls ``find_package(${dependency} [CONFIG] REQUIRED [OTHER_ARGUMENTS])`` for
all dependencies required and binds them to the target.

Properties named
``PROJECT_OPTIONS_<PRIVATE|PUBLIC|INTERFACE>[_CONFIG]_DEPENDENCIES``
will be created in ``target_name`` to represent corresponding
dependencies. When adding the target to ``package_project``, directories
in this property will be automatically added.

You can call this function with the same ``target_name`` multiple times
to add more dependencies.

.. code:: cmake

   add_library(my_lib)
   target_sources(my_lib PRIVATE function.cpp)
   target_include_interface_directories(my_lib "${CMAKE_CURRENT_SOURCE_DIR}/include")

   target_find_dependencies(my_lib
     PUBLIC_CONFIG
       fmt

     PRIVATE_CONFIG
       PACKAGE Microsoft.GSL
       PACKAGE Qt6 COMPONENTS Widgets
   )
   target_find_dependencies(my_lib
     PRIVATE
       PACKAGE range-v3 CONFIG QUIET  # you can also set CONFIG here
   )

   target_link_system_libraries(my_lib
     PUBLIC
     fmt::fmt

     PRIVATE
     Microsoft.GSL::GSL
     Qt6::Widgets
     range-v3::range-v3
   )

   package_project(TARGETS my_lib)

]=]
function(target_find_dependencies target)
  set(unparsed_args ${ARGN})

  set(type "")
  set(package_name "")
  set(find_package_args "")
  set(simple_mode FALSE)

  macro(_parse_target_find_dependencies)
    set(package_name "")
    set(find_package_args "")

    while(unparsed_args)
      list(POP_FRONT unparsed_args _current)

      if(_current MATCHES "^(PRIVATE|PUBLIC|INTERFACE)(_CONFIG)?$") # Parse an option section
        # Set the option section type
        set(type "${_current}")

        # Check mode for this option section
        if(unparsed_args)
          list(GET unparsed_args 0 _next)

          if(_next STREQUAL "PACKAGE")
            set(simple_mode FALSE)
          else()
            set(simple_mode TRUE)
          endif()
        endif()
      elseif(simple_mode) # Parse a simple option item
        set(package_name "${_current}")
        break()
      else() # Parse a complex option item
        # _current == "PACKAGE", so the next is the package_name
        list(POP_FRONT unparsed_args package_name)

        while(unparsed_args)
          list(POP_FRONT unparsed_args _find_package_arg)

          # Done if _find_package_arg belongs to next option item
          if((_find_package_arg MATCHES "^(PRIVATE|PUBLIC|INTERFACE)(_CONFIG)?$") OR (_find_package_arg
                                                                                      STREQUAL "PACKAGE")
          )
            list(PREPEND unparsed_args "${_find_package_arg}")
            break()
          endif()

          list(APPEND find_package_args "${_find_package_arg}")
        endwhile()
        break()
      endif()
    endwhile()
  endmacro()

  macro(_add_dependency)
    if(package_name)
      if("CONFIG" IN_LIST find_package_args)
        list(REMOVE_ITEM find_package_args "CONFIG")

        if(type MATCHES "^(PRIVATE|PUBLIC|INTERFACE)$")
          set(type "${type}_CONFIG")
        endif()
      endif()

      if(${type} MATCHES ".*CONFIG")
        find_package(${package_name} CONFIG REQUIRED ${find_package_args})
      else()
        find_package(${package_name} REQUIRED ${find_package_args})
      endif()

      list(JOIN find_package_args " " installation_args)
      set_property(
        TARGET ${target} APPEND PROPERTY "PROJECT_OPTIONS_${type}_DEPENDENCIES"
                                         "${package_name} ${installation_args}"
      )
    endif()
  endmacro()

  while(unparsed_args)
    _parse_target_find_dependencies()
    _add_dependency()
  endwhile()
endfunction()
