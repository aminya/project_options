cmake_minimum_required(VERSION 3.16...3.21)

# set a default CXX standard used by the external tools like clang-tidy, cppcheck, etc.
# You can later set fine-grained standards for each target using `target_compile_features`
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_C_STANDARD 99)

### Add project_options
# include(FetchContent)
# FetchContent_Declare(_project_options URL https://github.com/aminya/project_options/archive/refs/heads/main.zip)
# FetchContent_MakeAvailable(_project_options)
# include(${_project_options_SOURCE_DIR}/Index.cmake)
include(../../src/Index.cmake)

# opt-in cross-compiling
if(ENABLE_BARE_METAL_CROSS_COMPILING)
  # my custom arm settings
  enable_cross_compiler(
    CC
    "arm-none-eabi-gcc"
    CXX
    "arm-none-eabi-g++"
    TARGET_ARCHITECTURE
    "arm"
    CROSS_ROOT
    "/usr/arm-none-eabi-gcc"
    CROSS_TRIPLET
    "arm-none-eabi")

  # some more custom compiler settings
  # -Wl,--gc-sections     Perform the dead code elimination.
  # --specs=nano.specs    Link with newlib-nano.
  # --specs=nosys.specs   No syscalls, provide empty implementations for the POSIX system calls.
  set(CMAKE_EXE_LINKER_FLAGS
      "-Wl,--gc-sections --specs=nano.specs --specs=nosys.specs -mthumb"
      CACHE INTERNAL "Linker options")
else()
  option(ENABLE_CROSS_COMPILING "Detect cross compiler and setup toolchain" OFF)
  if(ENABLE_CROSS_COMPILING)
    enable_cross_compiler()
  endif()
endif()

# Set the project name to your project name, my project isn't very descriptive
project(
  example
  VERSION 0.1.0
  LANGUAGES C CXX ASM)

set(ENABLE_CLANG_TIDY OFF)
set(ENABLE_CPPCHECK OFF)
set(ENABLE_SANITIZER_ADDRESS OFF)
set(ENABLE_SANITIZER_UNDEFINED_BEHAVIOR OFF)
set(ENABLE_COVERAGE OFF)
set(ENABLE_INCLUDE_WHAT_YOU_USE OFF)

option(ENABLE_CHECKING "Enable Static analyzer" OFF)
option(ENABLE_CHECKING_INCLUDE_WHAT_YOU_USE "Enable Static analyzer for include-what-you-use" OFF)
if(ENABLE_CHECKING)
  set(ENABLE_CLANG_TIDY "ENABLE_CLANG_TIDY")
  set(ENABLE_CPPCHECK "ENABLE_CPPCHECK")
  set(ENABLE_INCLUDE_WHAT_YOU_USE "ENABLE_INCLUDE_WHAT_YOU_USE")
endif()
if(ENABLE_CHECKING_INCLUDE_WHAT_YOU_USE)
  set(ENABLE_INCLUDE_WHAT_YOU_USE "ENABLE_INCLUDE_WHAT_YOU_USE")
endif()

#option(ENABLE_TESTING "Enable the tests" OFF)
option(DISABLE_SANITIZER "Disable Sanitizer" OFF)
if(ENABLE_TESTING)
  if(NOT DEFINED OPT_ENABLE_COVERAGE)
    set(ENABLE_COVERAGE "ENABLE_COVERAGE")
  endif()

  if(NOT DISABLE_SANITIZER)
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
endif()

if(ENABLE_CROSS_COMPILING)
  set(CLANG_TIDY_EXTRA_ARGUMENTS --extra-arg=--target=${CROSS_TRIPLET})
endif()
project_options(
  ENABLE_CACHE
  ${ENABLE_CPPCHECK}
  ${ENABLE_CLANG_TIDY}
  ${ENABLE_INCLUDE_WHAT_YOU_USE}
  ENABLE_VS_ANALYSIS
  ${ENABLE_COVERAGE}
  ${ENABLE_SANITIZER_ADDRESS}
  ${ENABLE_SANITIZER_UNDEFINED_BEHAVIOR}
  DISABLE_EXCEPTIONS
  DISABLE_RTTI
  # Note: PCH is disabled by default in developer mode because these headers become globally included and they can mask other errors
  PCH_HEADERS
  # This is a list of headers to pre-compile, here are some common ones
  <vector>
  <string>
  <unordered_map>
  <utility>
  <array>
  <algorithm>
  <concepts>
  CLANG_TIDY_EXTRA_ARGUMENTS
  ${CLANG_TIDY_EXTRA_ARGUMENTS}
  CPPCHECK_OPTIONS
  --enable=style,performance,warning,portability
  --inline-suppr
  # We cannot act on a bug/missing feature of cppcheck
  --suppress=cppcheckError
  --suppress=internalAstError
  # if a file does not have an internalAstError, we get an unmatchedSuppression error
  --suppress=unmatchedSuppression
  --suppress=passedByValue
  --suppress=syntaxError
  --inconclusive)

#add_executable(example)
#target_sources(example PRIVATE main.cpp)
#target_include_directories(example PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
#target_link_libraries(example PRIVATE project_options project_warnings)
#FIXME: linking with c++ (libs) ... /libstdc++.a(cxx11-ios_failure.o): in function `(anonymous namespace)::__io_category_instance()':

add_executable(example_c)
target_sources(example_c PRIVATE main.c)
target_include_directories(example_c PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(example_c PRIVATE project_options project_warnings)

if(ENABLE_BARE_METAL_CROSS_COMPILING OR ENABLE_CROSS_COMPILING)
  #target_link_options(example PRIVATE -Wl,--start-group -lgcc -lc -lstdc++ -lm -lrdimon -Wl,--end-group)

  # fix: ...arm-none-eabi/lib/libg.a(lib_a-exit.o): in function `exit':
  target_link_options(
    example_c
    PRIVATE
    -Wl,--start-group
    -lgcc
    -lc
    -lm
    -Wl,--end-group)

  # custom raspberry pi 3 options
  target_compile_options(project_options INTERFACE -march=armv8-a -mfpu=neon-fp-armv8 -mthumb)
endif()
