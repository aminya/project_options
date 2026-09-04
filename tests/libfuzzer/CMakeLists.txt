cmake_minimum_required(VERSION 3.20)

project(project_options_libfuzzer_regression LANGUAGES CXX)

if(NOT DEFINED PROJECT_OPTIONS_ROOT)
  message(FATAL_ERROR "PROJECT_OPTIONS_ROOT must point to the project_options checkout")
endif()

include("${PROJECT_OPTIONS_ROOT}/src/Index.cmake")

if(NOT COMMAND check_libfuzzer_support)
  message(FATAL_ERROR "check_libfuzzer_support() is not available from src/Index.cmake")
endif()

set(CMAKE_REQUIRED_FLAGS "-DPROJECT_OPTIONS_LIBFUZZER_CALLER_FLAG")
set(CMAKE_REQUIRED_LINK_OPTIONS "-Wl,--no-as-needed")

check_libfuzzer_support(PROJECT_OPTIONS_LIBFUZZER_SUPPORTED)

if(NOT DEFINED PROJECT_OPTIONS_LIBFUZZER_SUPPORTED)
  message(FATAL_ERROR "check_libfuzzer_support() did not set its output variable")
endif()

get_property(LIBFUZZER_RESULT_TYPE CACHE PROJECT_OPTIONS_LIBFUZZER_SUPPORTED PROPERTY TYPE)
if(NOT "${LIBFUZZER_RESULT_TYPE}" STREQUAL "INTERNAL")
  message(FATAL_ERROR "check_libfuzzer_support() did not preserve CMake's internal result cache")
endif()

if(NOT "${CMAKE_REQUIRED_FLAGS}" STREQUAL "-DPROJECT_OPTIONS_LIBFUZZER_CALLER_FLAG")
  message(FATAL_ERROR "check_libfuzzer_support() changed CMAKE_REQUIRED_FLAGS")
endif()

if(NOT "${CMAKE_REQUIRED_LINK_OPTIONS}" STREQUAL "-Wl,--no-as-needed")
  message(FATAL_ERROR "check_libfuzzer_support() changed CMAKE_REQUIRED_LINK_OPTIONS")
endif()
