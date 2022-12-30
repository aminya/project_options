cmake_minimum_required(VERSION 3.16...3.21)

# set a default CXX standard used by the external tools like clang-tidy, cppcheck, etc.
# You can later set fine-grained standards for each target using `target_compile_features`
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_C_STANDARD 99)

### Add project_options
# include(FetchContent)
# FetchContent_Declare(_project_options URL https://github.com/aminya/project_options/archive/refs/heads/main.zip)
# FetchContent_MakeAvailable(_project_options)
# include(${_project_options_SOURCE_DIR}/Index.cmake)
include(../src/Index.cmake)

# opt-in cross-compiling
option(ENABLE_CROSS_COMPILING "Detect cross compiler and setup toolchain" OFF)
if(ENABLE_CROSS_COMPILING)
  enable_cross_compiler()
endif()
run_vcpkg()

# Set the project name to your project name, my project isn't very descriptive
project(
  myapp
  VERSION 0.1.0
  LANGUAGES C CXX)

project_options(
  ENABLE_CACHE
  # WARNINGS_AS_ERRORS
  ENABLE_CPPCHECK
  ENABLE_CLANG_TIDY
  # ENABLE_INCLUDE_WHAT_YOU_USE
)

find_package(magic_enum CONFIG REQUIRED)
find_package(Microsoft.GSL CONFIG REQUIRED)

add_executable(myapp)
target_sources(myapp PRIVATE main.cpp)
target_include_directories(myapp PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(myapp PRIVATE project_options project_warnings)
target_link_system_libraries(myapp PRIVATE magic_enum::magic_enum)
target_link_system_libraries(myapp PRIVATE Microsoft.GSL::GSL)

if(EMSCRIPTEN)
  set(CMAKE_EXECUTABLE_SUFFIX ".wasm")

  set_target_properties(myapp PROPERTIES COMPILE_FLAGS "-Os -s SIDE_MODULE=1 ")
  set_target_properties(myapp PROPERTIES LINK_FLAGS "-Os -s WASM=1 -s SIDE_MODULE=1 -s STANDALONE_WASM --no-entry")
endif()
