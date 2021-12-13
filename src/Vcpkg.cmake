include(FetchContent)

macro(run_vcpkg)
  # named boolean ENABLE_VCPKG_UPDATE argument
  set(options ENABLE_VCPKG_UPDATE)
  # optional named VCPKG_DIR argument
  set(oneValueArgs VCPKG_DIR)
  cmake_parse_arguments(
    project_options
    ""
    "${oneValueArgs}"
    ""
    ${ARGN})

  if(${ProjectOptions_VCPKG_DIR})
    # the installation directory is specified
    get_filename_component(VCPKG_PARENT_DIR ${ProjectOptions_VCPKG_DIR} DIRECTORY)
  else()
    # Default vcpkg installation directory
    if(WIN32)
      set(VCPKG_PARENT_DIR $ENV{userprofile})
      set(ProjectOptions_VCPKG_DIR ${VCPKG_PARENT_DIR}/vcpkg)
    else()
      set(VCPKG_PARENT_DIR $ENV{HOME})
      set(ProjectOptions_VCPKG_DIR ${VCPKG_PARENT_DIR}/vcpkg)
    endif()
  endif()

  # check if the vcpkg is installed
  if(EXISTS ${ProjectOptions_VCPKG_DIR})
    message(STATUS "${ProjectOptions_VCPKG_DIR} already exists.")
    if(${ProjectOptions_ENABLE_VCPKG_UPDATE})
      message(STATUS "Updating the repository...")
      execute_process(COMMAND "git" "pull" WORKING_DIRECTORY ${ProjectOptions_VCPKG_DIR})
    endif()
  else()
    message(STATUS "Installing vcpkg at ${ProjectOptions_VCPKG_DIR}")
    # clone vcpkg from Github
    execute_process(COMMAND "git" "clone" "https://github.com/microsoft/vcpkg" WORKING_DIRECTORY ${VCPKG_PARENT_DIR})
    # Run vcpkg bootstrap
    execute_process(COMMAND "./vcpkg/bootstrap-vcpkg" WORKING_DIRECTORY "${ProjectOptions_VCPKG_DIR}")
  endif()

  # Setting up vcpkg toolchain
  list(APPEND VCPKG_FEATURE_FLAGS "versions")
  set(CMAKE_TOOLCHAIN_FILE
      ${ProjectOptions_VCPKG_DIR}/scripts/buildsystems/vcpkg.cmake
      CACHE STRING "Vcpkg toolchain file")
endmacro()
