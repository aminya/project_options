cmake_minimum_required(VERSION 3.20)

if(NOT DEFINED TEST_ROOT)
  message(FATAL_ERROR "TEST_ROOT must name the temporary regression-test directory")
endif()

get_filename_component(PROJECT_OPTIONS_ROOT "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)
include("${PROJECT_OPTIONS_ROOT}/src/Sanitizers.cmake")

set(FAKE_COMPILER_DIR "${TEST_ROOT}/compiler/bin/Hostx64/x64")
set(CMAKE_CXX_COMPILER "${FAKE_COMPILER_DIR}/cl.exe")
set(CMAKE_CXX_COMPILER_ID MSVC)
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR AMD64)
set(MSVC TRUE)

file(MAKE_DIRECTORY "${FAKE_COMPILER_DIR}")
file(WRITE "${CMAKE_CXX_COMPILER}" "fake compiler")
set(EXPECTED_RUNTIME "${FAKE_COMPILER_DIR}/clang_rt.asan_dynamic-x86_64.dll")
file(WRITE "${EXPECTED_RUNTIME}" "fake ASan runtime")

get_sanitizer_runtime_libraries(ACTUAL_RUNTIME)

if(NOT "${ACTUAL_RUNTIME}" STREQUAL "${EXPECTED_RUNTIME}")
  message(FATAL_ERROR "Expected MSVC sanitizer runtime ${EXPECTED_RUNTIME}, got ${ACTUAL_RUNTIME}")
endif()
