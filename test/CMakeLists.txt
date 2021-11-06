cmake_minimum_required(VERSION 3.16...3.21)

### Add ProjectOptions
# include(FetchContent)
# FetchContent_Declare(ProjectOptions URL https://github.com/aminya/ProjectOptions/archive/refs/heads/main.zip)
# FetchContent_MakeAvailable(ProjectOptions)
# include(${ProjectOptions_SOURCE_DIR}/Index.cmake)
include(../src/Index.cmake)

run_vcpkg()

project(
  main
  VERSION 0.2.0
  LANGUAGES CXX)

# Initialize ProjectOptions
# uncomment the options to enable them
ProjectOptions(
  ENABLE_CACHE
  # ENABLE_CONAN
  # WARNINGS_AS_ERRORS
  ENABLE_CPPCHECK
  # ENABLE_CLANG_TIDY
  # ENABLE_INCLUDE_WHAT_YOU_USE
  # ENABLE_COVERAGE
  # ENABLE_PCH
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
)
# NOTE: project_options and project_warnings are defined inside ProjectOptions

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
