cmake_minimum_required(VERSION 3.20)
# 3.20 is required by the windows toolchain and cmake_path. It also has a more reliable building functionality.
# 3.18 required by package_project and interprocedural optimization. It also has a more reliable building functionality (no errors during the linking stage).

include_guard()

# fix DOWNLOAD_EXTRACT_TIMESTAMP warning in FetchContent
if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.24.0")
  cmake_policy(SET CMP0135 NEW)
endif()

# only useable here
set(ProjectOptions_SRC_DIR ${CMAKE_CURRENT_LIST_DIR})

# include the files to allow calling individual functions (including the files does not run any code.)
include("${CMAKE_CURRENT_LIST_DIR}/Common.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Utilities.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/SystemLink.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Cuda.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/PackageProject.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Optimization.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Cache.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Linker.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/CompilerWarnings.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Tests.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Sanitizers.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Doxygen.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/StaticAnalyzers.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/VCEnvironment.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/MinGW.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/DetectCompiler.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/CrossCompiler.cmake")

# Include msvc toolchain on windows if the generator is not visual studio. Should be called before run_vcpkg and run_conan to be effective
msvc_toolchain()

include("${CMAKE_CURRENT_LIST_DIR}/Conan.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Vcpkg.cmake")

#[[.rst:

.. include:: ../../docs/src/project_options.rst

#]]
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
      DISABLE_EXCEPTIONS
      DISABLE_RTTI
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
      CONAN_PROFILE
      CONAN_HOST_PROFILE
      CONAN_BUILD_PROFILE)
  set(multiValueArgs
      DOXYGEN_THEME
      MSVC_WARNINGS
      CLANG_WARNINGS
      GCC_WARNINGS
      CUDA_WARNINGS
      CPPCHECK_OPTIONS
      CLANG_TIDY_EXTRA_ARGUMENTS
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

  if(${ProjectOptions_DISABLE_EXCEPTIONS})
    disable_exceptions(${_options_target})
  endif()
  if(${ProjectOptions_DISABLE_RTTI})
    disable_rtti(${_options_target})
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
    enable_clang_tidy("${ProjectOptions_CLANG_TIDY_EXTRA_ARGUMENTS}")
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
