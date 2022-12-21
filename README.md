# project_options

A general-purpose CMake library that provides functions that improve the CMake experience following the best practices.

## Features

- `project_options`:
  - compiler warnings,
  - compiler optimizations (intraprocedural, native),
  - caching (ccache, sccache),
  - sanitizers,
  - static code analyzers (clang-tidy, cppcheck, visual studio, include-what-you-use),
  - document generation (doxygen),
  - test coverage analysis,
  - precompiled headers,
  - build time measurement,
  - unity builds
  - using custom linkers (e.g. lld)
- `package_project`: automatic packaging/installation of the project for seamless usage via find_package/target_link through CMake's FetchContent, vcpkg, etc.
- `run_vcpkg`: automatic installation of vcpkg and the project dependencies
- `ENABLE_CONAN` in `project_options`: automatic installation of Conan and the project dependencies
- `dynamic_project_options`: a wrapper around `project_options` to change the options on the fly dynamically
- `target_link_system_libraries` and `target_include_system_directories`: linking/including external dependencies/headers without warnings
- `target_link_cuda`: linking Cuda to a target

[![ci](https://github.com/aminya/project_options/actions/workflows/ci.yml/badge.svg)](https://github.com/aminya/project_options/actions/workflows/ci.yml)

## Usage

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
      # ENABLE_USER_LINKER
      # ENABLE_BUILD_WITH_TIME_TRACE
      # ENABLE_UNITY
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

## `project_options` function

It accepts the following named flags:

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
- `ENABLE_USER_LINKER`: Enable a specific linker if available
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

## `run_vcpkg` function

```cmake
run_vcpkg()
```

Or by specifying the options

```cmake
run_vcpkg(
    VCPKG_URL "https://github.com/microsoft/vcpkg.git"
    VCPKG_REV "33c8f025390f8682811629b6830d2d66ecedcaa5"
    ENABLE_VCPKG_UPDATE
)
```

Named Option:

- `ENABLE_VCPKG_UPDATE`: (Disabled by default). If enabled, the vcpkg registry is updated before building (using `git pull`).

  If `VCPKG_REV` is set to a specific commit sha, no rebuilds are triggered.
  If `VCPKG_REV` is not specified or is a branch, enabling `ENABLE_VCPKG_UPDATE` will rebuild your updated vcpkg dependencies.

Named String:

- `VCPKG_DIR`: (Defaults to `~/vcpkg`). You can provide the vcpkg installation directory using this optional parameter.
  If the directory does not exist, it will automatically install vcpkg in this directory.

- `VCPKG_URL`: (Defaults to `https://github.com/microsoft/vcpkg.git`). This option allows setting the URL of the vcpkg repository. By default, the official vcpkg repository is used.

- `VCPKG_REV`: This option allows checking out a specific branch name or a commit sha.
If `VCPKG_REV` is set to a specific commit sha, the builds will become reproducible because that exact commit is always used for the builds. To make sure that this commit sha is pulled, enable `ENABLE_VCPKG_UPDATE`

## `target_link_system_libraries` function

A function that accepts the same arguments as `target_link_libraries`. It has the following features:

- The include directories of the library are included as `SYSTEM` to suppress their warnings. This helps in enabling `WARNINGS_AS_ERRORS` for your own source code.
- For installation of the package, the includes are considered to be at `${CMAKE_INSTALL_INCLUDEDIR}`.

## `target_include_system_directories` function

A function that accepts the same arguments as `target_include_directories`. It has the above mentioned features of `target_link_system_libraries`

## `target_link_cuda` function

A function that links Cuda to the given target.

```cmake
add_executable(main_cuda main.cu)
target_compile_features(main_cuda PRIVATE cxx_std_17)
target_link_libraries(main_cuda PRIVATE project_options project_warnings)
target_link_cuda(main_cuda)
```

## `package_project` function

A function that packages the project for external usage (e.g. from vcpkg, Conan, etc).

The following arguments specify the package:

- `TARGETS`: the targets you want to package. It is recursively found for the current folder if not specified

- `INTERFACE_INCLUDES` or `PUBLIC_INCLUDES`: a list of interface/public include directories or files.

  <sub>NOTE: The given include directories are directly installed to the install destination. To have an `include` folder in the install destination with the content of your include directory, name your directory `include`.</sub>

- `INTERFACE_DEPENDENCIES_CONFIGURED` or `PUBLIC_DEPENDENCIES_CONFIGURED`: the names of the interface/public dependencies that are found using `CONFIG`.

- `INTERFACE_DEPENDENCIES` or `PUBLIC_DEPENDENCIES`: the interface/public dependencies that will be found by any means using `find_dependency`. The arguments must be specified within quotes (e.g.`"<dependency> 1.0.0 EXACT"` or `"<dependency> CONFIG"`).

- `PRIVATE_DEPENDENCIES_CONFIGURED`: the names of the PRIVATE dependencies found using `CONFIG`. Only included when `BUILD_SHARED_LIBS` is `OFF`.

- `PRIVATE_DEPENDENCIES`: the PRIVATE dependencies found by any means using `find_dependency`. Only included when `BUILD_SHARED_LIBS` is `OFF`

Other arguments that are automatically found and manually specifying them is not recommended:

- `NAME`: the name of the package. Defaults to `${PROJECT_NAME}`.

- `VERSION`: the version of the package. Defaults to `${PROJECT_VERSION}`.

- `COMPATIBILITY`: the compatibility version of the package. Defaults to `SameMajorVersion`.

- `CONFIG_EXPORT_DESTINATION`: the destination for exporting the configuration files. Defaults to `${CMAKE_BINARY_DIR}/${NAME}`

- `CONFIG_INSTALL_DESTINATION`: the destination for installation of the configuration files. Defaults to `${CMAKE_INSTALL_DATADIR}/${NAME}`

## Disabling static analysis for external targets

This function disables static analysis for the given target:

```cmake
target_disable_static_analysis(some_external_target)
```

There is also individual functions to disable a specific analysis for the target:

- `target_disable_cpp_check(target)`
- `target_disable_vs_analysis(target)`
- `target_disable_clang_tidy(target)`

## Changing the project_options dynamically

During the test and development, it can be useful to change options on the fly. For example, to enable sanitizers when running tests. You can include `DynamicOptions.cmake`, which imports the `dynamic_project_options` function.

`dynamic_project_options` provides a recommended set of defaults (all static analysis and runtime analysis enabled for platforms where that is possible) while also providing a high-level option `ENABLE_DEVELOPER_MODE` (defaulted to `ON`) which can be turned off for easy use by non-developers.

The goal of the `dynamic_project_options` is to give a safe and well-analyzed environment to the developer by default while simultaneously making it easy for a user of the project to compile while not having to worry about clang-tidy, sanitizers, cppcheck, etc.

The defaults presented to the user can be modified with

- `set(<featurename>_DEFAULT value)` - for user and developer builds
- `set(<featurename>_USER_DEFAULT value)` - for user builds
- `set(<featureoptionname>_DEVELOPER_DEFAULT value)` - for developer builds

If you need to fix a setting for the sake of a command-line configuration, you can use:

```shell
cmake -DOPT_<featurename>:BOOL=value
```

See `dynamic_project_options()` in action in [this template repository](https://github.com/aminya/cpp_boilerplate_project).

<details>
<summary> 👉 Click to show the example:</summary>

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

 # ❗ Add dynamic CMake options
include(${_project_options_SOURCE_DIR}/src/DynamicOptions.cmake)

# install vcpkg dependencies: - should be called before defining project()
# run_vcpkg()

# Set the project name and language
project(myproject LANGUAGES CXX C)

# Set PCH to be on by default for all non-Developer Mode Builds
set(ENABLE_PCH_USER_DEFAULT ON)

# enable Conan
set(ENABLE_CONAN_DEFAULT ON)

# Initialize project_options variable related to this project
# This overwrites `project_options` and sets `project_warnings`
# This also accepts the same arguments as `project_options`.
dynamic_project_options(
  # set the common headers you want to precompile
  PCH_HEADERS <vector> <string> <fmt/format.h> <Eigen/Dense>
)
```

Add your executables, etc., as described above.

</details>

# License

This project can be used under the terms of either the [MIT license](./LICENSE.txt) or the [Unlicense](./Unlicense.txt) depending on your choice (as you wish). Both are permissive open-source licenses that allow any usage, commercial or non-commercial, copying, distribution, publishing, modification, etc. Feel free to choose whichever is more suitable for you.
