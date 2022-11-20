include_guard()

include(FetchContent)

# Install vcpkg and vcpkg dependencies: - should be called before defining project()
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

  # check if vcpkg is installed
  if(WIN32 AND "${CMAKE_EXECUTABLE_SUFFIX}" STREQUAL "")
    set(CMAKE_EXECUTABLE_SUFFIX ".exe")
  endif()
  if(EXISTS "${_vcpkg_args_VCPKG_DIR}" AND EXISTS "${_vcpkg_args_VCPKG_DIR}/vcpkg${CMAKE_EXECUTABLE_SUFFIX}")
    message(STATUS "vcpkg is already installed at ${_vcpkg_args_VCPKG_DIR}.")
    if(${_vcpkg_args_ENABLE_VCPKG_UPDATE})

      if(NOT
         "${_vcpkg_args_VCPKG_REV}"
         STREQUAL
         "")
        # detect if the head is detached, if so, switch back before calling git pull on a detached head
        set(_vcpkg_git_status "")
        execute_process(
          COMMAND "${GIT_EXECUTABLE}" "rev-parse" "--abbrev-ref" "--symbolic-full-name" "HEAD"
          OUTPUT_VARIABLE _vcpkg_git_status
          WORKING_DIRECTORY "${_vcpkg_args_VCPKG_DIR}"
          OUTPUT_STRIP_TRAILING_WHITESPACE)
        if("${_vcpkg_git_status}" STREQUAL "HEAD")
          message(STATUS "Switching back before updating")
          execute_process(COMMAND "${GIT_EXECUTABLE}" "switch" "-" WORKING_DIRECTORY "${_vcpkg_args_VCPKG_DIR}")
        endif()
      endif()

      message(STATUS "Updating the repository...")
      execute_process(COMMAND "${GIT_EXECUTABLE}" "pull" WORKING_DIRECTORY "${_vcpkg_args_VCPKG_DIR}")
    endif()
  else()
    message(STATUS "Installing vcpkg at ${_vcpkg_args_VCPKG_DIR}")
    # clone vcpkg from Github
    if("${_vcpkg_args_VCPKG_URL}" STREQUAL "")
      set(_vcpkg_args_VCPKG_URL "https://github.com/microsoft/vcpkg.git")
    endif()
    if(NOT EXISTS "${_vcpkg_args_VCPKG_DIR}")
      execute_process(COMMAND "${GIT_EXECUTABLE}" "clone" "${_vcpkg_args_VCPKG_URL}"
                      WORKING_DIRECTORY "${VCPKG_PARENT_DIR}" COMMAND_ERROR_IS_FATAL LAST)
    else()
      # ensure that the given vcpkg remote is the current remote
      execute_process(
        COMMAND "${GIT_EXECUTABLE}" "remote" "-v"
        WORKING_DIRECTORY "${VCPKG_PARENT_DIR}" COMMAND_ERROR_IS_FATAL LAST
        OUTPUT_VARIABLE _vcpkg_git_remote_info)
      string(FIND "${_vcpkg_git_remote_info}" "${_vcpkg_args_VCPKG_URL}" _vcpkg_has_remote)
      if(NOT ${_vcpkg_has_remote})
        message(
          FATAL
          "The current vcpkg remote at ${_vcpkg_args_VCPKG_DIR} does not match the given URL ${_vcpkg_args_VCPKG_URL}")
      endif()
    endif()
    # Run vcpkg bootstrap
    if(WIN32)
      execute_process(COMMAND "bootstrap-vcpkg.bat" "-disableMetrics" WORKING_DIRECTORY "${_vcpkg_args_VCPKG_DIR}"
                                                                                        COMMAND_ERROR_IS_FATAL LAST)
    else()
      execute_process(COMMAND "./bootstrap-vcpkg.sh" "-disableMetrics" WORKING_DIRECTORY "${_vcpkg_args_VCPKG_DIR}"
                                                                                         COMMAND_ERROR_IS_FATAL LAST)
    endif()
  endif()

  if(NOT
     "${_vcpkg_args_VCPKG_REV}"
     STREQUAL
     "")
    execute_process(COMMAND "${GIT_EXECUTABLE}" "checkout" "${_vcpkg_args_VCPKG_REV}"
                    WORKING_DIRECTORY "${VCPKG_PARENT_DIR}/vcpkg" COMMAND_ERROR_IS_FATAL LAST)
  endif()

  configure_mingw_vcpkg()

  # Setting up vcpkg toolchain
  list(APPEND VCPKG_FEATURE_FLAGS "versions")
  set(CMAKE_TOOLCHAIN_FILE
      ${_vcpkg_args_VCPKG_DIR}/scripts/buildsystems/vcpkg.cmake
      CACHE STRING "vcpkg toolchain file" FORCE)

  configure_mingw_vcpkg_after()

  if(CROSSCOMPILING)
    if(NOT MINGW)
      if(TARGET_ARCHITECTURE)
        set(VCPKG_TARGET_TRIPLET "${TARGET_ARCHITECTURE}")
      endif()
      if(DEFAULT_TRIPLET)
        set(VCPKG_DEFAULT_TRIPLET "${DEFAULT_TRIPLET}")
      endif()
      if(LIBRARY_LINKAGE)
        set(VCPKG_LIBRARY_LINKAGE "${LIBRARY_LINKAGE}")
      endif()
    endif()
    set(_toolchain_file)
    get_toolchain_file(_toolchain_file)
    if(_toolchain_file)
      set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE
          ${_toolchain_file}
          CACHE STRING "vcpkg chainload toolchain file")
      message(STATUS "Setup cross-compiler for ${VCPKG_TARGET_TRIPLET}")
      message(STATUS "Use cross-compiler toolchain: ${VCPKG_CHAINLOAD_TOOLCHAIN_FILE}")
    endif()
  endif()
endmacro()
