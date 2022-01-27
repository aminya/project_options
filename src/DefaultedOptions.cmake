# ENABLE_DEVELOPER_MODE: sets defaults appropriate for developers, this is defaulted to ON
#  * WARNINGS_AS_ERRORS: ON
#  * ENABLE_SANITIZER_ADDRESS: ON
#  * ENABLE_CLANG_TIDY: ON for unix
#  * ENABLE_SANITIZER_UNDEFINED: ON for unix
#  * ENABLE_CPPCHECK: ON for unix

# For non-developer builds
#  -DENABLE_DEVELOPER_MODE:BOOL=OFF
# Is recommended

# In developer mode, all features have options that show up in the CMake GUI tools

# defaulted_options() macro enables all recommended defaults with appropriately
# applied options from the GUI which are set

# Any default can be overridden
# set(<feature_name>_DEFAULT <value>) - set default for both user and developer modes
# set(<feature_name>_DEVELOPER_DEFAULT <value>) - set default for developer mode
# set(<feature_name>_USER_DEFAULT <value>) - set default for user mode

option(ENABLE_DEVELOPER_MODE "Set up defaults for a developer of the project, and let developer change options" ON)

if(MSVC)
  set(UNIX_ONLY OFF)
else()
  set(UNIX_ONLY ON)
endif()

include(CMakeDependentOption)

# <option name>;<user mode default>;<developer mode default>;<description>
set(options
    "ENABLE_CACHE\;${UNIX_ONLY}\;${UNIX_ONLY}\;Enable ccache on Unix"
    "WARNINGS_AS_ERRORS\;OFF\;ON\;Treat warnings as Errors"
    "ENABLE_CLANG_TIDY\;OFF\;${UNIX_ONLY}\;Enable clang-tidy analysis during compilation"
    "ENABLE_CONAN\;ON\;ON\;Automatically integrate Conan for package management"
    "ENABLE_COVERAGE\;OFF\;OFF\;Analyze and report on coverage"
    "ENABLE_SANITIZER_ADDRESS\;OFF\;ON\;Make memory errors into hard runtime errors (windows/linux/macos)"
    "ENABLE_SANITIZER_UNDEFINED_BEHAVIOR\;OFF\;${UNIX_ONLY}\;Make certain types (numeric mostly) of undefined behavior into runtime errors"
    "ENABLE_CPPCHECK\;OFF\;${UNIX_ONLY}\;Enable cppcheck analysis during compilation"
    "ENABLE_IPO\;OFF\;OFF\;Enable whole-program optimization"
    "ENABLE_INCLUDE_WHAT_YOU_USE\;OFF\;OFF\;Enable include-what-you-use analysis during compilation"
    "ENABLE_PCH\;ON\;OFF\;Enable pre-compiled-headers support"
    "ENABLE_DOXYGEN\;OFF\;OFF\;Build documentation with Doxygen"
    "ENABLE_USER_LINKER\;OFF\;OFF\;Allow custom linker settings"
    "ENABLE_BUILD_WITH_TIME_TRACE\;OFF\;OFF\;Generates report of where compile-time is spent"
    "ENABLE_UNITY\;OFF\;OFF\;Merge C++ files into larger C++ files, can speed up compilation sometimes"
    "ENABLE_SANITIZER_LEAK\;OFF\;OFF\;Make memory leaks into hard runtime errors"
    "ENABLE_SANITIZER_THREAD\;OFF\;OFF\;Make thread race conditions into hard runtime errors"
    "ENABLE_SANITIZER_MEMORY\;OFF\;OFF\;Make other memory errors into runtime errors")

foreach(option ${options})
  list(
    GET
    option
    0
    option_name)
  list(
    GET
    option
    1
    option_user_default)
  list(
    GET
    option
    2
    option_developer_default)
  list(
    GET
    option
    3
    option_description)

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

  cmake_dependent_option(
    OPT_${option_name}
    "${option_description}"
    ${option_developer_default}
    ENABLE_DEVELOPER_MODE
    ${option_user_default})

  if(OPT_${option_name})
    set(${option_name}_VALUE ${option_name})
  else()
    unset(${option_name}_VALUE)
  endif()
endforeach()

macro(defaulted_project_options)
  project_options(
    ${ENABLE_CONAN_VALUE}
    ${ENABLE_CACHE_VALUE}
    ${WARNINGS_AS_ERRORS_VALUE}
    ${ENABLE_CPPCHECK_VALUE}
    ${ENABLE_CLANG_TIDY_VALUE}
    ${ENABLE_COVERAGE_VALUE}
    ${ENABLE_IPO_VALUE}
    ${ENABLE_INCLUDE_WHAT_YOU_USE_VALUE}
    ${ENABLE_PCH_VALUE}
    ${ENABLE_DOXYGEN_VALUE}
    ${ENABLE_USER_LINKER_VALUE}
    ${ENABLE_BUILD_WITH_TIME_TRACE_VALUE}
    ${ENABLE_UNITY_VALUE}
    ${ENABLE_SANITIZER_ADDRESS_VALUE}
    ${ENABLE_SANITIZER_LEAK_VALUE}
    ${ENABLE_SANITIZER_UNDEFINED_BEHAVIOR_VALUE}
    ${ENABLE_SANITIZER_THREAD_VALUE}
    ${ENABLE_SANITIZER_MEMORY_VALUE}
    ${ARGN})
endmacro()
