include_guard()

# This function sets ProjectOptions_SRC_DIR using the current lists path
macro(set_project_options_src_dir)
  get_directory_property(LISTFILE_STACK LISTFILE_STACK)
  list(POP_BACK LISTFILE_STACK _LIST_FILE)
  cmake_path(
    GET
    _LIST_FILE
    PARENT_PATH
    ProjectOptions_SRC_DIR)
endmacro()

# Common project settings run by default for all the projects that call `project_options()`
macro(common_project_options)
  set_project_options_src_dir()
  message(DEBUG "${ProjectOptions_SRC_DIR}")

  include("${ProjectOptions_SRC_DIR}/PreventInSourceBuilds.cmake")
  assure_out_of_source_builds()

  # Set a default build type if none was specified
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message(STATUS "Setting build type to 'RelWithDebInfo' as none was specified.")
    set(CMAKE_BUILD_TYPE
        RelWithDebInfo
        CACHE STRING "Choose the type of build." FORCE)
    # Set the possible values of build type for cmake-gui, ccmake
    set_property(
      CACHE CMAKE_BUILD_TYPE
      PROPERTY STRINGS
               "Debug"
               "Release"
               "MinSizeRel"
               "RelWithDebInfo")
  endif()

  get_property(BUILDING_MULTI_CONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
  if(BUILDING_MULTI_CONFIG)
    if(NOT CMAKE_BUILD_TYPE)
      # Make sure that all supported configuration types have their
      # associated conan packages available. You can reduce this
      # list to only the configuration types you use, but only if one
      # is not forced-set on the command line for VS
      message(TRACE "Setting up multi-config build types")
      set(CMAKE_CONFIGURATION_TYPES
          Debug
          Release
          RelWithDebInfo
          MinSizeRel
          CACHE STRING "Enabled build types" FORCE)
    else()
      message(TRACE "User chose a specific build type, so we are using that")
      set(CMAKE_CONFIGURATION_TYPES
          ${CMAKE_BUILD_TYPE}
          CACHE STRING "Enabled build types" FORCE)
    endif()
  endif()

  # Fix for Amnet/Colcon
  if(NOT
     "${AMENT_PREFIX_PATH}"
     STREQUAL
     ""
     OR "$ENV{COLCON}" STREQUAL "1")
    # these are used in order:
    set(CMAKE_MAP_IMPORTED_CONFIG_RELWITHDEBINFO
        "RelWithDebInfo;Release;None;NoConfig;"
        CACHE STRING "Fallbacks for the RelWithDebInfo build type")
  endif()

  # Generate and possibly symlink compile_commands.json to make it easier to work with clang based tools
  if(CMAKE_GENERATOR MATCHES ".*Makefile*." OR CMAKE_GENERATOR MATCHES ".*Ninja*")
    # Enable generate compile_commands.json
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

    # Make a symbol link of compile_commands.json on the source dir to help clang based tools find it
    if(WIN32)
      # Detect whether cmake is run as administrator (only administrator can read the LOCAL SERVICE account reg key)
      execute_process(
        COMMAND reg query "HKU\\S-1-5-19"
        ERROR_VARIABLE IS_NONADMINISTRATOR
        OUTPUT_QUIET)
    else()
      set(IS_NONADMINISTRATOR "")
    endif()

    if(IS_NONADMINISTRATOR)
      # For non-administrator, create an auxiliary target and ask user to run it
      add_custom_command(
        OUTPUT ${CMAKE_SOURCE_DIR}/compile_commands.json
        COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/compile_commands.json
                ${CMAKE_SOURCE_DIR}/compile_commands.json
        DEPENDS ${CMAKE_BINARY_DIR}/compile_commands.json
        VERBATIM)
      add_custom_target(
        _copy_compile_commands
        DEPENDS ${CMAKE_SOURCE_DIR}/compile_commands.json
        VERBATIM)
      message(
        STATUS
          "compile_commands.json was not symlinked to the root. Run `cmake --build <build_dir> -t _copy_compile_commands` if needed."
      )
    else()
      file(
        CREATE_LINK
        ${CMAKE_BINARY_DIR}/compile_commands.json
        ${CMAKE_SOURCE_DIR}/compile_commands.json
        SYMBOLIC)
      message(TRACE "compile_commands.json was symlinked to the root.")
    endif()

    # Add compile_commans.json to .gitignore if .gitignore exists
    set(GITIGNORE_FILE "${CMAKE_SOURCE_DIR}/.gitignore")

    if(EXISTS ${GITIGNORE_FILE})
      file(STRINGS ${GITIGNORE_FILE} HAS_IGNORED REGEX "^compile_commands.json")

      if(NOT HAS_IGNORED)
        message(TRACE "Adding compile_commands.json to .gitignore")
        file(APPEND ${GITIGNORE_FILE} "\ncompile_commands.json")
      endif()
    endif()
  endif()

  # Enhance error reporting and compiler messages
  if(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    if(WIN32)
      # On Windows cuda nvcc uses cl and not clang
      add_compile_options($<$<COMPILE_LANGUAGE:C>:-fcolor-diagnostics> $<$<COMPILE_LANGUAGE:CXX>:-fcolor-diagnostics>)
    else()
      add_compile_options(-fcolor-diagnostics)
    endif()
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    if(WIN32)
      # On Windows cuda nvcc uses cl and not gcc
      add_compile_options($<$<COMPILE_LANGUAGE:C>:-fdiagnostics-color=always>
                          $<$<COMPILE_LANGUAGE:CXX>:-fdiagnostics-color=always>)
    else()
      add_compile_options(-fdiagnostics-color=always)
    endif()
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" AND MSVC_VERSION GREATER 1900)
    add_compile_options(/diagnostics:column)
  else()
    message(STATUS "No colored compiler diagnostic set for '${CMAKE_CXX_COMPILER_ID}' compiler.")
  endif()

  include("${ProjectOptions_SRC_DIR}/Standards.cmake")
  set_standards()

  # run vcvarsall when msvc is used
  run_vcvarsall()
endmacro()
