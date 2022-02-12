# project_options

A general-purpose CMake library that makes using CMake easier

## Usage

Here is a full example:

```cmake
cmake_minimum_required(VERSION 3.16)

# uncomment to set a default CXX standard for the external tools like clang-tidy and cppcheck
# and the targets that do not specify a standard.
# If not set, the latest supported standard for your compiler is used
# You can later set fine-grained standards for each target using `target_compile_features`
# set(CMAKE_CXX_STANDARD 17)

# Add project_options v0.16.0
# https://github.com/cpp-best-practices/project_options
include(FetchContent)
FetchContent_Declare(_project_options URL https://github.com/cpp-best-practices/project_options/archive/refs/tags/v0.16.0.zip)
FetchContent_MakeAvailable(_project_options)
include(${_project_options_SOURCE_DIR}/Index.cmake)

# uncomment to enable vcpkg:
# # Setup vcpkg - should be called before defining project()
# run_vcpkg()

# Set the project name and language
project(myproject LANGUAGES CXX C)

# Initialize project_options variable related to this project
# This overwrites `project_options` and sets `project_warnings`
# uncomment the options to enable them:
project_options(
      ENABLE_CACHE
      ENABLE_CPPCHECK
      ENABLE_CLANG_TIDY
      # ENABLE_CONAN
      # ENABLE_IPO
      # ENABLE_DOXYGEN
      # ENABLE_COVERAGE
      # WARNINGS_AS_ERRORS
      # ENABLE_SANITIZER_ADDRESS
      # ENABLE_SANITIZER_LEAK
      # ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
      # ENABLE_SANITIZER_THREAD
      # ENABLE_SANITIZER_MEMORY
      # ENABLE_INCLUDE_WHAT_YOU_USE
      # ENABLE_PCH
      # PCH_HEADERS
      # ENABLE_USER_LINKER
      # ENABLE_BUILD_WITH_TIME_TRACE
      # ENABLE_UNITY
      # CONAN_OPTIONS
)
```

```cmake
# add your executables, libraries, etc. here:

add_executable(myprogram main.cpp)
target_compile_features(myprogram INTERFACE cxx_std_17)
target_link_libraries(myprogram PRIVATE project_options project_warnings) # connect project_options to myprogram

# find and link dependencies (assuming you have enabled vcpkg or Conan):
find_package(fmt REQUIRED)
target_link_system_libraries(
  main
  PRIVATE
  fmt::fmt
)
```

## `project_options` function

It accepts the following named flags:

- `ENABLE_CACHE`: Enable cache if available
- `ENABLE_CPPCHECK`: Enable static analysis with Cppcheck
- `ENABLE_CLANG_TIDY`: Enable static analysis with clang-tidy
- `ENABLE_CONAN`: Use Conan for dependency management
- `ENABLE_IPO`: Enable Interprocedural Optimization (Link Time Optimization, LTO) in the release build
- `ENABLE_COVERAGE`: Enable coverage reporting for gcc/clang
- `ENABLE_DOXYGEN`: Enable Doxygen doc builds of source
- `WARNINGS_AS_ERRORS`: Treat compiler and static code analyzer warnings as errors. This also effects cmake warnings related to those.
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

- `DOXYGEN_THEME`: the name of the Doxygen theme to use. Supported themes: `awesome-sidebar` (default), `awesome` and `original`.
- `PCH_HEADERS`: the list of the headers to precompile
- `MSVC_WARNINGS`: Override the defaults for the MSVC warnings
- `CLANG_WARNINGS`: Override the defaults for the CLANG warnings
- `GCC_WARNINGS`: Override the defaults for the GCC warnings
- `CUDA_WARNINGS`: Override the defaults for the CUDA warnings
- `CPPCHECK_WARNINGS`: Override the defaults for the options passed to CPPCHECK
- `CONAN_OPTIONS`: Extra Conan options

## `run_vcpkg` function

Named Option:

- `ENABLE_VCPKG_UPDATE`: (Disabled by default). If enabled, the vcpkg registry is updated before building (using `git pull`). As a result, if some of your vcpkg dependencies have been updated in the registry, they will be rebuilt.

Named String:

- `VCPKG_DIR`: (Defaults to `~/vcpkg`). You can provide the vcpkg installation directory using this optional parameter.
  If the directory does not exist, it will automatically install vcpkg in this directory.

- `VCPKG_URL`: (Defaults to `https://github.com/microsoft/vcpkg.git`). This option allows setting the URL of the vcpkg repository. By default, the official vcpkg repository is used.

## `target_link_system_libraries` function

A function that accepts the same arguments as `target_link_libraries`. It has the following features:

- The include directories of the library are included as `SYSTEM` to suppress their warnings. This helps in enabling `WARNINGS_AS_ERRORS` for your own source code.
- For installation of the package, the includes are considered to be at `${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}`.

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

<details>
<summary> 👉 Click to show the example:</summary>

```cmake
cmake_minimum_required(VERSION 3.16)

# uncomment to set a default CXX standard for the external tools like clang-tidy and cppcheck
# and the targets that do not specify a standard.
# If not set, the latest supported standard for your compiler is used
# You can later set fine-grained standards for each target using `target_compile_features`
# set(CMAKE_CXX_STANDARD 17)

# Add project_options v0.16.0
# https://github.com/cpp-best-practices/project_options
include(FetchContent)
FetchContent_Declare(_project_options URL https://github.com/cpp-best-practices/project_options/archive/refs/tags/v0.16.0.zip)
FetchContent_MakeAvailable(_project_options)
include(${_project_options_SOURCE_DIR}/Index.cmake)

 # ❗ Add dynamic CMake options
include(${_project_options_SOURCE_DIR}/src/DynamicOptions.cmake)

# uncomment to enable vcpkg:
# # Setup vcpkg - should be called before defining project()
# run_vcpkg()

# Set the project name and language
project(myproject LANGUAGES CXX C)

# Set PCH to be on by default for all non-Developer Mode Builds
# (this is just intended as an example of what is possible)
set(ENABLE_PCH_USER_DEFAULT ON)

# Initialize project_options variable related to this project
# This overwrites `project_options` and sets `project_warnings`
# uncomment the options to enable them:
dynamic_project_options(
  # set PCH headers you want enabled. Format can be slow, so this might be helpful
  PCH_HEADERS <vector> <string> <fmt/format.h>
)
```

```cmake
# add your executables, libraries, etc. here:

add_executable(myprogram main.cpp)
target_compile_features(myprogram INTERFACE cxx_std_17)
target_link_libraries(myprogram PRIVATE project_options project_warnings) # connect project_options to myprogram

# find and link dependencies (assuming you have enabled vcpkg or Conan):
find_package(fmt REQUIRED)
target_link_system_libraries(
  main
  PRIVATE
  fmt::fmt
)
```

</details>
