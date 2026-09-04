cmake_minimum_required(VERSION 3.20)

if(NOT DEFINED PROJECT_OPTIONS_ROOT
   OR NOT DEFINED VCPKG_DIR
   OR NOT DEFINED VCPKG_URL
   OR NOT DEFINED VCPKG_REV
)
  message(FATAL_ERROR "The vcpkg parallel fixture requires all -D input variables")
endif()

include("${PROJECT_OPTIONS_ROOT}/src/Index.cmake")

run_vcpkg(
  VCPKG_DIR "${VCPKG_DIR}"
  VCPKG_URL "${VCPKG_URL}"
  VCPKG_REV "${VCPKG_REV}"
)

project(vcpkg_parallel_fixture NONE)
