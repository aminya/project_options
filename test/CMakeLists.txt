cmake_minimum_required(VERSION 3.16...3.21)

### Add ProjectOptions
# include(FetchContent)
# FetchContent_Declare(ProjectOptions URL https://github.com/aminya/ProjectOptions/archive/refs/heads/main.zip)
# FetchContent_MakeAvailable(ProjectOptions)
# include(${ProjectOptions_SOURCE_DIR}/Index.cmake)
include(../src/Vcpkg.cmake)
run_vcpkg()

project(
  escape
  VERSION 0.2.0
  LANGUAGES CXX)

# Initialize ProjectOptions
include(../src/Index.cmake)
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
  ENABLE_UNITY
  # ENABLE_SANITIZER_ADDRESS
  # ENABLE_SANITIZER_LEAK
  # ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
  # ENABLE_SANITIZER_THREAD
  # ENABLE_SANITIZER_MEMORY
)

# NOTE: project_options and project_warnings are defined inside ProjectOptions
target_compile_features(project_options INTERFACE cxx_std_17)

# add src, tests, etc here:
add_executable(escape escape.cpp)
target_link_libraries(escape PRIVATE project_options project_warnings)

find_package(fmt REQUIRED)
target_link_libraries(escape PRIVATE fmt::fmt)

enable_testing()
add_test(NAME escape COMMAND escape)
