# Uses ycm (permissive BSD-3-Clause license) and FowardArguments (permissive MIT license)

macro(package_project)
  set(_options # default to true
      ARCH_INDEPENDENT)
  set(_oneValueArgs
      # default all of these to the project_name or the given name:
      NAME
      NAMESPACE
      VARS_PREFIX
      EXPORT
      # default to project version:
      VERSION
      # default to any newer:
      COMPATIBILITY
      # include directory: default to include
      INCLUDE_DIR
      EXPORT_DESTINATION
      INSTALL_DESTINATION
      CONFIG_TEMPLATE
      COMPONENT)
  set(_multiValueArgs
      # default to the project_name or the given name:
      TARGETS
      DEPENDENCIES
      PRIVATE_DEPENDENCIES
      EXTRA_PATH_VARS_SUFFIX)

  cmake_parse_arguments(
    _PackageProject
    "${_options}"
    "${_oneValueArgs}"
    "${_multiValueArgs}"
    "${ARGN}")

  # Set default options

  # default name to the name of the project
  if("${_PackageProject_NAME}" STREQUAL "")
    set(_PackageProject_NAME ${PROJECT_NAME})
  endif()

  # default namespace to the given name or the name of the project
  if("${_PackageProject_NAMESPACE}" STREQUAL "")
    set(_PackageProject_NAMESPACE ${_PackageProject_NAME})
  endif()

  # default VARS_PREFIX to the given name or the name of the project
  if("${_PackageProject_VARS_PREFIX}" STREQUAL "")
    set(_PackageProject_VARS_PREFIX ${_PackageProject_NAME})
  endif()

  # default export to the given name or the name of the project
  if("${_PackageProject_EXPORT}" STREQUAL "")
    set(_PackageProject_EXPORT ${_PackageProject_NAME})
  endif()

  # default targets to the given name or the name of the project
  if("${_PackageProject_TARGETS}" STREQUAL "")
    set(_PackageProject_TARGETS ${_PackageProject_NAME})
  endif()

  # default version to the project version
  if("${_PackageProject_VERSION}" STREQUAL "")
    set(_PackageProject_VERSION ${PROJECT_VERSION})
  endif()

  # default compatibility to any newer version (since a lot of projects do not follow semver)
  if("${_PackageProject_COMPATIBILITY}" STREQUAL "")
    set(_PackageProject_COMPATIBILITY "AnyNewerVersion")
  endif()

  # default to arch dependant (works better with vcpkg, etc)
  if("${_PackageProject_ARCH_INDEPENDENT}" STREQUAL "")
    set(_PackageProject_ARCH_INDEPENDENT ON)
  endif()

  # Installation of public/interface includes
  if(EXISTS "${_PackageProject_INCLUDE_DIR}")
    install(DIRECTORY ${_PackageProject_INCLUDE_DIR} DESTINATION ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR})
  endif()

  # Installation of package (compatible with vcpkg, etc)
  install(
    TARGETS ${_PackageProject_TARGETS}
    EXPORT ${_PackageProject_EXPORT}
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}" COMPONENT shlib
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}" COMPONENT lib
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}" COMPONENT bin
    PUBLIC_HEADER DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${_PackageProject_NAME}" COMPONENT dev)

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
  unset(_PackageProject_TARGETS)

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
