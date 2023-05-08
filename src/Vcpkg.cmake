include_guard()

include(FetchContent)
include("${CMAKE_CURRENT_LIST_DIR}/Git.cmake")

macro(_find_vcpkg_repository)
  if(NOT
     "${_vcpkg_args_VCPKG_DIR}"
     STREQUAL
     "")
    # the installation directory is specified
    get_filename_component(VCPKG_PARENT_DIR "${_vcpkg_args_VCPKG_DIR}" DIRECTORY)
  else()
    # Default vcpkg installation directory
    if(WIN32)
      set(VCPKG_PARENT_DIR $ENV{userprofile})
      set(_vcpkg_args_VCPKG_DIR "${VCPKG_PARENT_DIR}/vcpkg")
    else()
      set(VCPKG_PARENT_DIR $ENV{HOME})
      set(_vcpkg_args_VCPKG_DIR "${VCPKG_PARENT_DIR}/vcpkg")
    endif()
  endif()
endmacro()

macro(_clone_vcpkg_repository)
  if("${_vcpkg_args_VCPKG_URL}" STREQUAL "")
    set(_vcpkg_args_VCPKG_URL "https://github.com/microsoft/vcpkg.git")
  endif()

  git_clone(
    REPOSITORY_PATH
    "${_vcpkg_args_VCPKG_DIR}"
    REMOTE_URL
    "${_vcpkg_args_VCPKG_URL}")
endmacro()

macro(_update_vcpkg_repository)
  if(${_vcpkg_args_ENABLE_VCPKG_UPDATE})
    git_pull(REPOSITORY_PATH "${_vcpkg_args_VCPKG_DIR}")
  endif()
endmacro()

macro(_bootstrap_vcpkg)
  if(WIN32 AND "${CMAKE_EXECUTABLE_SUFFIX}" STREQUAL "")
    set(CMAKE_EXECUTABLE_SUFFIX ".exe")
  endif()

  # if vcpkg executable does not exists
  # or if the user wants to update vcpkg
  if(NOT EXISTS "${_vcpkg_args_VCPKG_DIR}/vcpkg${CMAKE_EXECUTABLE_SUFFIX}" OR ${_vcpkg_args_ENABLE_VCPKG_UPDATE})
    # Run the vcpkg bootstrap
    if(WIN32)
      execute_process(COMMAND "bootstrap-vcpkg.bat" "-disableMetrics" WORKING_DIRECTORY "${_vcpkg_args_VCPKG_DIR}"
                                                                                        COMMAND_ERROR_IS_FATAL LAST)
    else()
      execute_process(COMMAND "./bootstrap-vcpkg.sh" "-disableMetrics" WORKING_DIRECTORY "${_vcpkg_args_VCPKG_DIR}"
                                                                                         COMMAND_ERROR_IS_FATAL LAST)
    endif()
  endif()
endmacro()

macro(_install_and_update_vcpkg)
  _clone_vcpkg_repository()
  _update_vcpkg_repository()
  _bootstrap_vcpkg()
endmacro()

macro(_checkout_vcpkg_repository)
  if(NOT
     "${_vcpkg_args_VCPKG_REV}"
     STREQUAL
     "")

    git_checkout(
      REPOSITORY_PATH
      "${_vcpkg_args_VCPKG_DIR}"
      REVISION
      "${_vcpkg_args_VCPKG_REV}")
  endif()
endmacro()

macro(_add_vcpkg_toolchain)
  # Setting up vcpkg toolchain
  list(APPEND VCPKG_FEATURE_FLAGS "versions")
  set(CMAKE_TOOLCHAIN_FILE
      ${_vcpkg_args_VCPKG_DIR}/scripts/buildsystems/vcpkg.cmake
      CACHE STRING "vcpkg toolchain file" FORCE)
endmacro()

macro(_cross_compiling_vcpkg)
  if(CROSSCOMPILING)
    if(NOT MINGW)
      if(NOT
         "${TARGET_ARCHITECTURE}"
         STREQUAL
         "")
        set(VCPKG_TARGET_TRIPLET "${TARGET_ARCHITECTURE}")
      endif()
      if(NOT
         "${DEFAULT_TRIPLET}"
         STREQUAL
         "")
        set(VCPKG_DEFAULT_TRIPLET "${DEFAULT_TRIPLET}")
      endif()
      if(NOT
         "${LIBRARY_LINKAGE}"
         STREQUAL
         "")
        set(VCPKG_LIBRARY_LINKAGE "${LIBRARY_LINKAGE}")
      endif()
    endif()

    if(NOT DEFINED VCPKG_CHAINLOAD_TOOLCHAIN_FILE)
      set(_toolchain_file)
      if(NOT
         "${CROSS_TOOLCHAIN_FILE}"
         STREQUAL
         "")
        set(_toolchain_file ${CROSS_TOOLCHAIN_FILE})
      else()
        get_toolchain_file(_toolchain_file)
      endif()

      if(NOT
         "${_toolchain_file}"
         STREQUAL
         "")
        set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE
            ${_toolchain_file}
            CACHE STRING "vcpkg chainload toolchain file" FORCE)
      endif()
    endif()
    message(STATUS "Setup cross-compiler for ${VCPKG_TARGET_TRIPLET}")
    message(STATUS "Use cross-compiler toolchain for vcpkg: ${VCPKG_CHAINLOAD_TOOLCHAIN_FILE}")
  endif()
endmacro()

#[[.rst:

.. include:: ../../docs/src/run_vcpkg.md
   :parser: myst_parser.sphinx_

#]]
macro(run_vcpkg)
  # named boolean ENABLE_VCPKG_UPDATE arguments
  set(options ENABLE_VCPKG_UPDATE)
  # optional named VCPKG_DIR, VCPKG_URL, and VCPKG_REV arguments
  set(oneValueArgs VCPKG_DIR VCPKG_URL VCPKG_REV)
  cmake_parse_arguments(
    _vcpkg_args
    "${options}"
    "${oneValueArgs}"
    ""
    ${ARGN})

  find_program(GIT_EXECUTABLE "git" REQUIRED)

  # find the vcpkg directory
  _find_vcpkg_repository()

  # install and update vcpkg if necessary
  _install_and_update_vcpkg()

  # checkout the given revision if necessary
  _checkout_vcpkg_repository()

  configure_mingw_vcpkg()

  # add the vcpkg toolchain
  _add_vcpkg_toolchain()

  configure_mingw_vcpkg_after()

  # setup cross-compiling if necessary
  _cross_compiling_vcpkg()
endmacro()
