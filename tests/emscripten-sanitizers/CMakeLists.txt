cmake_minimum_required(VERSION 3.20)

# Simulate the platform marker with the host compiler; no Emscripten SDK is required.
set(EMSCRIPTEN ON)

include("${CMAKE_CURRENT_LIST_DIR}/../../src/Index.cmake")

project(emscripten_sanitizers_regression LANGUAGES CXX)

project_options(
  ENABLE_SANITIZER_ADDRESS
  ENABLE_SANITIZER_LEAK
  ENABLE_SANITIZER_UNDEFINED
  ENABLE_SANITIZER_THREAD
  ENABLE_SANITIZER_MEMORY
  ENABLE_SANITIZER_POINTER_COMPARE
  ENABLE_SANITIZER_POINTER_SUBTRACT
)

# Direct and repeated calls must honor the same platform guard as project_options().
set(REQUEST_SANITIZERS ON)
enable_sanitizers(
  project_options
  ${REQUEST_SANITIZERS}
  ${REQUEST_SANITIZERS}
  ${REQUEST_SANITIZERS}
  ${REQUEST_SANITIZERS}
  ${REQUEST_SANITIZERS}
  ${REQUEST_SANITIZERS}
  ${REQUEST_SANITIZERS}
)

# Exercise the Clang-only public helper without requiring an Emscripten SDK.
set(_emscripten_sanitizers_saved_compiler_id "${CMAKE_CXX_COMPILER_ID}")
set(CMAKE_CXX_COMPILER_ID Clang)
link_shared_sanitizer(project_options)
set(CMAKE_CXX_COMPILER_ID "${_emscripten_sanitizers_saved_compiler_id}")
enable_sanitizers(
  project_options
  ${REQUEST_SANITIZERS}
  ${REQUEST_SANITIZERS}
  ${REQUEST_SANITIZERS}
  ${REQUEST_SANITIZERS}
  ${REQUEST_SANITIZERS}
  ${REQUEST_SANITIZERS}
  ${REQUEST_SANITIZERS}
)

set(SUPPORT_OUTPUTS
  EMSCRIPTEN_SUPPORTS_SANITIZER_ADDRESS
  EMSCRIPTEN_SUPPORTS_SANITIZER_UNDEFINED
  EMSCRIPTEN_SUPPORTS_SANITIZER_LEAK
  EMSCRIPTEN_SUPPORTS_SANITIZER_THREAD
  EMSCRIPTEN_SUPPORTS_SANITIZER_MEMORY
  EMSCRIPTEN_SUPPORTS_SANITIZER_POINTER_COMPARE
  EMSCRIPTEN_SUPPORTS_SANITIZER_POINTER_SUBTRACT
)
foreach(output_variable IN LISTS SUPPORT_OUTPUTS)
  set(${output_variable} stale)
endforeach()

check_sanitizers_support(${SUPPORT_OUTPUTS})

foreach(output_variable IN LISTS SUPPORT_OUTPUTS)
  if(NOT "${${output_variable}}" STREQUAL "")
    message(
      FATAL_ERROR
      "${output_variable} must be empty when EMSCRIPTEN is set, got '${${output_variable}}'"
    )
  endif()
endforeach()

foreach(property IN ITEMS INTERFACE_COMPILE_OPTIONS INTERFACE_LINK_OPTIONS)
  get_target_property(interface_options project_options ${property})
  if(NOT interface_options OR interface_options STREQUAL "interface_options-NOTFOUND")
    continue()
  endif()

  foreach(option IN LISTS interface_options)
    if(option MATCHES "(^|[-/])fsanitize(=|$)")
      message(FATAL_ERROR "${property} propagated sanitizer option '${option}'")
    elseif(option MATCHES "(^|[-/])shared-libsan(=|$)")
      message(FATAL_ERROR "${property} propagated native shared sanitizer option '${option}'")
    endif()
  endforeach()
endforeach()
