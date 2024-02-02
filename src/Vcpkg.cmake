include_guard()

include(FetchContent)
include("${CMAKE_CURRENT_LIST_DIR}/Git.cmake")

macro(_find_vcpkg_repository)
  if(NOT "${_vcpkg_args_VCPKG_DIR}" STREQUAL "")
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

  git_clone(REPOSITORY_PATH "${_vcpkg_args_VCPKG_DIR}" REMOTE_URL "${_vcpkg_args_VCPKG_URL}")
endmacro()

macro(_update_vcpkg_repository)
  if(${_vcpkg_args_ENABLE_VCPKG_UPDATE})
    git_pull(REPOSITORY_PATH "${_vcpkg_args_VCPKG_DIR}" TARGET_REVISION "${_vcpkg_args_VCPKG_REV}")
  endif()
endmacro()

macro(_bootstrap_vcpkg)
  if(WIN32 AND "${CMAKE_EXECUTABLE_SUFFIX}" STREQUAL "")
    set(CMAKE_EXECUTABLE_SUFFIX ".exe")
  endif()

  # if vcpkg executable does not exists
  # or if the user wants to update vcpkg
  if(NOT EXISTS "${_vcpkg_args_VCPKG_DIR}/vcpkg${CMAKE_EXECUTABLE_SUFFIX}"
     OR ${_vcpkg_args_ENABLE_VCPKG_UPDATE}
  )
    # Run the vcpkg bootstrap
    if(WIN32)
      execute_process(
        COMMAND "bootstrap-vcpkg.bat" "-disableMetrics"
        WORKING_DIRECTORY "${_vcpkg_args_VCPKG_DIR}" COMMAND_ERROR_IS_FATAL LAST
      )
    else()
      execute_process(
        COMMAND "./bootstrap-vcpkg.sh" "-disableMetrics"
        WORKING_DIRECTORY "${_vcpkg_args_VCPKG_DIR}" COMMAND_ERROR_IS_FATAL LAST
      )
    endif()
  endif()
endmacro()

macro(_is_vcpkg_outdated)
  # skip the update if the requested revision is the same as the current revision
  git_revision(_REVISION REPOSITORY_PATH "${_vcpkg_args_VCPKG_DIR}")
  if(NOT "${_vcpkg_args_VCPKG_REV}" STREQUAL "" AND "${_REVISION}" STREQUAL
                                                    "${_vcpkg_args_VCPKG_REV}"
  )
    message(STATUS "Skipping vcpkg update as it's already at ${_REVISION}")
    set(_vcpkg_args_ENABLE_VCPKG_UPDATE OFF)
  elseif(NOT "${_vcpkg_args_VCPKG_REV}" STREQUAL "" AND NOT "${_REVISION}" STREQUAL
                                                        "${_vcpkg_args_VCPKG_REV}"
  )
    # Requested revision is different from the current revision, so update
    set(_vcpkg_args_ENABLE_VCPKG_UPDATE ON)
  else()
    # Requested revision is not specified, so update depending on the timestamp
    # Check if the vcpkg registry is updated using the timestamp file that project_option generates
    if("${_vcpkg_args_VCPKG_UPDATE_THRESHOLD}" STREQUAL "")
      set(_vcpkg_args_VCPKG_UPDATE_THRESHOLD 3600)
    endif()

    if(${_vcpkg_args_ENABLE_VCPKG_UPDATE})
      set(_time_stamp_file "${VCPKG_PARENT_DIR}/.vcpkg_last_update")

      if(EXISTS "${_time_stamp_file}")
        string(TIMESTAMP _current_time "%s")
        file(TIMESTAMP "${_time_stamp_file}" _vcpkg_last_update "%s")
        # if the last update was more than VCPKG_UPDATE_THRESHOLD
        math(EXPR time_diff "${_current_time} - ${_vcpkg_last_update}")
        if(${time_diff} GREATER ${_vcpkg_args_VCPKG_UPDATE_THRESHOLD})
          set(_vcpkg_args_ENABLE_VCPKG_UPDATE ON)
          file(TOUCH "${_time_stamp_file}")
        else()
          message(STATUS "vcpkg updated recently. Skipping update.")
          set(_vcpkg_args_ENABLE_VCPKG_UPDATE OFF)
        endif()
      else()
        set(_vcpkg_args_ENABLE_VCPKG_UPDATE ON)
        file(TOUCH "${_time_stamp_file}")
      endif()
    endif()
  endif()
endmacro()

macro(_install_and_update_vcpkg)
  _clone_vcpkg_repository()
  _is_vcpkg_outdated()
  _update_vcpkg_repository()
  _bootstrap_vcpkg()
endmacro()

