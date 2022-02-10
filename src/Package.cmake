# Uses ycm (permissive BSD-3-Clause license) and FowardArguments (permissive MIT license)

function(package_project)
  set(_options
      ARCH_INDEPENDENT
      NO_EXPORT
      NO_SET_AND_CHECK_MACRO
      NO_CHECK_REQUIRED_COMPONENTS_MACRO
      UPPERCASE_FILENAMES
      LOWERCASE_FILENAMES)
  set(_oneValueArgs
      VERSION
      COMPATIBILITY
      EXPORT
      VARS_PREFIX
      EXPORT_DESTINATION
      INSTALL_DESTINATION
      NAMESPACE
      CONFIG_TEMPLATE
      INCLUDE_FILE
      INCLUDE_CONTENT
      COMPONENT)
  set(_multiValueArgs EXTRA_PATH_VARS_SUFFIX DEPENDENCIES PRIVATE_DEPENDENCIES)

  cmake_parse_arguments(
    _PackageProject
    "${_options}"
    "${_oneValueArgs}"
    "${_multiValueArgs}"
    "${ARGN}")

  # download FowardArguments (premisive MIT license)
  FetchContent_Declare(
    _fargs
    URL https://github.com/polysquare/cmake-forward-arguments/archive/8c50d1f956172edb34e95efa52a2d5cb1f686ed2.zip)
  FetchContent_GetProperties(_fargs)
  if(NOT _fargs_POPULATED)
    FetchContent_Populate(_fargs)
  endif()
  include("${_fargs_SOURCE_DIR}/ForwardArguments.cmake")

  cmake_forward_arguments(
    _PackageProject
    _PackageProject_ARGS_LIST
    OPTION_ARGS
    "${_options}"
    SINGLEVAR_ARGS
    "${_oneValueArgs}"
    MULTIVAR_ARGS
    "${_multiValueArgs}")

  # download ycm (premisive BSD-3-Clause license)
  FetchContent_Declare(_ycm URL https://github.com/robotology/ycm/archive/refs/tags/v0.13.0.zip)
  FetchContent_GetProperties(_ycm)
  if(NOT _ycm_POPULATED)
    FetchContent_Populate(_ycm)
  endif()
  include("${_ycm_SOURCE_DIR}/modules/InstallBasicPackageFiles.cmake")

  install_basic_package_files("${_PackageProject_ARGS_LIST}")

  include("${_ycm_SOURCE_DIR}/modules/AddUninstallTarget.cmake")
endfunction()
