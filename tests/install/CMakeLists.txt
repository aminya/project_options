cmake_minimum_required(VERSION 3.16...3.21)

### Add project_options
include(../../src/Index.cmake)

run_vcpkg()
run_conan()

project(anotherproj VERSION 0.1.0 LANGUAGES CXX C)

option(FEATURE_TESTS "Enable the tests" ON)
if(FEATURE_TESTS)
  # Enable sanitizers and static analyzers when running the tests
  check_sanitizers_support(
    ENABLE_SANITIZER_ADDRESS ENABLE_SANITIZER_UNDEFINED_BEHAVIOR ENABLE_SANITIZER_LEAK
    ENABLE_SANITIZER_THREAD ENABLE_SANITIZER_MEMORY
  )
endif()

set(ENABLE_INTERPROCEDURAL_OPTIMIZATION "ENABLE_INTERPROCEDURAL_OPTIMIZATION")
if(APPLE)
  detect_macos_version(apple_version)
  if(apple_version VERSION_GREATER_EQUAL 13)
    # workaround for linkage error as described in https://github.com/Homebrew/homebrew-core/issues/145991
    # although fixed, this problem still exists in github actions
    add_link_options(-Wl,-ld_classic)
    set(ENABLE_INTERPROCEDURAL_OPTIMIZATION "")
  endif()
endif()

# Initialize project_options
project_options(
  ENABLE_CACHE
  # WARNINGS_AS_ERRORS
  ENABLE_CPPCHECK
  ENABLE_CLANG_TIDY
  # ENABLE_INCLUDE_WHAT_YOU_USE
  # ENABLE_GCC_ANALYZER
  # ENABLE_COVERAGE
  # ENABLE_PCH
  # PCH_HEADERS <Eigen/Dense> <fmt/core.h> <vector> <utility> <string> <string_view>
  ENABLE_DOXYGEN
  DOXYGEN_THEME
  "${CMAKE_CURRENT_LIST_DIR}/css/my_custom_theme.css"
  "${CMAKE_CURRENT_LIST_DIR}/css/my_custom_theme_extra.css"
  ${ENABLE_INTERPROCEDURAL_OPTIMIZATION}
  # ENABLE_BUILD_WITH_TIME_TRACE
  # ENABLE_UNITY
  ${ENABLE_SANITIZER_ADDRESS}
  # ${ENABLE_SANITIZER_LEAK}
  ${ENABLE_SANITIZER_UNDEFINED_BEHAVIOR}
  # ${ENABLE_SANITIZER_THREAD}
  # ${ENABLE_SANITIZER_MEMORY}
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
add_executable_test(another_main no_arg)
