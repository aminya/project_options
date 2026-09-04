cmake_minimum_required(VERSION 3.20)

project(vcpkg_parallel_regression NONE)

include(CTest)

if(NOT BUILD_TESTING)
  return()
endif()

find_program(GIT_EXECUTABLE git REQUIRED)

get_filename_component(PROJECT_OPTIONS_ROOT "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)
set(HARNESS_ROOT "${CMAKE_CURRENT_BINARY_DIR}/vcpkg-parallel")
set(FAKE_VCPKG_REPOSITORY "${HARNESS_ROOT}/fake-vcpkg-repository")
set(SHARED_VCPKG_DIR "${HARNESS_ROOT}/shared-vcpkg")
set(CONFIGURE_A_BINARY_DIR "${HARNESS_ROOT}/configure-a")
set(CONFIGURE_B_BINARY_DIR "${HARNESS_ROOT}/configure-b")
set(CONFIGURE_REENTRANT_BINARY_DIR "${HARNESS_ROOT}/configure-reentrant")

execute_process(
  COMMAND "${CMAKE_COMMAND}"
          "-DREPO_DIR=${FAKE_VCPKG_REPOSITORY}"
          "-P"
          "${CMAKE_CURRENT_LIST_DIR}/generate_fake_vcpkg.cmake"
  RESULT_VARIABLE GENERATE_RESULT
  OUTPUT_VARIABLE GENERATE_OUTPUT
  ERROR_VARIABLE GENERATE_ERROR
)
if(GENERATE_RESULT)
  message(
    FATAL_ERROR
    "Could not generate fake vcpkg repository (${GENERATE_RESULT}):\n"
    "${GENERATE_OUTPUT}\n${GENERATE_ERROR}"
  )
endif()

execute_process(
  COMMAND "${GIT_EXECUTABLE}" rev-parse HEAD
  WORKING_DIRECTORY "${FAKE_VCPKG_REPOSITORY}"
  OUTPUT_VARIABLE FAKE_VCPKG_REVISION
  OUTPUT_STRIP_TRAILING_WHITESPACE
  RESULT_VARIABLE REVISION_RESULT
  ERROR_VARIABLE REVISION_ERROR
)
if(REVISION_RESULT)
  message(FATAL_ERROR "Could not determine fake vcpkg revision: ${REVISION_ERROR}")
endif()

add_test(
  NAME vcpkg_parallel_prepare
  COMMAND "${CMAKE_COMMAND}"
          "-DFAKE_VCPKG_REPOSITORY=${FAKE_VCPKG_REPOSITORY}"
          "-DSHARED_VCPKG_DIR=${SHARED_VCPKG_DIR}"
          "-DCONFIGURE_A_BINARY_DIR=${CONFIGURE_A_BINARY_DIR}"
          "-DCONFIGURE_B_BINARY_DIR=${CONFIGURE_B_BINARY_DIR}"
          "-P"
          "${CMAKE_CURRENT_LIST_DIR}/prepare_shared_vcpkg.cmake"
)
set_tests_properties(vcpkg_parallel_prepare PROPERTIES FIXTURES_SETUP vcpkg_parallel_shared)

foreach(CONFIGURE_NAME IN ITEMS a b)
  set(CONFIGURE_BINARY_DIR "${HARNESS_ROOT}/configure-${CONFIGURE_NAME}")
  add_test(
    NAME "vcpkg_parallel_configure_${CONFIGURE_NAME}"
    COMMAND "${CMAKE_COMMAND}"
            "-S"
            "${CMAKE_CURRENT_LIST_DIR}/configure-project"
            "-B"
            "${CONFIGURE_BINARY_DIR}"
            "-DPROJECT_OPTIONS_ROOT=${PROJECT_OPTIONS_ROOT}"
            "-DVCPKG_DIR=${SHARED_VCPKG_DIR}"
            "-DVCPKG_URL=${FAKE_VCPKG_REPOSITORY}"
            "-DVCPKG_REV=${FAKE_VCPKG_REVISION}"
  )
  set_tests_properties(
    "vcpkg_parallel_configure_${CONFIGURE_NAME}"
    PROPERTIES FIXTURES_REQUIRED vcpkg_parallel_shared
  )
endforeach()

add_test(
  NAME vcpkg_parallel_reentrant_configure
  COMMAND "${CMAKE_COMMAND}"
          "-S"
          "${CMAKE_CURRENT_LIST_DIR}/configure-project"
          "-B"
          "${CONFIGURE_REENTRANT_BINARY_DIR}"
          "-DPROJECT_OPTIONS_ROOT=${PROJECT_OPTIONS_ROOT}"
          "-DVCPKG_DIR=${SHARED_VCPKG_DIR}"
          "-DVCPKG_URL=${FAKE_VCPKG_REPOSITORY}"
          "-DVCPKG_REV=${FAKE_VCPKG_REVISION}"
          "-DEXERCISE_REENTRANT_LOCK=ON"
)
set_tests_properties(
  vcpkg_parallel_reentrant_configure
  PROPERTIES
    FIXTURES_REQUIRED vcpkg_parallel_shared
    TIMEOUT 5
)
