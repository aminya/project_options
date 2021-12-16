cmake_minimum_required(VERSION 3.16...3.21)

# set a default CXX standard used by the external tools like clang-tidy, cppcheck, etc.
# You can later set fine-grained standards for each target using `target_compile_features`
set(CMAKE_CXX_STANDARD 17)

### Add project_options
# include(FetchContent)
# FetchContent_Declare(_project_options URL https://github.com/cpp-best-practices/project_options/archive/refs/heads/main.zip)
# FetchContent_MakeAvailable(_project_options)
# include(${_project_options_SOURCE_DIR}/Index.cmake)
include(../src/Index.cmake)

run_vcpkg()

project(
  main
  VERSION 0.2.0
  LANGUAGES CXX)

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
  # ENABLE_DOXYGEN
  # ENABLE_IPO
  # ENABLE_USER_LINKER
  # ENABLE_BUILD_WITH_TIME_TRACE
  ENABLE_UNITY
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
target_compile_features(main INTERFACE cxx_std_17)
target_link_libraries(main PRIVATE project_options project_warnings)

# dependencies
find_package(fmt REQUIRED)
find_package(Eigen3 CONFIG REQUIRED)
target_link_system_libraries(
  main
  PRIVATE
  fmt::fmt
  Eigen3::Eigen
)

# tests
enable_testing()
add_test(NAME main COMMAND main)
