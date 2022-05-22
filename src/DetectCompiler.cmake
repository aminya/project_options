include_guard()

macro(detect_compiler)
  # includes a separate CMakeLists.txt file to detect the CXX/C compilers before project is called
  # Using a separate file ensures that the current scope is not contaminated by the variable
  find_program(CMAKE_EXECUTABLE cmake)
  execute_process(
    COMMAND "${CMAKE_EXECUTABLE}" -S "${ProjectOptions_SRC_DIR}/detect_compiler" -B
            "${CMAKE_CURRENT_BINARY_DIR}/detect_compiler" -G "${CMAKE_GENERATOR}" "--log-level=ERROR" "-Wno-dev"
    OUTPUT_QUIET)

  # parse the detected compilers from the cache
  set(cache_variables
      CMAKE_CXX_COMPILER
      CMAKE_CXX_COMPILER_ID
      CMAKE_C_COMPILER
      CMAKE_C_COMPILER_ID
      CMAKE_SYSTEM_PROCESSOR
      CMAKE_HOST_SYSTEM_PROCESSOR)
  foreach(cache_var ${cache_variables})
    file(STRINGS "${CMAKE_CURRENT_BINARY_DIR}/detect_compiler/CMakeCache.txt" "DETECTED_${cache_var}"
         REGEX "^${cache_var}:STRING=(.*)$")
    string(
      REGEX
      REPLACE "^${cache_var}:STRING=(.*)$"
              "\\1"
              "DETECTED_${cache_var}"
              "${DETECTED_${cache_var}}")
  endforeach()
endmacro()
