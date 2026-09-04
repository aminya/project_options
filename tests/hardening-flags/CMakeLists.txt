cmake_minimum_required(VERSION 3.20)

project(project_options_hardening_flags_regression LANGUAGES CXX C)

include("${CMAKE_CURRENT_LIST_DIR}/../../src/Index.cmake")

project_options(PREFIX no_hardening)

project_options(ENABLE_CONTROL_FLOW_PROTECTION ENABLE_STACK_PROTECTION ENABLE_OVERFLOW_PROTECTION)

# Assert that a target property contains or excludes a value.
function(assert_target_property_contains target property value expected)
  get_target_property(actual_values "${target}" "${property}")
  if(actual_values STREQUAL "actual_values-NOTFOUND")
    set(actual_values "")
  endif()

  string(JOIN ";" actual_values_text ${actual_values})
  string(FIND "${actual_values_text}" "${value}" value_index)
  if(expected AND value_index EQUAL -1)
    message(FATAL_ERROR "${target}.${property} does not contain '${value}': ${actual_values}")
  elseif(NOT expected AND NOT value_index EQUAL -1)
    message(FATAL_ERROR "${target}.${property} unexpectedly contains '${value}': ${actual_values}")
  endif()
endfunction()

# Assert that a directory property does not contain a value.
function(assert_directory_property_excludes property value)
  get_property(actual_values DIRECTORY PROPERTY "${property}")
  if(actual_values STREQUAL "actual_values-NOTFOUND")
    set(actual_values "")
  endif()

  string(JOIN ";" actual_values_text ${actual_values})
  string(FIND "${actual_values_text}" "${value}" value_index)
  if(NOT value_index EQUAL -1)
    message(FATAL_ERROR "Directory ${property} unexpectedly contains '${value}': ${actual_values}")
  endif()
endfunction()

assert_target_property_contains(
  no_hardening_project_options INTERFACE_COMPILE_DEFINITIONS _GLIBCXX_ASSERTIONS FALSE
)

foreach(property IN ITEMS COMPILE_OPTIONS COMPILE_DEFINITIONS LINK_OPTIONS)
  foreach(
    value IN
    ITEMS _GLIBCXX_ASSERTIONS
          -fstack-protector-strong
          -fcf-protection=full
          -fstack-clash-protection
          /sdl
          /DYNAMICBASE
          /guard:cf
          /NXCOMPAT
          /CETCOMPAT
  )
    assert_directory_property_excludes("${property}" "${value}")
  endforeach()
endforeach()

include(CheckCXXCompilerFlag)

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
  assert_target_property_contains(project_options INTERFACE_COMPILE_DEFINITIONS _GLIBCXX_ASSERTIONS TRUE)

  check_cxx_compiler_flag("-fstack-protector-strong" HARDENING_TEST_HAS_STACK_PROTECTOR_STRONG)
  assert_target_property_contains(
    project_options INTERFACE_COMPILE_OPTIONS -fstack-protector-strong
    "${HARDENING_TEST_HAS_STACK_PROTECTOR_STRONG}"
  )

  set(HARDENING_TEST_X86_PROCESSOR FALSE)
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "([xX]86)|(amd64)|(AMD64)|([xX]86_64)|(i686)")
    set(HARDENING_TEST_X86_PROCESSOR TRUE)
  endif()
  if(HARDENING_TEST_X86_PROCESSOR)
    check_cxx_compiler_flag("-fcf-protection=full" HARDENING_TEST_HAS_X86_CFI)
  else()
    set(HARDENING_TEST_HAS_X86_CFI FALSE)
  endif()
  assert_target_property_contains(
    project_options INTERFACE_COMPILE_OPTIONS -fcf-protection=full "${HARDENING_TEST_HAS_X86_CFI}"
  )
  assert_target_property_contains(
    project_options INTERFACE_LINK_OPTIONS -fcf-protection=full "${HARDENING_TEST_HAS_X86_CFI}"
  )

  set(HARDENING_TEST_APPLE_ARM_CLANG FALSE)
  if(APPLE AND CMAKE_SYSTEM_PROCESSOR MATCHES "arm64" AND CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    set(HARDENING_TEST_APPLE_ARM_CLANG TRUE)
  endif()
  if(NOT HARDENING_TEST_APPLE_ARM_CLANG)
    check_cxx_compiler_flag("-fstack-clash-protection" HARDENING_TEST_HAS_STACK_CLASH)
  else()
    set(HARDENING_TEST_HAS_STACK_CLASH FALSE)
  endif()
  assert_target_property_contains(
    project_options INTERFACE_COMPILE_OPTIONS -fstack-clash-protection "${HARDENING_TEST_HAS_STACK_CLASH}"
  )
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
  check_cxx_compiler_flag("/guard:cf" HARDENING_TEST_HAS_CONTROL_FLOW_GUARD)
  assert_target_property_contains(
    project_options INTERFACE_COMPILE_OPTIONS /guard:cf "${HARDENING_TEST_HAS_CONTROL_FLOW_GUARD}"
  )
  assert_target_property_contains(
    project_options INTERFACE_LINK_OPTIONS /guard:cf "${HARDENING_TEST_HAS_CONTROL_FLOW_GUARD}"
  )

  check_cxx_compiler_flag("/sdl" HARDENING_TEST_HAS_SDL)
  assert_target_property_contains(project_options INTERFACE_COMPILE_OPTIONS /sdl "${HARDENING_TEST_HAS_SDL}")
else()
  message(FATAL_ERROR "Unsupported compiler for hardening regression: ${CMAKE_CXX_COMPILER_ID}")
endif()
