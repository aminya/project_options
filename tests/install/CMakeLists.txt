cmake_minimum_required(VERSION 3.16...3.21)

### Add project_options
include(../../src/Index.cmake)

run_vcpkg()

project(
  anotherproj
  VERSION 0.1.0
  LANGUAGES CXX C)

# Initialize project_options
project_options(
  ENABLE_CACHE
  ENABLE_CONAN
  # WARNINGS_AS_ERRORS
  ENABLE_CPPCHECK
  ENABLE_CLANG_TIDY
  # ENABLE_INCLUDE_WHAT_YOU_USE
  # ENABLE_COVERAGE
  # ENABLE_PCH
  # PCH_HEADERS <Eigen/Dense> <fmt/core.h> <vector> <utility> <string> <string_view>
  ENABLE_DOXYGEN
  DOXYGEN_THEME
  "${CMAKE_CURRENT_LIST_DIR}/css/my_custom_theme.css"
  "${CMAKE_CURRENT_LIST_DIR}/css/my_custom_theme_extra.css"
  ENABLE_INTERPROCEDURAL_OPTIMIZATION
  # ENABLE_BUILD_WITH_TIME_TRACE
  # ENABLE_UNITY
  # ENABLE_SANITIZER_ADDRESS
  # ENABLE_SANITIZER_LEAK
  # ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
  # ENABLE_SANITIZER_THREAD
  # ENABLE_SANITIZER_MEMORY
)

# add src, tests, etc here:
add_executable(another_main "./src/another_main.cpp")
target_link_libraries(another_main PRIVATE project_options project_warnings)

## dependencies
set(DEPENDENCIES_CONFIGURED myproj)

foreach(DEPENDENCY ${DEPENDENCIES_CONFIGURED})
  find_package(${DEPENDENCY} CONFIG REQUIRED)
endforeach()

target_link_libraries(another_main PRIVATE myproj::lib myproj::lib2)

# tests
enable_testing()
add_test(NAME another_main COMMAND another_main)