macro(_checkout_vcpkg_repository)
  if(NOT "${_vcpkg_args_VCPKG_REV}" STREQUAL "")
    git_checkout(REPOSITORY_PATH "${_vcpkg_args_VCPKG_DIR}" REVISION "${_vcpkg_args_VCPKG_REV}")
  endif()
endmacro()

macro(_add_vcpkg_toolchain)
  # Setting up vcpkg toolchain
  list(APPEND VCPKG_FEATURE_FLAGS "versions")
  set(CMAKE_TOOLCHAIN_FILE ${_vcpkg_args_VCPKG_DIR}/scripts/buildsystems/vcpkg.cmake
      CACHE STRING "vcpkg toolchain file" FORCE
  )
endmacro()

macro(_cross_compiling_vcpkg)
  if(CROSSCOMPILING)
    if(NOT MINGW)
      if(NOT "${TARGET_ARCHITECTURE}" STREQUAL "")
        set(VCPKG_TARGET_TRIPLET "${TARGET_ARCHITECTURE}")
      endif()
      if(NOT "${DEFAULT_TRIPLET}" STREQUAL "")
        set(VCPKG_DEFAULT_TRIPLET "${DEFAULT_TRIPLET}")
      endif()
      if(NOT "${LIBRARY_LINKAGE}" STREQUAL "")
        set(VCPKG_LIBRARY_LINKAGE "${LIBRARY_LINKAGE}")
      endif()
    endif()

    if(NOT DEFINED VCPKG_CHAINLOAD_TOOLCHAIN_FILE)
      set(_toolchain_file)
      if(NOT "${CROSS_TOOLCHAIN_FILE}" STREQUAL "")
        set(_toolchain_file ${CROSS_TOOLCHAIN_FILE})
      else()
        get_toolchain_file(_toolchain_file)
      endif()

      if(NOT "${_toolchain_file}" STREQUAL "")
        set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE ${_toolchain_file}
            CACHE STRING "vcpkg chainload toolchain file" FORCE
        )
      endif()
    endif()
    message(STATUS "Setup cross-compiler for ${VCPKG_TARGET_TRIPLET}")
    message(STATUS "Use cross-compiler toolchain for vcpkg: ${VCPKG_CHAINLOAD_TOOLCHAIN_FILE}")
  endif()
endmacro()

#[[.rst:

``run_vcpkg``
=============

Install vcpkg and vcpkg dependencies:

.. code:: cmake

   run_vcpkg()

Or by specifying the options

.. code:: cmake

   run_vcpkg(
       VCPKG_URL "https://github.com/microsoft/vcpkg.git"
       VCPKG_REV "10e052511428d6b0c7fcc63a139e8024bb146032"
       ENABLE_VCPKG_UPDATE
   )

Note that it should be called before defining ``project()``.

Named Option:

-  ``ENABLE_VCPKG_UPDATE``: (Disabled by default). If enabled, the vcpkg
   registry is updated before building (using ``git pull``).

   If ``VCPKG_REV`` is set to a specific commit sha, no rebuilds are
   triggered. If ``VCPKG_REV`` is not specified or is a branch, enabling
   ``ENABLE_VCPKG_UPDATE`` will rebuild your updated vcpkg dependencies.

Named String:

-  ``VCPKG_DIR``: (Defaults to ``~/vcpkg``). You can provide the vcpkg
   installation directory using this optional parameter. If the
   directory does not exist, it will automatically install vcpkg in this
   directory.

-  ``VCPKG_URL``: (Defaults to
   ``https://github.com/microsoft/vcpkg.git``). This option allows
   setting the URL of the vcpkg repository. By default, the official
   vcpkg repository is used.

-  ``VCPKG_REV``: This option allows checking out a specific branch name
   or a commit sha. If ``VCPKG_REV`` is set to a specific commit sha,
   the builds will become reproducible because that exact commit is
   always used for the builds. To make sure that this commit sha is
   pulled, enable ``ENABLE_VCPKG_UPDATE``


- ``VCPKG_UPDATE_THRESHOLD``: (Defaults to 3600 seconds). This option
  allows setting the time threshold in seconds for updating the vcpkg
  registry. If ``ENABLE_VCPKG_UPDATE`` is enabled, the vcpkg registry
  will be updated if the last update was more than
  ``VCPKG_UPDATE_THRESHOLD`` seconds ago.

]]
macro(run_vcpkg)
  # named boolean ENABLE_VCPKG_UPDATE arguments
  set(options ENABLE_VCPKG_UPDATE)
  # optional named VCPKG_DIR, VCPKG_URL, and VCPKG_REV arguments
  set(oneValueArgs VCPKG_DIR VCPKG_URL VCPKG_REV VCPKG_UPDATE_THRESHOLD)
  cmake_parse_arguments(_vcpkg_args "${options}" "${oneValueArgs}" "" ${ARGN})

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
