include_guard()

include(FetchContent)

# Install vcpkg and vcpkg dependencies: - should be called before defining project()
macro(run_vcpkg)
  # named boolean ENABLE_VCPKG_UPDATE argument
  set(options ENABLE_VCPKG_UPDATE)
  # optional named VCPKG_DIR and VCPKG_URL argument
  set(oneValueArgs VCPKG_DIR VCPKG_URL)
  cmake_parse_arguments(
    _vcpkg_args
    "${options}"
    "${oneValueArgs}"
    ""
    ${ARGN})

  if(NOT
     "${_vcpkg_args_VCPKG_DIR}"
     STREQUAL
     "")
    # the installation directory is specified
    get_filename_component(VCPKG_PARENT_DIR ${_vcpkg_args_VCPKG_DIR} DIRECTORY)
  else()
    # Default vcpkg installation directory
    if(WIN32)
      set(VCPKG_PARENT_DIR $ENV{userprofile})
      set(_vcpkg_args_VCPKG_DIR ${VCPKG_PARENT_DIR}/vcpkg)
    else()
      set(VCPKG_PARENT_DIR $ENV{HOME})
      set(_vcpkg_args_VCPKG_DIR ${VCPKG_PARENT_DIR}/vcpkg)
    endif()
  endif()

  # check if vcpkg is installed
  if(WIN32 AND "${CMAKE_EXECUTABLE_SUFFIX}" STREQUAL "")
    set(CMAKE_EXECUTABLE_SUFFIX ".exe")
  endif()
  if(EXISTS "${_vcpkg_args_VCPKG_DIR}" AND EXISTS "${_vcpkg_args_VCPKG_DIR}/vcpkg${CMAKE_EXECUTABLE_SUFFIX}")
    message(STATUS "vcpkg is already installed at ${_vcpkg_args_VCPKG_DIR}.")
    if(${_vcpkg_args_ENABLE_VCPKG_UPDATE})
      message(STATUS "Updating the repository...")
      execute_process(COMMAND "git" "pull" WORKING_DIRECTORY ${_vcpkg_args_VCPKG_DIR})
    endif()
  else()
    message(STATUS "Installing vcpkg at ${_vcpkg_args_VCPKG_DIR}")
    # clone vcpkg from Github
    if(NOT EXISTS "${_vcpkg_args_VCPKG_DIR}")
      if("${_vcpkg_args_VCPKG_URL}" STREQUAL "")
        set(_vcpkg_args_VCPKG_URL "https://github.com/microsoft/vcpkg.git")
      endif()
      find_program(GIT_EXECUTABLE "git" REQUIRED)
      execute_process(COMMAND "${GIT_EXECUTABLE}" "clone" "${_vcpkg_args_VCPKG_URL}"
                      WORKING_DIRECTORY ${VCPKG_PARENT_DIR} COMMAND_ERROR_IS_FATAL LAST)
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

  # if mingw, use the correct triplet (otherwise it will fail to link libraries)
  include("${ProjectOptions_SRC_DIR}/DetectCompiler.cmake")
  if(MinGW OR (WIN32 AND "${DETECTED_CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU"))
    include("${ProjectOptions_SRC_DIR}/Utilities.cmake")
    detect_architecture(_arch)
    string(TOLOWER "${_arch}" _arch)

    # Based on this issue, vcpkg uses MINGW variable https://github.com/microsoft/vcpkg/issues/23607#issuecomment-1071966853
    set(MINGW TRUE)

    # Based on the docs https://github.com/microsoft/vcpkg/blob/master/docs/users/mingw.md (but it doesn't work!)
    set(VCPKG_DEFAULT_TRIPLET
        "${_arch}-mingw-dynamic"
        CACHE STRING "Default triplet for vcpkg" FORCE)
    set(VCPKG_DEFAULT_HOST_TRIPLET
        "${_arch}-mingw-dynamic"
        CACHE STRING "Default target triplet for vcpkg" FORCE)
    set($ENV{VCPKG_DEFAULT_TRIPLET} "${_arch}-mingw-dynamic")
    set($ENV{VCPKG_DEFAULT_HOST_TRIPLET} "${_arch}-mingw-dynamic")
  endif()

  # Setting up vcpkg toolchain
  list(APPEND VCPKG_FEATURE_FLAGS "versions")
  set(CMAKE_TOOLCHAIN_FILE
      ${_vcpkg_args_VCPKG_DIR}/scripts/buildsystems/vcpkg.cmake
      CACHE STRING "vcpkg toolchain file")
endmacro()
