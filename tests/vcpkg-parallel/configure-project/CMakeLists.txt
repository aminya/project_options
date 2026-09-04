cmake_minimum_required(VERSION 3.20)

if(NOT DEFINED PROJECT_OPTIONS_ROOT
   OR NOT DEFINED VCPKG_DIR
   OR NOT DEFINED VCPKG_URL
   OR NOT DEFINED VCPKG_REV
)
  message(FATAL_ERROR "The vcpkg parallel fixture requires all -D input variables")
endif()

include("${PROJECT_OPTIONS_ROOT}/src/Index.cmake")

if(EXERCISE_REENTRANT_LOCK)
  set(_vcpkg_args_VCPKG_DIR "${VCPKG_DIR}")
  _lock_vcpkg_repository()
endif()

run_vcpkg(
  VCPKG_DIR
  "${VCPKG_DIR}"
  VCPKG_URL
  "${VCPKG_URL}"
  VCPKG_REV
  "${VCPKG_REV}"
)

if(EXERCISE_REENTRANT_LOCK)
  run_vcpkg(
    VCPKG_DIR
    "${VCPKG_DIR}"
    VCPKG_URL
    "${VCPKG_URL}"
    VCPKG_REV
    "${VCPKG_REV}"
  )
endif()

if(EXERCISE_REENTRANT_LOCK)
  _unlock_vcpkg_repository()
endif()

project(vcpkg_parallel_fixture NONE)
