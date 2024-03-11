include_guard()

#[[.rst:

``dynamic_project_options``
===========================

During the test and development, it can be useful to change options on
the fly. For example, to enable sanitizers when running tests. You can
include ``DynamicOptions.cmake``, which imports the
``dynamic_project_options`` function.

``dynamic_project_options`` provides a dynamic set of defaults (all
static analysis and runtime analysis enabled for platforms where that is
possible) while also providing a high-level option
``ENABLE_DEVELOPER_MODE`` (defaulted to ``ON``) which can be turned off
for easy use by non-developers.

The goal of the ``dynamic_project_options`` is to give a safe and
well-analyzed environment to the developer by default while
simultaneously making it easy for a user of the project to compile while
not having to worry about clang-tidy, sanitizers, cppcheck, etc.

The defaults presented to the user can be modified with

-  ``set(<featurename>_DEFAULT value)`` - for user and developer builds
-  ``set(<featurename>_USER_DEFAULT value)`` - for user builds
-  ``set(<featureoptionname>_DEVELOPER_DEFAULT value)`` - for developer
   builds

If you need to fix a setting for the sake of a command-line
configuration, you can use:

.. code:: shell

   cmake -DOPT_<featurename>:BOOL=value

See ``dynamic_project_options()`` in action in `this template
repository <https://github.com/aminya/cpp_boilerplate_project>`__.

Here is an example of how to use ``dynamic_project_options``:

