# `project_options` function

## Example

See `project_options()` in action in [this template repository](https://github.com/aminya/cpp_vcpkg_project). [cpp_vcpkg_project](https://github.com/aminya/cpp_vcpkg_project) has prepared all the best practices for a production-ready C++ project.

Here is a full example:

```cmake
cmake_minimum_required(VERSION 3.20)

# set a default CXX standard for the tools and targets that do not specify them.
# If commented, the latest supported standard for your compiler is automatically set.
# set(CMAKE_CXX_STANDARD 20)

# Add project_options v0.26.3
# https://github.com/aminya/project_options
# Change the version in the following URL to update the package (watch the releases of the repository for future updates)
include(FetchContent)
FetchContent_Declare(_project_options URL https://github.com/aminya/project_options/archive/refs/tags/v0.26.3.zip)
FetchContent_MakeAvailable(_project_options)
include(${_project_options_SOURCE_DIR}/Index.cmake)

# install vcpkg dependencies: - should be called before defining project()
run_vcpkg()

# Set the project name and language
project(myproject LANGUAGES CXX C)

# Build Features
option(FEATURE_TESTS "Enable the tests" OFF)
if(FEATURE_TESTS)
  list(APPEND VCPKG_MANIFEST_FEATURES "tests")
endif()

option(FEATURE_DOCS "Enable the docs" OFF)

# Enable sanitizers and static analyzers when running the tests
set(ENABLE_CLANG_TIDY OFF)
set(ENABLE_CPPCHECK OFF)
set(ENABLE_SANITIZER_ADDRESS OFF)
set(ENABLE_SANITIZER_UNDEFINED_BEHAVIOR OFF)
set(ENABLE_COVERAGE OFF)

if(FEATURE_TESTS)
  set(ENABLE_CLANG_TIDY "ENABLE_CLANG_TIDY")
  set(ENABLE_CPPCHECK "ENABLE_CPPCHECK")
  set(ENABLE_COVERAGE "ENABLE_COVERAGE")

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
endif()

if(FEATURE_DOCS)
  set(ENABLE_DOXYGEN "ENABLE_DOXYGEN")
else()
  set(ENABLE_DOXYGEN OFF)
endif()

# Initialize project_options variable related to this project
# This overwrites `project_options` and sets `project_warnings`
# uncomment to enable the options. Some of them accept one or more inputs:
project_options(
      ENABLE_CACHE
      ${ENABLE_CPPCHECK}
      ${ENABLE_CLANG_TIDY}
      ENABLE_VS_ANALYSIS
      # ENABLE_CONAN
      # ENABLE_INTERPROCEDURAL_OPTIMIZATION
      # ENABLE_NATIVE_OPTIMIZATION
      ${ENABLE_DOXYGEN}
      ${ENABLE_COVERAGE}
      ${ENABLE_SANITIZER_ADDRESS}
      ${ENABLE_SANITIZER_UNDEFINED_BEHAVIOR}
      # ENABLE_SANITIZER_THREAD
      # ENABLE_SANITIZER_MEMORY
      # ENABLE_PCH
      # PCH_HEADERS
      # WARNINGS_AS_ERRORS
      # ENABLE_INCLUDE_WHAT_YOU_USE
      # ENABLE_BUILD_WITH_TIME_TRACE
      # ENABLE_UNITY
      # LINKER "lld"
      # CONAN_PROFILE ${profile_path}  # passes a profile to conan: see https://docs.conan.io/en/latest/reference/profiles.html
)
```

Then add the executables or libraries to the project:

[An executable](https://github.com/aminya/cpp_vcpkg_project/tree/main/my_exe):

```cmake
add_executable(main main.cpp)
target_link_libraries(main PRIVATE project_options project_warnings) # link project_options/warnings

# Find dependencies:
set(DEPENDENCIES_CONFIGURED fmt Eigen3)

foreach(DEPENDENCY ${DEPENDENCIES_CONFIGURED})
  find_package(${DEPENDENCY} CONFIG REQUIRED)
endforeach()

# Link dependencies
target_link_system_libraries(
  main
  PRIVATE
  fmt::fmt
  Eigen3::Eigen
)

# Package the project
package_project(TARGETS main)
```

[A header-only library](https://github.com/aminya/cpp_vcpkg_project/tree/main/my_header_lib):

```cmake
add_library(my_header_lib INTERFACE)
target_link_libraries(my_header_lib INTERFACE project_options project_warnings) # link project_options/warnings

# Includes
set(INCLUDE_DIR "include") # must be relative paths
target_include_directories(my_header_lib INTERFACE "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${INCLUDE_DIR}>"
                                          "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>")

# Find dependencies:
set(DEPENDENCIES_CONFIGURED fmt Eigen3)

foreach(DEPENDENCY ${DEPENDENCIES_CONFIGURED})
  find_package(${DEPENDENCY} CONFIG REQUIRED)
endforeach()

# Link dependencies:
target_link_system_libraries(
  my_header_lib
  INTERFACE
  fmt::fmt
  Eigen3::Eigen
)

# Package the project
package_project(
  TARGETS my_header_lib project_options project_warnings
  INTERFACE_DEPENDENCIES_CONFIGURED ${DEPENDENCIES_CONFIGURED}
  INTERFACE_INCLUDES ${INCLUDE_DIR}
)
```

[A library with separate header and source files](https://github.com/aminya/cpp_vcpkg_project/tree/main/my_lib)

```cmake
add_library(my_lib "./src/my_lib/lib.cpp")
target_link_libraries(my_lib PRIVATE project_options project_warnings) # link project_options/warnings

# Includes
set(INCLUDE_DIR "include") # must be relative paths
target_include_directories(my_lib PUBLIC "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${INCLUDE_DIR}>"
                                         "$<INSTALL_INTERFACE:./${CMAKE_INSTALL_INCLUDEDIR}>")

# Find dependencies:
set(DEPENDENCIES_CONFIGURED fmt Eigen3)

foreach(DEPENDENCY ${DEPENDENCIES_CONFIGURED})
  find_package(${DEPENDENCY} CONFIG REQUIRED)
endforeach()

# Link dependencies:
target_link_system_libraries(
  my_lib
  PRIVATE
  fmt::fmt
  Eigen3::Eigen
)

# Package the project
package_project(
  TARGETS my_lib
  PUBLIC_INCLUDES ${INCLUDE_DIR}
)
```

## API

`project_options` function accepts the following named flags:

- `ENABLE_CACHE`: Enable cache if available
- `ENABLE_CPPCHECK`: Enable static analysis with Cppcheck
- `ENABLE_CLANG_TIDY`: Enable static analysis with clang-tidy
- `ENABLE_VS_ANALYSIS`: Enable Visual Studio IDE code analysis if the generator is Visual Studio.
- `ENABLE_CONAN`: Use Conan for dependency management
- `ENABLE_INTERPROCEDURAL_OPTIMIZATION`: Enable Interprocedural Optimization (Link Time Optimization, LTO) in the release build
- `ENABLE_NATIVE_OPTIMIZATION`: Enable the optimizations specific to the build machine (e.g. SSE4_1, AVX2, etc.).
- `ENABLE_COVERAGE`: Enable coverage reporting for gcc/clang
- `ENABLE_DOXYGEN`: Enable Doxygen documentation. The added `doxygen-docs` target can be built via `cmake --build ./build --target doxygen-docs`.
- `WARNINGS_AS_ERRORS`: Treat compiler and static code analyzer warnings as errors. This also affects CMake warnings related to those.
- `ENABLE_SANITIZER_ADDRESS`: Enable address sanitizer
- `ENABLE_SANITIZER_LEAK`: Enable leak sanitizer
- `ENABLE_SANITIZER_UNDEFINED_BEHAVIOR`: Enable undefined behavior sanitizer
- `ENABLE_SANITIZER_THREAD`: Enable thread sanitizer
- `ENABLE_SANITIZER_MEMORY`: Enable memory sanitizer
- `ENABLE_PCH`: Enable Precompiled Headers
- `ENABLE_INCLUDE_WHAT_YOU_USE`: Enable static analysis with include-what-you-use
- `ENABLE_BUILD_WITH_TIME_TRACE`: Enable `-ftime-trace` to generate time tracing `.json` files on clang
- `ENABLE_UNITY`: Enable Unity builds of projects

It gets the following named parameters that can have different values in front of them:

- `PREFIX`: the optional prefix that is used to define `${PREFIX}_project_options` and `${PREFIX}_project_warnings` targets when the function is used in a multi-project fashion.
- `DOXYGEN_THEME`: the name of the Doxygen theme to use. Supported themes:
  - `awesome-sidebar` (default)
  - `awesome`
  - `original`
  - Alternatively you can supply a list of css files to be added to [DOXYGEN_HTML_EXTRA_STYLESHEET](https://www.doxygen.nl/manual/config.html#cfg_html_extra_stylesheet)
- `LINKER`: choose a specific linker (e.g. lld, gold, bfd). If set to OFF (default), the linker is automatically chosen.
- `PCH_HEADERS`: the list of the headers to precompile
- `MSVC_WARNINGS`: Override the defaults for the MSVC warnings
- `CLANG_WARNINGS`: Override the defaults for the CLANG warnings
- `GCC_WARNINGS`: Override the defaults for the GCC warnings
- `CUDA_WARNINGS`: Override the defaults for the CUDA warnings
- `CPPCHECK_OPTIONS`: Override the defaults for the options passed to cppcheck
- `VS_ANALYSIS_RULESET`: Override the defaults for the code analysis rule set in Visual Studio.
- `CONAN_OPTIONS`: Extra Conan options
