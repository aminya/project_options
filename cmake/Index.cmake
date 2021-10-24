cmake_minimum_required(VERSION 3.16)

set(CMAKELIB_SRC_DIR
    ${CMAKE_CURRENT_LIST_DIR}
    CACHE FILEPATH ""
)

include("${CMAKELIB_SRC_DIR}/PreventInSourceBuilds.cmake")

#
# Params:
# - WARNINGS_AS_ERRORS: Treat compiler warnings as errors
# - ENABLE_CPPCHECK: Enable static analysis with cppcheck
# - ENABLE_CLANG_TIDY: Enable static analysis with clang-tidy
# - ENABLE_INCLUDE_WHAT_YOU_USE: Enable static analysis with include-what-you-use
# - ENABLE_COVERAGE: Enable coverage reporting for gcc/clang
# - ENABLE_CACHE: Enable cache if available
# - ENABLE_PCH: Enable Precompiled Headers
# - ENABLE_CONAN: Use Conan for dependency management
# - ENABLE_DOXYGEN: Enable doxygen doc builds of source
# - ENABLE_IPO: Enable Interprocedural Optimization, aka Link Time Optimization (LTO)
# - ENABLE_USER_LINKER: Enable a specific linker if available
# - ENABLE_BUILD_WITH_TIME_TRACE: Enable -ftime-trace to generate time tracing .json files on clang
# - ENABLE_UNITY: Enable Unity builds of projects
# - ENABLE_SANITIZER_ADDRESS: Enable address sanitizer
# - ENABLE_SANITIZER_LEAK: Enable leak sanitizer
# - ENABLE_SANITIZER_UNDEFINED_BEHAVIOR: Enable undefined behavior sanitizer
# - ENABLE_SANITIZER_THREAD: Enable thread sanitizer
# - ENABLE_SANITIZER_MEMORY: Enable memory sanitizer
# - MSVC_WARNINGS: Override the defaults for the MSVC warnings
# - CLANG_WARNINGS: Override the defaults for the CLANG warnings
# - GCC_WARNINGS: Override the defaults for the GCC warnings
# - CONAN_OPTIONS: Extra Conan options
macro(cmakelib)
  set(options
      WARNINGS_AS_ERRORS
      ENABLE_COVERAGE
      ENABLE_CPPCHECK
      ENABLE_CLANG_TIDY
      ENABLE_INCLUDE_WHAT_YOU_USE
      ENABLE_CACHE
      ENABLE_PCH
      ENABLE_CONAN
      ENABLE_DOXYGEN
      ENABLE_IPO
      ENABLE_USER_LINKER
      ENABLE_BUILD_WITH_TIME_TRACE
      ENABLE_UNITY
      ENABLE_SANITIZER_ADDRESS
      ENABLE_SANITIZER_LEAK
      ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
      ENABLE_SANITIZER_THREAD
      ENABLE_SANITIZER_MEMORY
  )
  set(oneValueArgs MSVC_WARNINGS CLANG_WARNINGS GCC_WARNINGS)
  set(multiValueArgs CONAN_OPTIONS)
  cmake_parse_arguments(
    cmakelib
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  include("${CMAKELIB_SRC_DIR}/StandardProjectSettings.cmake")

  if(${cmakelib_ENABLE_IPO})
    include("${CMAKELIB_SRC_DIR}/InterproceduralOptimization.cmake")
    enable_ipo()
  endif()

  # Link this 'library' to set the c++ standard / compile-time options requested
  add_library(project_options INTERFACE)

  if(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    if(cmakelib_ENABLE_BUILD_WITH_TIME_TRACE)
      target_compile_options(project_options INTERFACE -ftime-trace)
    endif()
  endif()

  # Link this 'library' to use the warnings specified in CompilerWarnings.cmake
  add_library(project_warnings INTERFACE)

  if(${cmakelib_ENABLE_CACHE})
    # enable cache system
    include("${CMAKELIB_SRC_DIR}/Cache.cmake")
    enable_cache()
  endif()

  if(${cmakelib_ENABLE_USER_LINKER})
    # Add linker configuration
    include("${CMAKELIB_SRC_DIR}/Linker.cmake")
    configure_linker(project_options)
  endif()

  # standard compiler warnings
  include("${CMAKELIB_SRC_DIR}/CompilerWarnings.cmake")
  set_project_warnings(
    project_warnings
    WARNINGS_AS_ERRORS=${cmakelib_WARNINGS_AS_ERRORS}
    MSVC_WARNINGS=${cmakelib_MSVC_WARNINGS}
    CLANG_WARNINGS=${cmakelib_CLANG_WARNINGS}
    GCC_WARNINGS=${cmakelib_GCC_WARNINGS}
  )

  include("${CMAKELIB_SRC_DIR}/Tests.cmake")
  if(${cmakelib_ENABLE_COVERAGE})
    enable_coverage(${PROJECT_NAME})
  endif()

  # sanitizer options if supported by compiler
  include("${CMAKELIB_SRC_DIR}/Sanitizers.cmake")
  enable_sanitizers(
    project_options
    ${cmakelib_ENABLE_SANITIZER_ADDRESS}
    ${cmakelib_ENABLE_SANITIZER_LEAK}
    ${cmakelib_ENABLE_SANITIZER_UNDEFINED_BEHAVIOR}
    ${cmakelib_ENABLE_SANITIZER_THREAD}
    ${cmakelib_ENABLE_SANITIZER_MEMORY}
  )

  if(${cmakelib_ENABLE_DOXYGEN})
    # enable doxygen
    include("${CMAKELIB_SRC_DIR}/Doxygen.cmake")
    enable_doxygen()
  endif()

  # allow for static analysis options
  include("${CMAKELIB_SRC_DIR}/StaticAnalyzers.cmake")
  if(${cmakelib_ENABLE_CPPCHECK})
    enable_cppcheck()
  endif()

  if(${cmakelib_ENABLE_CLANG_TIDY})
    enable_clang_tidy()
  endif()

  if(${cmakelib_ENABLE_INCLUDE_WHAT_YOU_USE})
    enable_include_what_you_use()
  endif()

  # Very basic PCH example
  if(${cmakelib_ENABLE_PCH})
    # This sets a global PCH parameter, each project will build its own PCH, which is a good idea if any #define's change
    #
    # consider breaking this out per project as necessary
    target_precompile_headers(
      project_options
      INTERFACE
      <vector>
      <string>
      <map>
      <utility>
    )
  endif()

  if(${cmakelib_ENABLE_CONAN})
    include("${CMAKELIB_SRC_DIR}/Conan.cmake")
    run_conan(${cmakelib_CONAN_OPTIONS})
  endif()

  if(${cmakelib_ENABLE_UNITY})
    # Add for any project you want to apply unity builds for
    set_target_properties(${PROJECT_NAME} PROPERTIES UNITY_BUILD ON)
  endif()

endmacro()