.. code:: cmake

   cmake_minimum_required(VERSION 3.20)

   # set a default CXX standard for the tools and targets that do not specify them.
   # If commented, the latest supported standard for your compiler is automatically set.
   # set(CMAKE_CXX_STANDARD 20)

   include(FetchContent)
   if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.24.0")
     cmake_policy(SET CMP0135 NEW)
   endif()

   # Add project_options from https://github.com/aminya/project_options
   # Change the version in the following URL to update the package (watch the releases of the repository for future updates)
   set(PROJECT_OPTIONS_VERSION "v0.35.1")
   FetchContent_Declare(
     _project_options
     URL https://github.com/aminya/project_options/archive/refs/tags/${PROJECT_OPTIONS_VERSION}.zip)
   FetchContent_MakeAvailable(_project_options)
   include(${_project_options_SOURCE_DIR}/Index.cmake)

   # install vcpkg dependencies: - should be called before defining project()
   # run_vcpkg()
   # install conan dependencies: - should be called before defining project()
   # run_conan()

   # Set the project name and language
   project(myproject LANGUAGES CXX C)

   # Set PCH to be on by default for all non-Developer Mode Builds
   set(ENABLE_PCH_USER_DEFAULT ON)

   # Initialize project_options variable related to this project
   # This overwrites `project_options` and sets `project_warnings`
   # This also accepts the same arguments as `project_options`.
   dynamic_project_options(
     # set the common headers you want to precompile
     PCH_HEADERS <vector> <string> <fmt/format.h> <Eigen/Dense>
   )

Add your executables, etc., as described above.


]]
macro(dynamic_project_options)
  option(ENABLE_DEVELOPER_MODE
         "Set up defaults for a developer of the project, and let developer change options" OFF
  )
  if(NOT ${ENABLE_DEVELOPER_MODE})
    message(
      STATUS
        "Developer mode is OFF. For developement, use `-DENABLE_DEVELOPER_MODE:BOOL=ON`. Building the project for the end-user..."
    )
  else()
    message(
      STATUS
        "Developer mode is ON. For production, use `-DENABLE_DEVELOPER_MODE:BOOL=OFF`. Building the project for the developer..."
    )
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*")
     AND NOT WIN32
  )
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*")
     AND WIN32
  )
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()

  # ccache, clang-tidy, cppcheck are only supported with Ninja and Makefile based generators
  # note that it is possible to use Ninja with cl, so this still allows clang-tidy on Windows
  # with CL.
  #
  # We are only setting the default options here. If the user attempts to enable
  # these tools on a platform with unknown support, they are on their own.
  #
  # Also note, cppcheck has an option to be run on VCproj files, so we should investigate that
  # Further note: MSVC2022 has builtin support for clang-tidy, but I can find
  # no way to enable that via CMake
  if(CMAKE_GENERATOR MATCHES ".*Makefile*." OR CMAKE_GENERATOR MATCHES ".*Ninja*")
    set(MAKEFILE_OR_NINJA ON)
  else()
    set(MAKEFILE_OR_NINJA OFF)
  endif()

  include(CMakeDependentOption)

  # <option type>;<option name>;<user mode default>;<developer mode default>;<description>
  set(options
      "0\;WARNINGS_AS_ERRORS\;OFF\;ON\;Treat warnings as Errors"
      "0\;ENABLE_COVERAGE\;OFF\;OFF\;Analyze and report on coverage"
      "0\;ENABLE_CPPCHECK\;OFF\;${MAKEFILE_OR_NINJA}\;Enable cppcheck analysis during compilation"
      "0\;ENABLE_CLANG_TIDY\;OFF\;${MAKEFILE_OR_NINJA}\;Enable clang-tidy analysis during compilation"
      "0\;ENABLE_VS_ANALYSIS\;ON\;ON\;Enable Visual Studio IDE code analysis if the generator is Visual Studio."
      "0\;ENABLE_INCLUDE_WHAT_YOU_USE\;OFF\;OFF\;Enable include-what-you-use analysis during compilation"
      "0\;ENABLE_GCC_ANALYZER\;OFF\;OFF\;Enable GCC (10+) analyzer during compilation"
      "0\;ENABLE_CACHE\;${MAKEFILE_OR_NINJA}\;${MAKEFILE_OR_NINJA}\;Enable ccache on Unix"
      "0\;ENABLE_PCH\;OFF\;OFF\;Enable pre-compiled-headers support"
      "0\;ENABLE_CONAN\;OFF\;OFF\;Automatically integrate Conan for package management"
      "0\;ENABLE_VCPKG\;OFF\;OFF\;Automatically integrate vcpkg for package management"
      "0\;ENABLE_DOXYGEN\;OFF\;OFF\;Build documentation with Doxygen"
      "0\;ENABLE_INTERPROCEDURAL_OPTIMIZATION\;OFF\;OFF\;Enable whole-program optimization (e.g. LTO)"
      "0\;ENABLE_NATIVE_OPTIMIZATION\;OFF\;OFF\;Enable the optimizations specific to the build machine (e.g. SSE4_1, AVX2, etc.)."
      "0\;DISABLE_EXCEPTIONS\;OFF\;OFF\;Disable Exceptions (no-exceptions and no-unwind-tables flag)"
      "0\;DISABLE_RTTI\;OFF\;OFF\;Disable RTTI (no-rtti flag)"
      "0\;ENABLE_BUILD_WITH_TIME_TRACE\;OFF\;OFF\;Generates report of where compile-time is spent"
      "0\;ENABLE_UNITY\;OFF\;OFF\;Merge C++ files into larger C++ files, can speed up compilation sometimes"
      "0\;ENABLE_SANITIZER_ADDRESS\;OFF\;${SUPPORTS_ASAN}\;Make memory errors into hard runtime errors (windows/linux/macos)"
      "0\;ENABLE_SANITIZER_LEAK\;OFF\;OFF\;Make memory leaks into hard runtime errors"
      "0\;ENABLE_SANITIZER_UNDEFINED_BEHAVIOR\;OFF\;${SUPPORTS_UBSAN}\;Make certain types (numeric mostly) of undefined behavior into runtime errors"
      "0\;ENABLE_SANITIZER_THREAD\;OFF\;OFF\;Make thread race conditions into hard runtime errors"
      "0\;ENABLE_SANITIZER_MEMORY\;OFF\;OFF\;Make other memory errors into runtime errors"
      "0\;ENABLE_CONTROL_FLOW_PROTECTION\;OFF\;OFF\;Enable control flow protection instrumentation"
      "0\;ENABLE_STACK_PROTECTION\;OFF\;OFF\;Enable stack protection instrumentation"
      "0\;ENABLE_OVERFLOW_PROTECTION\;OFF\;OFF\;Enable overflow protection instrumentation"
      "0\;ENABLE_ELF_PROTECTION\;OFF\;OFF\;Enable ELF protection instrumentation"
      "0\;ENABLE_RUNTIME_SYMBOLS_RESOLUTION\;OFF\;OFF\;When ELF protection is enabled, allow resolving symbols at runtime"
      "0\;ENABLE_COMPILE_COMMANDS_SYMLINK\;OFF\;OFF\;Don't create a symlink for compile_commands.json"
      "1\;LINKER\;\;\;Choose a specific linker"
      "1\;VS_ANALYSIS_RULESET\;\;\;Override the defaults for the code analysis rule set in Visual Studio"
      "1\;CONAN_PROFILE\;\;\;Use specific Conan profile"
      "1\;CONAN_HOST_PROFILE\;\;\;Use specific Conan host profile"
      "1\;CONAN_BUILD_PROFILE\;\;\;Use specific Conan build profile"
      "2\;DOXYGEN_THEME\;\;\;Name of the Doxygen theme to use"
      "2\;MSVC_WARNINGS\;\;\;Override the defaults for the MSVC warnings"
      "2\;CLANG_WARNINGS\;\;\;Override the defaults for the CLANG warnings"
      "2\;GCC_WARNINGS\;\;\;Override the defaults for the GCC warnings"
      "2\;CUDA_WARNINGS\;\;\;Override the defaults for the CUDA warnings"
      "2\;CPPCHECK_OPTIONS\;\;\;Override the defaults for the options passed to cppcheck"
      "2\;CLANG_TIDY_EXTRA_ARGUMENTS\;\;\;Additional arguments to use for clang-tidy invocation"
      "2\;GCC_ANALYZER_EXTRA_ARGUMENTS\;\;\;Additional arguments to use for GCC static analysis"
      "2\;PCH_HEADERS\;\;\;List of the headers to precompile"
      "2\;CONAN_OPTIONS\;\;\;Extra Conan options"
  )

  foreach(option ${options})
    list(GET option 0 option_type)
    list(GET option 1 option_name)
    list(GET option 2 option_user_default)
    list(GET option 3 option_developer_default)
    list(GET option 4 option_description)

    if(DEFINED ${option_name}_DEFAULT)
      if(DEFINED ${option_name}_DEVELOPER_DEFAULT OR DEFINED ${option_name}_USER_DEFAULT)
        message(
          SEND_ERROR
            "You have separately defined user/developer defaults and general defaults for ${option_name}. Please either provide a general default OR separate developer/user overrides"
        )
      endif()

      set(option_user_default ${${option_name}_DEFAULT})
      set(option_developer_default ${${option_name}_DEFAULT})
    endif()

    if(DEFINED ${option_name}_USER_DEFAULT)
      set(option_user_default ${${option_name}_USER_DEFAULT})
    endif()

    if(DEFINED ${option_name}_DEVELOPER_DEFAULT)
      set(option_developer_default ${${option_name}_DEVELOPER_DEFAULT})
    endif()

    if(OPT_${option_name})
      if(ENABLE_DEVELOPER_MODE)
        set(option_implicit_default ${option_developer_default})
      else()
        set(option_implicit_default ${option_user_default})
      endif()
      if(option_type EQUAL 0)
        option(OPT_${option_name} "${option_description}" ${option_implicit_default})
      else()
        option(OPT_${option_name} "${option_description}" "${option_implicit_default}")
      endif()
    else()
      if(option_type EQUAL 0)
        cmake_dependent_option(
          OPT_${option_name} "${option_description}" ${option_developer_default}
          ENABLE_DEVELOPER_MODE ${option_user_default}
        )
      else()
        cmake_dependent_option(
          OPT_${option_name} "${option_description}" "${option_developer_default}"
          ENABLE_DEVELOPER_MODE "${option_user_default}"
        )
      endif()
    endif()

    if(OPT_${option_name})
      if(option_type EQUAL 0)
        set(${option_name}_VALUE ${option_name})
      elseif(option_type EQUAL 1)
        set(${option_name}_VALUE ${option_name} "${OPT_${option_name}}")
      elseif(option_type EQUAL 2)
        set(${option_name}_VALUE ${option_name} ${OPT_${option_name}})
      endif()
    else()
      unset(${option_name}_VALUE)
    endif()
  endforeach()

  project_options(
    ${WARNINGS_AS_ERRORS_VALUE}
    ${ENABLE_COVERAGE_VALUE}
    ${ENABLE_CPPCHECK_VALUE}
    ${ENABLE_CLANG_TIDY_VALUE}
    ${ENABLE_VS_ANALYSIS_VALUE}
    ${ENABLE_INCLUDE_WHAT_YOU_USE_VALUE}
    ${ENABLE_GCC_ANALYZER_VALUE}
    ${ENABLE_CACHE_VALUE}
    ${ENABLE_PCH_VALUE}
    ${ENABLE_CONAN_VALUE}
    ${ENABLE_VCPKG_VALUE}
    ${ENABLE_DOXYGEN_VALUE}
    ${ENABLE_INTERPROCEDURAL_OPTIMIZATION_VALUE}
    ${ENABLE_NATIVE_OPTIMIZATION_VALUE}
    ${DISABLE_EXCEPTIONS_VALUE}
    ${DISABLE_RTTI_VALUE}
    ${ENABLE_BUILD_WITH_TIME_TRACE_VALUE}
    ${ENABLE_UNITY_VALUE}
    ${ENABLE_SANITIZER_ADDRESS_VALUE}
    ${ENABLE_SANITIZER_LEAK_VALUE}
    ${ENABLE_SANITIZER_UNDEFINED_BEHAVIOR_VALUE}
    ${ENABLE_SANITIZER_THREAD_VALUE}
    ${ENABLE_SANITIZER_MEMORY_VALUE}
    ${ENABLE_CONTROL_FLOW_PROTECTION_VALUE}
    ${ENABLE_STACK_PROTECTION_VALUE}
    ${ENABLE_OVERFLOW_PROTECTION_VALUE}
    ${ENABLE_ELF_PROTECTION_VALUE}
    ${ENABLE_RUNTIME_SYMBOLS_RESOLUTION_VALUE}
    ${ENABLE_COMPILE_COMMANDS_SYMLINK_VALUE}
    ${LINKER_VALUE}
    ${VS_ANALYSIS_RULESET_VALUE}
    ${CONAN_PROFILE_VALUE}
    ${CONAN_HOST_PROFILE_VALUE}
    ${CONAN_BUILD_PROFILE_VALUE}
    ${DOXYGEN_THEME_VALUE}
    ${MSVC_WARNINGS_VALUE}
    ${CLANG_WARNINGS_VALUE}
    ${GCC_WARNINGS_VALUE}
    ${CUDA_WARNINGS_VALUE}
    ${CPPCHECK_OPTIONS_VALUE}
    ${CLANG_TIDY_EXTRA_ARGUMENTS_VALUE}
    ${GCC_ANALYZER_EXTRA_ARGUMENTS_VALUE}
    ${PCH_HEADERS_VALUE}
    ${CONAN_OPTIONS_VALUE}
    ${ARGN}
  )
endmacro()
