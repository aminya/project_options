# `dynamic_project_options`

During the test and development, it can be useful to change options on the fly. For example, to enable sanitizers when running tests. You can include `DynamicOptions.cmake`, which imports the `dynamic_project_options` function.

`dynamic_project_options` provides a dynamic set of defaults (all static analysis and runtime analysis enabled for platforms where that is possible) while also providing a high-level option `ENABLE_DEVELOPER_MODE` (defaulted to `ON`) which can be turned off for easy use by non-developers.

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

Here is an example of how to use `dynamic_project_options`:


```cmake
cmake_minimum_required(VERSION 3.20)

# set a default CXX standard for the tools and targets that do not specify them.
# If commented, the latest supported standard for your compiler is automatically set.
# set(CMAKE_CXX_STANDARD 20)

# Add project_options from https://github.com/aminya/project_options
# Change the version in the following URL to update the package (watch the releases of the repository for future updates)
include(FetchContent)
FetchContent_Declare(_project_options URL
  https://github.com/aminya/project_options/archive/refs/tags/v0.27.0.zip
)
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
