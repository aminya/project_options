# ProjectOptions

A general-purpose CMake library that makes using CMake easier

_NOTE_: It is planned to transfer this repository to [cpp-best-practices organization](https://github.com/cpp-best-practices/cpp_starter_project/issues/125). Stay tuned for that.

## Usage

```cmake
cmake_minimum_required(VERSION 3.16)

# Add ProjectOptions v0.2.0
# https://github.com/aminya/ProjectOptions
include(FetchContent)
FetchContent_Declare(projectoptions URL https://github.com/aminya/ProjectOptions/archive/refs/tags/v0.2.0.zip)
FetchContent_MakeAvailable(projectoptions)

# uncomment to enable vcpkg:
# # Setup vcpkg (should be before calling project)
# include(${projectoptions_SOURCE_DIR}/src/Vcpkg.cmake)
# run_vcpkg()

# Set the project name to your project name, my_project isn't very descriptive
project(myproject LANGUAGES CXX)

# Initialize ProjectOptions
include(${projectoptions_SOURCE_DIR}/Index.cmake)
# uncomment the options to enable them:
ProjectOptions(
      ENABLE_CACHE
      # ENABLE_CONAN
      # WARNINGS_AS_ERRORS
      # ENABLE_CPPCHECK
      # ENABLE_CLANG_TIDY
      # ENABLE_INCLUDE_WHAT_YOU_USE
      # ENABLE_COVERAGE
      # ENABLE_PCH
      # ENABLE_DOXYGEN
      # ENABLE_IPO
      # ENABLE_USER_LINKER
      # ENABLE_BUILD_WITH_TIME_TRACE
      # ENABLE_UNITY
      # ENABLE_SANITIZER_ADDRESS
      # ENABLE_SANITIZER_LEAK
      # ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
      # ENABLE_SANITIZER_THREAD
      # ENABLE_SANITIZER_MEMORY
      # CONAN_OPTIONS
)

# add the C++ standard
target_compile_features(project_options INTERFACE cxx_std_17)


# add your executables, libraries, etc. here:

add_executable(myprogram main.cpp)
target_link_libraries(myprogram PRIVATE project_options project_warnings) # connect ProjectOptions to myprogram

```

## `ProjectOptions` parameters

- `WARNINGS_AS_ERRORS`: Treat compiler warnings as errors
- `ENABLE_CPPCHECK`: Enable static analysis with Cppcheck
- `ENABLE_CLANG_TIDY`: Enable static analysis with clang-tidy
- `ENABLE_INCLUDE_WHAT_YOU_USE`: Enable static analysis with include-what-you-use
- `ENABLE_COVERAGE`: Enable coverage reporting for gcc/clang
- `ENABLE_CACHE`: Enable cache if available
- `ENABLE_PCH`: Enable Precompiled Headers
- `ENABLE_CONAN`: Use Conan for dependency management
- `ENABLE_DOXYGEN`: Enable Doxygen doc builds of source
- `ENABLE_IPO`: Enable Interprocedural Optimization, aka Link Time Optimization (LTO)
- `ENABLE_USER_LINKER`: Enable a specific linker if available
- `ENABLE_BUILD_WITH_TIME_TRACE`: Enable `-ftime-trace` to generate time tracing `.json` files on clang
- `ENABLE_UNITY`: Enable Unity builds of projects
- `ENABLE_SANITIZER_ADDRESS`: Enable address sanitizer
- `ENABLE_SANITIZER_LEAK`: Enable leak sanitizer
- `ENABLE_SANITIZER_UNDEFINED_BEHAVIOR`: Enable undefined behavior sanitizer
- `ENABLE_SANITIZER_THREAD`: Enable thread sanitizer
- `ENABLE_SANITIZER_MEMORY`: Enable memory sanitizer
- `MSVC_WARNINGS`: Override the defaults for the MSVC warnings
- `CLANG_WARNINGS`: Override the defaults for the CLANG warnings
- `GCC_WARNINGS`: Override the defaults for the GCC warnings
- `CONAN_OPTIONS`: Extra Conan options

## Using global CMake options (⚠️ **not recommended**)

⚠️ It is highly recommended to keep the build declarative and reproducible by using the function arguments as explained above.

However, if you still want to change the CMake options on the fly (e.g. to enable sanitizers inside CI), you can include the `GlobalOptions.cmake`, which adds global options for the arguments of `ProjectOptions` function.

```cmake
cmake_minimum_required(VERSION 3.16)

# Add ProjectOptions v0.2.0
# https://github.com/aminya/ProjectOptions
include(FetchContent)
FetchContent_Declare(projectoptions URL https://github.com/aminya/ProjectOptions/archive/refs/tags/v0.2.0.zip)
FetchContent_MakeAvailable(projectoptions)

# uncomment to enable vcpkg:
# # Setup vcpkg (should be before calling project)
# include(${projectoptions_SOURCE_DIR}/src/Vcpkg.cmake)
# run_vcpkg()

# Set the project name to your project name, my_project isn't very descriptive
project(myproject LANGUAGES CXX)

# Initialize ProjectOptions
include(${projectoptions_SOURCE_DIR}/Index.cmake)
include(${ProjectOptions_SOURCE_DIR}/src/GlobalOptions.cmake) # ❗ Add global CMake options
# uncomment the options to enable them:
ProjectOptions(
      ENABLE_CACHE
      ENABLE_CONAN
      # WARNINGS_AS_ERRORS
      # ENABLE_CPPCHECK
      # ENABLE_CLANG_TIDY
      # ENABLE_INCLUDE_WHAT_YOU_USE
      # ENABLE_COVERAGE
      # ENABLE_PCH
      # ENABLE_DOXYGEN
      # ENABLE_IPO
      # ENABLE_USER_LINKER
      # ENABLE_BUILD_WITH_TIME_TRACE
      # ENABLE_UNITY
      ${ENABLE_SANITIZER_ADDRESS}   # ❗ Now, the address sanitizer is enabled through CMake options
      # ENABLE_SANITIZER_LEAK
      # ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
      # ENABLE_SANITIZER_THREAD
      # ENABLE_SANITIZER_MEMORY
)

# add the C++ standard
target_compile_features(project_options INTERFACE cxx_std_17)

# add your executables, libraries, etc. here:

add_executable(myprogram main.cpp)
target_link_libraries(myprogram PRIVATE project_options project_warnings) # connect ProjectOptions to myprogram
```
