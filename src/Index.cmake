cmake_minimum_required(VERSION 3.15)

include("${CMAKE_CURRENT_LIST_DIR}/StandardProjectSettings.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/PreventInSourceBuilds.cmake")

# Link this 'library' to set the c++ standard / compile-time options requested
add_library(project_options INTERFACE)

if(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
  option(ENABLE_BUILD_WITH_TIME_TRACE "Enable -ftime-trace to generate time tracing .json files on clang" OFF)
  if(ENABLE_BUILD_WITH_TIME_TRACE)
    target_compile_options(project_options INTERFACE -ftime-trace)
  endif()
endif()

# Link this 'library' to use the warnings specified in CompilerWarnings.cmake
add_library(project_warnings INTERFACE)

# enable cache system
include("${CMAKE_CURRENT_LIST_DIR}/Cache.cmake")

# Add linker configuration
include("${CMAKE_CURRENT_LIST_DIR}/Linker.cmake")
configure_linker(project_options)

# standard compiler warnings
include("${CMAKE_CURRENT_LIST_DIR}/CompilerWarnings.cmake")
set_project_warnings(project_warnings)

# sanitizer options if supported by compiler
include("${CMAKE_CURRENT_LIST_DIR}/Sanitizers.cmake")
enable_sanitizers(project_options)

# enable doxygen
include("${CMAKE_CURRENT_LIST_DIR}/Doxygen.cmake")
enable_doxygen()

# allow for static analysis options
include("${CMAKE_CURRENT_LIST_DIR}/StaticAnalyzers.cmake")

option(BUILD_SHARED_LIBS "Enable compilation of shared libraries" OFF)
option(ENABLE_TESTING "Enable Test Builds" ON)
option(ENABLE_FUZZING "Enable Fuzzing Builds" OFF)

# Very basic PCH example
option(ENABLE_PCH "Enable Precompiled Headers" OFF)
if(ENABLE_PCH)
  # This sets a global PCH parameter, each project will build its own PCH, which is a good idea if any #define's change
  #
  # consider breaking this out per project as necessary
  target_precompile_headers(
    project_options
    INTERFACE
    <vector>
    <string>
    <map>
    <utility>)
endif()

option(ENABLE_CONAN "Use Conan for dependency management" ON)
if(ENABLE_CONAN)
  include("${CMAKE_CURRENT_LIST_DIR}/Conan.cmake")
  run_conan()
endif()

option(ENABLE_UNITY "Enable Unity builds of projects" OFF)
if(ENABLE_UNITY)
  # Add for any project you want to apply unity builds for
  set_target_properties(main PROPERTIES UNITY_BUILD ON)
endif()
