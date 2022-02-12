# Uses ycm (permissive BSD-3-Clause license) and FowardArguments (permissive MIT license)

macro(package_project)
  set(_options ARCH_INDEPENDENT # default to false
  )
  set(_oneValueArgs
      # default to the project_name:
      NAME
      COMPONENT
      # default to project version:
      VERSION
      # default to any newer:
      COMPATIBILITY
      # default to ${CMAKE_BINARY_DIR}
      CONFIG_EXPORT_DESTINATION
      # default to ${CMAKE_INSTALL_DATADIR}/cmake/${NAME} suitable for vcpkg, etc.
      CONFIG_INSTALL_DESTINATION)
  set(_multiValueArgs
      # required
      TARGETS
      # a list of public/interface include directories or files
      PUBLIC_INCLUDES
      # the names of the INTERFACE/PUBLIC dependencies that are found using `CONFIG`
      PUBLIC_DEPENDENCIES_CONFIGED
      # the INTERFACE/PUBLIC dependencies that are found by any means using `find_dependency`.
      # the arguments must be specified within double quotes (e.g. "<dependency> 1.0.0 EXACT" or "<dependency> CONFIG").
      PUBLIC_DEPENDENCIES
      # the names of the PRIVATE dependencies that are found using `CONFIG`. Only included when BUILD_SHARED_LIBS is OFF.
      PRIVATE_DEPENDENCIES_CONFIGED
      # PRIVATE dependencies that are only included when BUILD_SHARED_LIBS is OFF
      PRIVATE_DEPENDENCIES)

  cmake_parse_arguments(
    _PackageProject
    "${_options}"
    "${_oneValueArgs}"
    "${_multiValueArgs}"
    "${ARGN}")

  if(NOT _PackageProject_TARGETS)
    message(FATAL_ERROR "No targets specified in `package_project` function")
  endif()

  # Set default options

  # default to the name of the project or the given name
  if("${_PackageProject_NAME}" STREQUAL "")
    set(_PackageProject_NAME ${PROJECT_NAME})
  endif()
  set(_PackageProject_NAMESPACE ${_PackageProject_NAME})
  set(_PackageProject_VARS_PREFIX ${_PackageProject_NAME})
  set(_PackageProject_EXPORT ${_PackageProject_NAME})

  # default version to the project version
  if("${_PackageProject_VERSION}" STREQUAL "")
    set(_PackageProject_VERSION ${PROJECT_VERSION})
  endif()

  # default compatibility to any newer version (since a lot of projects do not follow semver)
  if("${_PackageProject_COMPATIBILITY}" STREQUAL "")
    set(_PackageProject_COMPATIBILITY "AnyNewerVersion")
  endif()

  # use datadir (works better with vcpkg, etc)
  if("${_PackageProject_CONFIG_INSTALL_DESTINATION}" STREQUAL "")
    set(_PackageProject_CONFIG_INSTALL_DESTINATION "${CMAKE_INSTALL_DATADIR}/cmake/${_PackageProject_NAME}")
  endif()
  # ycm args
  set(_PackageProject_EXPORT_DESTINATION "${_PackageProject_CONFIG_EXPORT_DESTINATION}")
  set(_PackageProject_INSTALL_DESTINATION "${_PackageProject_CONFIG_INSTALL_DESTINATION}")

  # Installation of the public/interface includes
  if(NOT
     "${_PackageProject_PUBLIC_INCLUDES}"
     STREQUAL
     "")
    foreach(_INC ${_PackageProject_PUBLIC_INCLUDES})
      if(NOT IS_ABSOLUTE ${_INC})
        set(_INC "${CMAKE_CURRENT_SOURCE_DIR}/${_INC}")
      endif()
      if(IS_DIRECTORY ${_INC})
        install(DIRECTORY ${_INC} DESTINATION ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR})
      else()
        install(FILES ${_INC} DESTINATION ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR})
      endif()
    endforeach()
  endif()

  # Append the configed public dependencies
  if(_PackageProject_PUBLIC_DEPENDENCIES_CONFIGED)
    set(_PUBLIC_DEPENDENCIES_CONFIG)
    foreach(DEP ${_PackageProject_PUBLIC_DEPENDENCIES_CONFIGED})
      set(_PUBLIC_DEPENDENCIES_CONFIG "${_PUBLIC_DEPENDENCIES_CONFIG};${DEP} CONFIG")
    endforeach()
  endif()
  set(_PackageProject_PUBLIC_DEPENDENCIES "${_PackageProject_PUBLIC_DEPENDENCIES};${_PUBLIC_DEPENDENCIES_CONFIG}")
  # ycm arg
  set(_PackageProject_DEPENDENCIES "${_PackageProject_PUBLIC_DEPENDENCIES}")

  # Append the configed private dependencies
  if(_PackageProject_PRIVATE_DEPENDENCIES_CONFIGED)
    set(_PRIVATE_DEPENDENCIES_CONFIG)
    foreach(DEP ${_PackageProject_PRIVATE_DEPENDENCIES_CONFIGED})
      set(_PRIVATE_DEPENDENCIES_CONFIG "${_PRIVATE_DEPENDENCIES_CONFIG};${DEP} CONFIG")
    endforeach()
  endif()
  # ycm arg
  set(_PackageProject_PRIVATE_DEPENDENCIES "${_PackageProject_PRIVATE_DEPENDENCIES};${_PRIVATE_DEPENDENCIES_CONFIG}")

  # Installation of package (compatible with vcpkg, etc)
  install(
    TARGETS ${_PackageProject_TARGETS}
    EXPORT ${_PackageProject_EXPORT}
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}" COMPONENT shlib
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}" COMPONENT lib
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}" COMPONENT bin
    PUBLIC_HEADER DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${_PackageProject_NAME}" COMPONENT dev)

  unset(_PackageProject_TARGETS)

  # download FowardArguments
  FetchContent_Declare(
    _fargs
    URL https://github.com/polysquare/cmake-forward-arguments/archive/8c50d1f956172edb34e95efa52a2d5cb1f686ed2.zip)
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
    "${_options}"
    SINGLEVAR_ARGS
    "${_oneValueArgs}"
    MULTIVAR_ARGS
    "${_multiValueArgs}")

  # download ycm
  FetchContent_Declare(_ycm URL https://github.com/robotology/ycm/archive/refs/tags/v0.13.0.zip)
  FetchContent_GetProperties(_ycm)
  if(NOT _ycm_POPULATED)
    FetchContent_Populate(_ycm)
  endif()
  include("${_ycm_SOURCE_DIR}/modules/InstallBasicPackageFiles.cmake")

  install_basic_package_files(${_PackageProject_NAME} "${_FARGS_LIST}")

  include("${_ycm_SOURCE_DIR}/modules/AddUninstallTarget.cmake")
endmacro()
