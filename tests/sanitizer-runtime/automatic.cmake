cmake_minimum_required(VERSION 3.20)

if(NOT DEFINED TEST_ROOT)
  message(FATAL_ERROR "TEST_ROOT must name the temporary regression-test directory")
endif()

get_filename_component(PROJECT_OPTIONS_ROOT "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)
get_filename_component(TEST_ROOT "${TEST_ROOT}" ABSOLUTE)
set(TEST_SOURCE "${TEST_ROOT}/automatic/source")
set(TEST_BUILD "${TEST_ROOT}/automatic/build")
set(FAKE_RUNTIME "${TEST_SOURCE}/clang_rt.asan_dynamic-x86_64.dll")

file(MAKE_DIRECTORY "${TEST_SOURCE}")
file(MAKE_DIRECTORY "${TEST_SOURCE}/app")
file(WRITE "${TEST_SOURCE}/main.cpp" "int main() { return 0; }\n")
file(WRITE "${TEST_SOURCE}/app/main.cpp" "int main() { return 0; }\n")
file(WRITE "${FAKE_RUNTIME}" "fake ASan runtime\n")

set(PROJECT_FILE
    [=[
cmake_minimum_required(VERSION 3.20)
project(automatic_sanitizer_runtime LANGUAGES CXX)

include("@PROJECT_OPTIONS_ROOT@/src/Index.cmake")
project_options(ENABLE_SANITIZER_ADDRESS)

add_library(options_bridge INTERFACE)
target_link_libraries(options_bridge INTERFACE project_options)

get_target_property(options_link_options project_options INTERFACE_LINK_OPTIONS)
if(NOT options_link_options MATCHES "sanitize")
  file(WRITE "${CMAKE_BINARY_DIR}/automatic_sanitizer_runtime_skipped.txt" "AddressSanitizer is unsupported\n")
  return()
endif()

add_executable(automatic_runtime main.cpp)
target_link_libraries(automatic_runtime PRIVATE options_bridge)
file(GENERATE OUTPUT "${CMAKE_BINARY_DIR}/automatic_runtime_dir.txt" CONTENT "$<TARGET_FILE_DIR:automatic_runtime>")

add_subdirectory(app)
]=]
)
string(CONFIGURE "${PROJECT_FILE}" PROJECT_FILE @ONLY)
file(WRITE "${TEST_SOURCE}/CMakeLists.txt" "${PROJECT_FILE}")
file(
  WRITE "${TEST_SOURCE}/app/CMakeLists.txt"
  [=[
add_executable(automatic_runtime_subdir main.cpp)
target_link_libraries(automatic_runtime_subdir PRIVATE options_bridge)
file(GENERATE OUTPUT "${CMAKE_BINARY_DIR}/automatic_runtime_subdir_dir.txt" CONTENT "$<TARGET_FILE_DIR:automatic_runtime_subdir>")
]=]
)

execute_process(
  COMMAND "${CMAKE_COMMAND}" -S "${TEST_SOURCE}" -B "${TEST_BUILD}" -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
          "-DSANITIZER_RUNTIME_LIBRARIES=${FAKE_RUNTIME}"
  RESULT_VARIABLE CONFIGURE_RESULT
  OUTPUT_VARIABLE CONFIGURE_OUTPUT
  ERROR_VARIABLE CONFIGURE_ERROR
)
if(CONFIGURE_RESULT)
  message(
    FATAL_ERROR
      "Automatic sanitizer-runtime regression configure failed:\n${CONFIGURE_OUTPUT}\n${CONFIGURE_ERROR}"
  )
endif()

if(EXISTS "${TEST_BUILD}/automatic_sanitizer_runtime_skipped.txt")
  message(STATUS "Skipping automatic sanitizer-runtime regression because AddressSanitizer is unsupported")
  return()
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" --build "${TEST_BUILD}"
  RESULT_VARIABLE BUILD_RESULT
  OUTPUT_VARIABLE BUILD_OUTPUT
  ERROR_VARIABLE BUILD_ERROR
)
if(BUILD_RESULT)
  message(FATAL_ERROR "Automatic sanitizer-runtime regression build failed:\n${BUILD_OUTPUT}\n${BUILD_ERROR}")
endif()

file(READ "${TEST_BUILD}/automatic_runtime_dir.txt" AUTOMATIC_RUNTIME_DIRECTORY)
string(STRIP "${AUTOMATIC_RUNTIME_DIRECTORY}" AUTOMATIC_RUNTIME_DIRECTORY)
if(NOT EXISTS "${AUTOMATIC_RUNTIME_DIRECTORY}/clang_rt.asan_dynamic-x86_64.dll")
  message(
    FATAL_ERROR
      "Automatic sanitizer-runtime regression did not stage the runtime next to the executable in '${AUTOMATIC_RUNTIME_DIRECTORY}'"
  )
endif()
file(READ "${TEST_BUILD}/automatic_runtime_subdir_dir.txt" AUTOMATIC_RUNTIME_SUBDIR_DIRECTORY)
string(STRIP "${AUTOMATIC_RUNTIME_SUBDIR_DIRECTORY}" AUTOMATIC_RUNTIME_SUBDIR_DIRECTORY)
if(NOT EXISTS "${AUTOMATIC_RUNTIME_SUBDIR_DIRECTORY}/clang_rt.asan_dynamic-x86_64.dll")
  message(
    FATAL_ERROR
      "Automatic sanitizer-runtime regression did not stage the runtime next to the subdirectory executable in '${AUTOMATIC_RUNTIME_SUBDIR_DIRECTORY}'"
  )
endif()
