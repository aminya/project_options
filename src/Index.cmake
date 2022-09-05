if(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.18.0")
  cmake_minimum_required(VERSION 3.18)
else()
  cmake_minimum_required(VERSION 3.16)
  message(
    WARNING
      "Consider upgrading CMake to the latest version. CMake ${CMAKE_VERSION} might fail in the linking stage because of missing references."
  )
endif()

include_guard()

set(ProjectOptions_SRC_DIR
    ${CMAKE_CURRENT_LIST_DIR}
    CACHE FILEPATH "")

# include the files to allow calling individual functions (including the files does not run any code.)
include("${ProjectOptions_SRC_DIR}/Common.cmake")
include("${ProjectOptions_SRC_DIR}/Utilities.cmake")
include("${ProjectOptions_SRC_DIR}/Vcpkg.cmake")
include("${ProjectOptions_SRC_DIR}/SystemLink.cmake")
include("${ProjectOptions_SRC_DIR}/Cuda.cmake")
include("${ProjectOptions_SRC_DIR}/PackageProject.cmake")
include("${ProjectOptions_SRC_DIR}/Optimization.cmake")
include("${ProjectOptions_SRC_DIR}/Cache.cmake")
include("${ProjectOptions_SRC_DIR}/Linker.cmake")
include("${ProjectOptions_SRC_DIR}/CompilerWarnings.cmake")
include("${ProjectOptions_SRC_DIR}/Tests.cmake")
include("${ProjectOptions_SRC_DIR}/Sanitizers.cmake")
include("${ProjectOptions_SRC_DIR}/Doxygen.cmake")
include("${ProjectOptions_SRC_DIR}/StaticAnalyzers.cmake")
include("${ProjectOptions_SRC_DIR}/VCEnvironment.cmake")
include("${ProjectOptions_SRC_DIR}/MinGW.cmake")
include("${ProjectOptions_SRC_DIR}/DetectCompiler.cmake")

# Include msvc toolchain on windows if the generator is not visual studio. Should be called before run_vcpkg and run_conan to be effective
msvc_toolchain()

include("${ProjectOptions_SRC_DIR}/Conan.cmake")
include("${ProjectOptions_SRC_DIR}/Vcpkg.cmake")

#
# Params:
# - PREFIX: the optional prefix to be prepended to the `project_options` and `project_warnings` targets when the function is used in a multi-project fashion.
# - WARNINGS_AS_ERRORS: Treat compiler warnings as errors
# - ENABLE_CPPCHECK: Enable static analysis with cppcheck
# - ENABLE_CLANG_TIDY: Enable static analysis with clang-tidy
# - ENABLE_INCLUDE_WHAT_YOU_USE: Enable static analysis with include-what-you-use
# - ENABLE_COVERAGE: Enable coverage reporting for gcc/clang
# - ENABLE_CACHE: Enable cache if available
# - ENABLE_PCH: Enable Precompiled Headers
# - PCH_HEADERS: the list of the headers to precompile
# - ENABLE_CONAN: Use Conan for dependency management
# - ENABLE_DOXYGEN: Enable doxygen doc builds of source
# - DOXYGEN_THEME: the name of the Doxygen theme to use. Supported themes: `awesome-sidebar` (default), `awesome` and `original`.
# - ENABLE_INTERPROCEDURAL_OPTIMIZATION: Enable Interprocedural Optimization, aka Link Time Optimization (LTO)
# - ENABLE_NATIVE_OPTIMIZATION: Enable the optimizations specific to the build machine (e.g. SSE4_1, AVX2, etc.).
# - ENABLE_USER_LINKER: Enable a specific linker if available
# - ENABLE_BUILD_WITH_TIME_TRACE: Enable -ftime-trace to generate time tracing .json files on clang
# - ENABLE_UNITY: Enable Unity builds of projects
# - ENABLE_SANITIZER_ADDRESS: Enable address sanitizer
# - ENABLE_SANITIZER_LEAK: Enable leak sanitizer
# - ENABLE_SANITIZER_UNDEFINED_BEHAVIOR: Enable undefined behavior sanitizer
# - ENABLE_SANITIZER_THREAD: Enable thread sanitizer
# - ENABLE_SANITIZER_MEMORY: Enable memory sanitizer
# - LINKER: choose a specific linker (e.g. lld, gold, bfd). If set to OFF (default), the linker is automatically chosen.
# - MSVC_WARNINGS: Override the defaults for the MSVC warnings
# - CLANG_WARNINGS: Override the defaults for the CLANG warnings
# - GCC_WARNINGS: Override the defaults for the GCC warnings
# - CUDA_WARNINGS: Override the defaults for the CUDA warnings
# - CPPCHECK_OPTIONS: Override the defaults for CppCheck settings
# - CONAN_OPTIONS: Extra Conan options
#
# NOTE: cmake-lint [C0103] Invalid macro name "project_options" doesn't match `[0-9A-Z_]+`
macro(project_options)
  set(options
      WARNINGS_AS_ERRORS
      ENABLE_COVERAGE
      ENABLE_CPPCHECK
      ENABLE_CLANG_TIDY
      ENABLE_VS_ANALYSIS
      ENABLE_INCLUDE_WHAT_YOU_USE
      ENABLE_CACHE
      ENABLE_PCH
      ENABLE_CONAN
      ENABLE_VCPKG
      ENABLE_DOXYGEN
      ENABLE_INTERPROCEDURAL_OPTIMIZATION
      ENABLE_NATIVE_OPTIMIZATION
      ENABLE_USER_LINKER
      ENABLE_BUILD_WITH_TIME_TRACE
      ENABLE_UNITY
      ENABLE_SANITIZER_ADDRESS
      ENABLE_SANITIZER_LEAK
      ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
      ENABLE_SANITIZER_THREAD
      ENABLE_SANITIZER_MEMORY)
  set(oneValueArgs
      PREFIX
      LINKER
      VS_ANALYSIS_RULESET
      CONAN_PROFILE)
  set(multiValueArgs
      DOXYGEN_THEME
      MSVC_WARNINGS
      CLANG_WARNINGS
      GCC_WARNINGS
      CUDA_WARNINGS
      CPPCHECK_OPTIONS
      PCH_HEADERS
      CONAN_OPTIONS)
  cmake_parse_arguments(
    ProjectOptions
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN})

  # set warning message level
  if(${ProjectOptions_WARNINGS_AS_ERRORS})
    set(WARNINGS_AS_ERRORS ${ProjectOptions_WARNINGS_AS_ERRORS})
    set(WARNING_MESSAGE SEND_ERROR)
  else()
    set(WARNING_MESSAGE WARNING)
  endif()

  common_project_options()

  # Add an interface library for the options
  set(_options_target project_options)
  set(_warnings_target project_warnings)
  if(NOT
     "${ProjectOptions_PREFIX}"
     STREQUAL
     "")
    set(_options_target "${ProjectOptions_PREFIX}_project_options")
    set(_warnings_target "${ProjectOptions_PREFIX}_project_warnings")
  else()
    if(TARGET project_options)
      message(
        FATAL
        "Multiple calls to `project_options` in the same `project` detected, but the argument `PREFIX` that is prepended to `project_options` and `project_warnings` is not set."
      )
    endif()
  endif()

  add_library(${_options_target} INTERFACE)
  add_library(${_warnings_target} INTERFACE)

  # fix mingw
  mingw_unicode()

  if(NOT
     "${ProjectOptions_ENABLE_IPO}"
     STREQUAL
     "")
    message(WARNING "Deprecation: Use ENABLE_INTERPROCEDURAL_OPTIMIZATION instead of ENABLE_IPO")
    set(ProjectOptions_ENABLE_INTERPROCEDURAL_OPTIMIZATION ${ProjectOptions_ENABLE_IPO})
  endif()
  if(${ProjectOptions_ENABLE_INTERPROCEDURAL_OPTIMIZATION})
    enable_interprocedural_optimization(${_options_target})
  endif()

  if(${ProjectOptions_ENABLE_NATIVE_OPTIMIZATION})
    enable_native_optimization(${_options_target})
  endif()

  if(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    if(ProjectOptions_ENABLE_BUILD_WITH_TIME_TRACE)
      target_compile_options(${_options_target} INTERFACE -ftime-trace)
    endif()
  endif()

  if(${ProjectOptions_ENABLE_CACHE})
    # enable cache system
    enable_cache()
  endif()

  # use the linker
  configure_linker(${_options_target} "${ProjectOptions_LINKER}")

  # standard compiler warnings
  set_project_warnings(
    ${_warnings_target}
    "${WARNINGS_AS_ERRORS}"
    "${ProjectOptions_MSVC_WARNINGS}"
    "${ProjectOptions_CLANG_WARNINGS}"
    "${ProjectOptions_GCC_WARNINGS}"
    "${ProjectOptions_CUDA_WARNINGS}")

  if(${ProjectOptions_ENABLE_COVERAGE})
    enable_coverage(${_options_target})
  endif()

  # sanitizer options if supported by compiler
  enable_sanitizers(
    ${_options_target}
    ${ProjectOptions_ENABLE_SANITIZER_ADDRESS}
    ${ProjectOptions_ENABLE_SANITIZER_LEAK}
    ${ProjectOptions_ENABLE_SANITIZER_UNDEFINED_BEHAVIOR}
    ${ProjectOptions_ENABLE_SANITIZER_THREAD}
    ${ProjectOptions_ENABLE_SANITIZER_MEMORY})

  if(${ProjectOptions_ENABLE_DOXYGEN})
    # enable doxygen
    enable_doxygen("${ProjectOptions_DOXYGEN_THEME}")
  endif()

  # allow for static analysis options
  if(${ProjectOptions_ENABLE_CPPCHECK})
    enable_cppcheck("${ProjectOptions_CPPCHECK_OPTIONS}")
  endif()

  if(${ProjectOptions_ENABLE_CLANG_TIDY})
    enable_clang_tidy()
  endif()

  if(${ProjectOptions_ENABLE_VS_ANALYSIS})
    enable_vs_analysis("${ProjectOptions_VS_ANALYSIS_RULESET}")
  endif()

  if(${ProjectOptions_ENABLE_INCLUDE_WHAT_YOU_USE})
    enable_include_what_you_use()
  endif()

  if(${ProjectOptions_ENABLE_PCH})
    if(NOT ProjectOptions_PCH_HEADERS)
      set(ProjectOptions_PCH_HEADERS
          <vector>
          <string>
          <map>
          <utility>)
    endif()
    target_precompile_headers(${_options_target} INTERFACE ${ProjectOptions_PCH_HEADERS})
  endif()

  if(${ProjectOptions_ENABLE_VCPKG})
    run_vcpkg()
  endif()

  if(${ProjectOptions_ENABLE_CONAN})
    run_conan()
  endif()

  if(${ProjectOptions_ENABLE_UNITY})
    # Add for any project you want to apply unity builds for
    set_target_properties(${_options_target} PROPERTIES UNITY_BUILD ON)
  endif()

endmacro()
