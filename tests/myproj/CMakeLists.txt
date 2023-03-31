cmake_minimum_required(VERSION 3.16...3.21)

# set a default CXX standard used by the external tools like clang-tidy, cppcheck, etc.
# You can later set fine-grained standards for each target using `target_compile_features`
set(CMAKE_CXX_STANDARD 20)

### Add project_options
# include(FetchContent)
# FetchContent_Declare(_project_options URL https://github.com/aminya/project_options/archive/refs/heads/main.zip)
# FetchContent_MakeAvailable(_project_options)
# include(${_project_options_SOURCE_DIR}/Index.cmake)
include(../../src/Index.cmake)

# opt-in cross-compiling
option(ENABLE_CROSS_COMPILING "Detect cross compiler and setup toolchain" OFF)
if(ENABLE_CROSS_COMPILING)
  enable_cross_compiler()
endif()
run_vcpkg()

project(
  myproj
  VERSION 0.2.0
  LANGUAGES CXX C)

set(PCH_HEADERS
    <Eigen/Dense>
    <fmt/core.h>
    <vector>
    <utility>
    <string>
    <string_view>)

# Enable sanitizers and static analyzers when running the tests
set(ENABLE_SANITIZER_ADDRESS OFF)
set(ENABLE_SANITIZER_UNDEFINED_BEHAVIOR OFF)
if(NOT
   "${CMAKE_SYSTEM_NAME}"
   STREQUAL
   "Windows")
  set(ENABLE_SANITIZER_ADDRESS "ENABLE_SANITIZER_ADDRESS")
  set(ENABLE_SANITIZER_UNDEFINED_BEHAVIOR "ENABLE_SANITIZER_UNDEFINED_BEHAVIOR")
else()
  # or it is MSVC and has run vcvarsall
  string(FIND "$ENV{PATH}" "$ENV{VSINSTALLDIR}" index_of_vs_install_dir)
  if(MSVC AND "${index_of_vs_install_dir}" STREQUAL "-1")
    set(ENABLE_SANITIZER_ADDRESS "ENABLE_SANITIZER_ADDRESS")
  endif()
endif()

# Initialize project_options
# uncomment the options to enable them
project_options(
  PREFIX
  "myproj"
  ENABLE_CACHE
  ENABLE_CONAN
  # WARNINGS_AS_ERRORS
  ENABLE_CPPCHECK
  ENABLE_CLANG_TIDY
  # ENABLE_INCLUDE_WHAT_YOU_USE
  ENABLE_COVERAGE
  ENABLE_PCH
  PCH_HEADERS
  ${PCH_HEADERS}
  ENABLE_DOXYGEN
  ENABLE_INTERPROCEDURAL_OPTIMIZATION
  ENABLE_NATIVE_OPTIMIZATION
  # ENABLE_BUILD_WITH_TIME_TRACE
  # ENABLE_UNITY
  ${ENABLE_SANITIZER_ADDRESS}
  # ENABLE_SANITIZER_LEAK
  ${ENABLE_SANITIZER_UNDEFINED_BEHAVIOR}
  # ENABLE_SANITIZER_THREAD
  # ENABLE_SANITIZER_MEMORY
  # CLANG_WARNINGS "-Weverything"
)
# NOTE: project_options and project_warnings are defined inside project_options

# Executable
add_executable(main ./src/main/main.cpp)
target_link_libraries(main PRIVATE myproj_project_options myproj_project_warnings)

## dependencies
set(DEPENDENCIES_CONFIGURED fmt Eigen3 docopt)

foreach(DEPENDENCY ${DEPENDENCIES_CONFIGURED})
  find_package(${DEPENDENCY} CONFIG REQUIRED)
endforeach()

target_link_system_libraries(
  main
  PRIVATE
  fmt::fmt
  Eigen3::Eigen)

add_subdirectory(libs)

## tests
enable_testing()
add_test(NAME main COMMAND main)

# Header-only library
add_library(lib INTERFACE)
set(lib_INCLUDE_DIR "include")
target_include_directories(lib INTERFACE "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${lib_INCLUDE_DIR}>"
                                         "$<INSTALL_INTERFACE:./${CMAKE_INSTALL_INCLUDEDIR}>") # TODO(refactor)
target_link_libraries(lib INTERFACE myproj_project_options myproj_project_warnings)
target_link_system_libraries(
  lib
  INTERFACE
  fmt::fmt
  Eigen3::Eigen)

# Library
add_library(lib2 "./src/mylib2/lib.cpp")
set(lib2_INCLUDE_DIR2 "include")
target_include_directories(lib2 PUBLIC "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${lib2_INCLUDE_DIR2}>"
                                       "$<INSTALL_INTERFACE:./${CMAKE_INSTALL_INCLUDEDIR}>") # TODO(refactor)
target_link_libraries(lib2 PRIVATE myproj_project_options myproj_project_warnings)
target_link_system_libraries(
  lib2
  PRIVATE
  fmt::fmt
  Eigen3::Eigen)
target_link_system_libraries(lib2 PRIVATE mythirdpartylib)

# package everything automatically
package_project(
  # NAME
  # myproj
  # TARGETS
  # main
  # lib
  # myproj_project_warnings
  # myproj_project_options
  INTERFACE_DEPENDENCIES_CONFIGURED
  ${DEPENDENCIES_CONFIGURED}
  INTERFACE_INCLUDES
  ${lib_INCLUDE_DIR2}
  PUBLIC_INCLUDES
  ${lib2_INCLUDE_DIR2})

# package separately (for testing)
package_project(
  NAME
  myproj_header_only_lib
  TARGETS
  lib
  myproj_project_options
  myproj_project_warnings
  INTERFACE_DEPENDENCIES_CONFIGURED
  ${DEPENDENCIES_CONFIGURED}
  INTERFACE_INCLUDES
  ${lib_INCLUDE_DIR})

package_project(
  NAME
  myproj_lib
  TARGETS
  lib2
  myproj_project_options
  myproj_project_warnings
  PUBLIC_INCLUDES
  ${lib2_INCLUDE_DIR22})

package_project(
  NAME
  myproj_main
  TARGETS
  main)
