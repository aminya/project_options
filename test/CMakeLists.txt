cmake_minimum_required(VERSION 3.16...3.21)

project(
  escape
  VERSION 0.1.0
  LANGUAGES CXX)

### Add ProjectOptions
# include(FetchContent)
# FetchContent_Declare(ProjectOptions URL https://github.com/aminya/ProjectOptions/archive/refs/heads/main.zip)
# FetchContent_MakeAvailable(ProjectOptions)
# include(${ProjectOptions_SOURCE_DIR}/Index.cmake)
include(../src/Index.cmake)

add_library(escape INTERFACE)

# Initialize ProjectOptions
# uncomment the options to enable them
ProjectOptions(
  ENABLE_CACHE
  # ENABLE_CONAN
  # WARNINGS_AS_ERRORS
  # ENABLE_CPPCHECK
  ENABLE_CLANG_TIDY
  # ENABLE_INCLUDE_WHAT_YOU_USE
  ENABLE_COVERAGE
  # ENABLE_PCH
  # ENABLE_DOXYGEN
  # ENABLE_IPO
  # ENABLE_USER_LINKER
  ENABLE_BUILD_WITH_TIME_TRACE
  # ENABLE_UNITY
  # ENABLE_SANITIZER_ADDRESS
  # ENABLE_SANITIZER_LEAK
  # ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
  # ENABLE_SANITIZER_THREAD
  # ENABLE_SANITIZER_MEMORY
)

# NOTE: project_options and project_warnings are defined inside ProjectOptions
target_compile_features(project_options INTERFACE cxx_std_17)
target_link_libraries(escape INTERFACE project_options project_warnings)

# add src, tests, etc here:
add_executable(test_escape escape.cpp)
target_link_libraries(test_escape PRIVATE escape)

enable_testing()
add_test(NAME test_escape COMMAND test_escape)
