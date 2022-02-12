cmake_minimum_required(VERSION 3.16...3.21)

# set a default CXX standard used by the external tools like clang-tidy, cppcheck, etc.
# You can later set fine-grained standards for each target using `target_compile_features`
set(CMAKE_CXX_STANDARD 20)

### Add project_options
# include(FetchContent)
# FetchContent_Declare(_project_options URL https://github.com/cpp-best-practices/project_options/archive/refs/heads/main.zip)
# FetchContent_MakeAvailable(_project_options)
# include(${_project_options_SOURCE_DIR}/Index.cmake)
include(../src/Index.cmake)

run_vcpkg()

project(
  myproj
  VERSION 0.2.0
  LANGUAGES CXX C)

# Initialize project_options
# uncomment the options to enable them
project_options(
  ENABLE_CACHE
  # ENABLE_CONAN
  # WARNINGS_AS_ERRORS
  ENABLE_CPPCHECK
  ENABLE_CLANG_TIDY
  # ENABLE_INCLUDE_WHAT_YOU_USE
  # ENABLE_COVERAGE
  # ENABLE_PCH
  # PCH_HEADERS <Eigen/Dense> <fmt/core.h> <vector> <utility> <string> <string_view>
  ENABLE_DOXYGEN
  # ENABLE_IPO
  # ENABLE_USER_LINKER
  # ENABLE_BUILD_WITH_TIME_TRACE
  # ENABLE_UNITY
  # ENABLE_SANITIZER_ADDRESS
  # ENABLE_SANITIZER_LEAK
  # ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
  # ENABLE_SANITIZER_THREAD
  # ENABLE_SANITIZER_MEMORY
  # CLANG_WARNINGS "-Weverything"
)
# NOTE: project_options and project_warnings are defined inside project_options

# add src, tests, etc here:
add_executable(main main.cpp)
target_link_libraries(main PRIVATE project_options project_warnings)

# dependencies
set(DEPENDENCIES_CONFIGURED fmt Eigen3)

foreach(DEPENDENCY ${DEPENDENCIES_CONFIGURED})
  find_package(${DEPENDENCY} CONFIG REQUIRED)
endforeach()

target_link_system_libraries(
  main
  PRIVATE
  fmt::fmt
  Eigen3::Eigen)

# tests
enable_testing()
add_test(NAME main COMMAND main)

add_library(lib INTERFACE)
set(INCLUDE_DIR "./include")
# TODO are these generator expressions needed? If so, refactor this to a function
target_include_directories(lib INTERFACE "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${INCLUDE_DIR}>"
                                         "$<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}>")
target_link_libraries(main INTERFACE project_options project_warnings)
target_link_system_libraries(
  lib
  INTERFACE
  fmt::fmt
  Eigen3::Eigen)

# package everything automatically
package_project(
  # NAME
  # myproj
  # TARGETS
  # main
  # lib
  # project_warnings
  # project_options
  PUBLIC_DEPENDENCIES_CONFIGURED
  ${DEPENDENCIES_CONFIGURED}
  PUBLIC_INCLUDES
  ${INCLUDE_DIR})

# package separately (for testing)
package_project(
  NAME
  myproj_lib
  TARGETS
  lib
  PUBLIC_DEPENDENCIES_CONFIGURED
  ${DEPENDENCIES_CONFIGURED}
  PUBLIC_INCLUDES
  ${INCLUDE_DIR})

package_project(
  NAME
  myproj_main
  TARGETS
  main)
