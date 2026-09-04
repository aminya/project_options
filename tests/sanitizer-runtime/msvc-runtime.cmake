cmake_minimum_required(VERSION 3.20)

if(NOT DEFINED TEST_ROOT)
  message(FATAL_ERROR "TEST_ROOT must name the temporary regression-test directory")
endif()

get_filename_component(PROJECT_OPTIONS_ROOT "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)
include("${PROJECT_OPTIONS_ROOT}/src/Sanitizers.cmake")

set(CMAKE_SYSTEM_NAME Windows)
set(MSVC TRUE)

get_filename_component(TEST_ROOT "${TEST_ROOT}" ABSOLUTE)

function(assert_msvc_runtime architecture runtime_architecture)
  set(FAKE_COMPILER_DIR "${TEST_ROOT}/compiler/${architecture}/bin")
  set(CMAKE_CXX_COMPILER "${FAKE_COMPILER_DIR}/cl.exe")
  set(CMAKE_CXX_COMPILER_ID MSVC)
  set(CMAKE_SYSTEM_PROCESSOR "${architecture}")

  file(MAKE_DIRECTORY "${FAKE_COMPILER_DIR}")
  file(WRITE "${CMAKE_CXX_COMPILER}" "fake compiler")
  set(EXPECTED_RUNTIME "${FAKE_COMPILER_DIR}/clang_rt.asan_dynamic-${runtime_architecture}.dll")
  file(WRITE "${EXPECTED_RUNTIME}" "fake ASan runtime")

  unset(SANITIZER_RUNTIME_LIBRARIES CACHE)
  get_sanitizer_runtime_libraries(ACTUAL_RUNTIME)

  if(NOT "${ACTUAL_RUNTIME}" STREQUAL "${EXPECTED_RUNTIME}")
    message(FATAL_ERROR "Expected MSVC sanitizer runtime ${EXPECTED_RUNTIME}, got ${ACTUAL_RUNTIME}")
  endif()
endfunction()

function(assert_clang_cl_does_not_use_msvc_lookup)
  set(FAKE_COMPILER_DIR "${TEST_ROOT}/compiler/clang-cl/bin")
  set(CMAKE_CXX_COMPILER "${FAKE_COMPILER_DIR}/clang-cl.exe")
  set(CMAKE_CXX_COMPILER_ID Clang)
  set(CMAKE_CXX_SIMULATE_ID MSVC)
  set(CMAKE_SYSTEM_PROCESSOR AMD64)

  file(MAKE_DIRECTORY "${FAKE_COMPILER_DIR}")
  file(WRITE "${CMAKE_CXX_COMPILER}" "fake compiler")
  file(WRITE "${FAKE_COMPILER_DIR}/clang_rt.asan_dynamic-x86_64.dll" "fake ASan runtime")

  unset(SANITIZER_RUNTIME_LIBRARIES CACHE)
  get_sanitizer_runtime_libraries(ACTUAL_RUNTIME)

  if(ACTUAL_RUNTIME)
    message(FATAL_ERROR "clang-cl must not use the MSVC cl.exe sibling lookup, got ${ACTUAL_RUNTIME}")
  endif()
endfunction()

assert_msvc_runtime(AMD64 x86_64)
assert_msvc_runtime(x86 i386)
assert_msvc_runtime(ARM64 aarch64)
assert_clang_cl_does_not_use_msvc_lookup()
