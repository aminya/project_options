include(FetchContent)

macro(run_vcpkg)
  # optional named VCPKG_DIR argument
  set(oneValueArgs VCPKG_DIR)
  cmake_parse_arguments(
    ProjectOptions
    ""
    "${oneValueArgs}"
    ""
    ${ARGN})

  # Default vcpkg installation directory
  if(${ProjectOptions_VCPKG_DIR})
    # the installation directory is specified
  else()
    if(WIN32)
      set(HOME_DIR $ENV{userprofile})
      set(ProjectOptions_VCPKG_DIR ${HOME_DIR}/vcpkg)
    else()
      set(HOME_DIR $ENV{HOME})
      set(ProjectOptions_VCPKG_DIR ${HOME_DIR}/vcpkg)
    endif()
  endif()

  # check if the vcpkg is installed
  if(EXISTS ${ProjectOptions_VCPKG_DIR})
    message(STATUS "${ProjectOptions_VCPKG_DIR} already exists. Updating the repository...")
    execute_process(COMMAND "git" "pull" WORKING_DIRECTORY ${ProjectOptions_VCPKG_DIR})
  else()
    message(STATUS "Installing vcpkg at ${ProjectOptions_VCPKG_DIR}")
    # clone vcpkg from Github
    execute_process(COMMAND "git" "clone" "https://github.com/microsoft/vcpkg" WORKING_DIRECTORY ${HOME_DIR})
    # Run vcpkg bootstrap
    execute_process(COMMAND "./vcpkg/bootstrap-vcpkg" WORKING_DIRECTORY "${ProjectOptions_VCPKG_DIR}")
  endif()

  # Setting up vcpkg toolchain
  list(APPEND VCPKG_FEATURE_FLAGS "versions")
  set(CMAKE_TOOLCHAIN_FILE
      ${ProjectOptions_VCPKG_DIR}/scripts/buildsystems/vcpkg.cmake
      CACHE STRING "Vcpkg toolchain file")
endmacro()
