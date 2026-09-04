include_guard()
#[[.rst:
``check_libfuzzer_support``
===========================
Check whether the current C++ compiler and linker support LibFuzzer.

The probe compiles and links a minimal ``LLVMFuzzerTestOneInput`` entry point
with ``-fsanitize=fuzzer``. Any existing ``CMAKE_REQUIRED_FLAGS`` and
``CMAKE_REQUIRED_LINK_OPTIONS`` are preserved and included in the probe.

The result is stored in the caller-provided output variable as an internal
CMake cache value and is also set in the caller's normal variable scope.

.. code:: cmake

   check_libfuzzer_support(LIBFUZZER_SUPPORTED)
   if(LIBFUZZER_SUPPORTED)
     # Build LibFuzzer targets.
   endif()
]]
# Check whether the current C++ compiler and linker support LibFuzzer.
function(check_libfuzzer_support output_variable)
  include(CheckCXXSourceCompiles)

  set(_libfuzzer_test_source
      [=[
#include <cstddef>
#include <cstdint>

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t *, std::size_t) {
  return 0;
}
]=]
  )

  set(_libfuzzer_flag "-fsanitize=fuzzer")

  set(_libfuzzer_required_flags "${CMAKE_REQUIRED_FLAGS}")
  if(NOT "${_libfuzzer_required_flags}" STREQUAL "")
    string(APPEND _libfuzzer_required_flags " ")
  endif()
  string(APPEND _libfuzzer_required_flags "${_libfuzzer_flag}")

  set(_libfuzzer_required_link_options "${CMAKE_REQUIRED_LINK_OPTIONS}")
  list(APPEND _libfuzzer_required_link_options "${_libfuzzer_flag}")

  set(CMAKE_REQUIRED_FLAGS "${_libfuzzer_required_flags}")
  set(CMAKE_REQUIRED_LINK_OPTIONS "${_libfuzzer_required_link_options}")

  check_cxx_source_compiles("${_libfuzzer_test_source}" "${output_variable}")
  set(${output_variable} "${${output_variable}}" PARENT_SCOPE)
endfunction()
