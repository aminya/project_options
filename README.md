# cmakelib
 A general-purpose Cmake library that makes using Cmake easier

*NOTE*: It is planned to transfer this repository to [cpp-best-practices organization](https://github.com/cpp-best-practices/cpp_starter_project/issues/125). Stay tuned for that.

## Usage

```cmake
cmake_minimum_required(VERSION 3.15)

# Set the project name to your project name, my_project isn't very descriptive
project(myproject CXX)

# Add cmakelib
include(FetchContent)
FetchContent_Declare(cmakelib URL https://github.com/aminya/cmakelib/archive/refs/heads/main.zip)
FetchContent_MakeAvailable(cmakelib)
include(${cmakelib_SOURCE_DIR}/Index.cmake)

# Initialize cmakelib
# uncomment the options to enable them
cmakelib(
  # WARNINGS_AS_ERRORS
  ENABLE_CONAN
  # ENABLE_DOXYGEN
  ENABLE_CACHE
  # ENABLE_PCH
  # ENABLE_BUILD_WITH_TIME_TRACE
  # ENABLE_UNITY
  # ENABLE_USER_LINKER
)

# project_options is defined inside cmakelib
target_compile_features(project_options INTERFACE cxx_std_17)

# add src, tests, etc here:
```