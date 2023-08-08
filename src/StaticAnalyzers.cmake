include_guard()

# Enable static analysis with Cppcheck
macro(enable_cppcheck CPPCHECK_OPTIONS)
  find_program(CPPCHECK cppcheck)
  if(CPPCHECK)

    if(CMAKE_GENERATOR MATCHES ".*Visual Studio.*")
      set(CPPCHECK_TEMPLATE "vs")
    else()
      set(CPPCHECK_TEMPLATE "gcc")
    endif()

    if("${CPPCHECK_OPTIONS}" STREQUAL "")
      # Enable all warnings that are actionable by the user of this toolset
      # style should enable the other 3, but we'll be explicit just in case
      set(CMAKE_CXX_CPPCHECK
          ${CPPCHECK}
          --template=${CPPCHECK_TEMPLATE}
          --enable=style,performance,warning,portability
          --inline-suppr
          # We cannot act on a bug/missing feature of cppcheck
          --suppress=internalAstError
          # if a file does not have an internalAstError, we get an unmatchedSuppression error
          --suppress=unmatchedSuppression
          --inconclusive
      )
    else()
      # if the user provides a CPPCHECK_OPTIONS with a template specified, it will override this template
      set(CMAKE_CXX_CPPCHECK ${CPPCHECK} --template=${CPPCHECK_TEMPLATE} ${CPPCHECK_OPTIONS})
    endif()

    if(WARNINGS_AS_ERRORS)
      list(APPEND CMAKE_CXX_CPPCHECK --error-exitcode=2)
    endif()

    # C cppcheck
    set(CMAKE_C_CPPCHECK ${CMAKE_CXX_CPPCHECK})

    if(NOT "${CMAKE_CXX_STANDARD}" STREQUAL "")
      set(CMAKE_CXX_CPPCHECK ${CMAKE_CXX_CPPCHECK} --std=c++${CMAKE_CXX_STANDARD})
    endif()

    if(NOT "${CMAKE_C_STANDARD}" STREQUAL "")
      set(CMAKE_C_CPPCHECK ${CMAKE_C_CPPCHECK} --std=c${CMAKE_C_STANDARD})
    endif()

  else()
    message(${WARNING_MESSAGE} "cppcheck requested but executable not found")
  endif()
endmacro()

function(_enable_clang_tidy_setup_cl CXX_FLAGS C_FLAGS)
  set(CLANG_TIDY_CXX_FLAGS ${CXX_FLAGS})
  set(CLANG_TIDY_C_FLAGS ${C_FLAGS})

  if(CMAKE_CXX_STANDARD)
    list(APPEND CLANG_TIDY_CXX_FLAGS -extra-arg=/std:c++${CMAKE_CXX_STANDARD})
  endif()

  if(CMAKE_C_STANDARD)
    list(APPEND CLANG_TIDY_C_FLAGS -extra-arg=/std:c${CMAKE_C_STANDARD})
  endif()

  set(CLANG_TIDY_CXX_FLAGS ${CLANG_TIDY_CXX_FLAGS} PARENT_SCOPE)
  set(CLANG_TIDY_C_FLAGS ${CLANG_TIDY_C_FLAGS} PARENT_SCOPE)
endfunction()

function(_enable_clang_tidy_setup_cross CXX_FLAGS C_FLAGS)
  set(CLANG_TIDY_CXX_FLAGS ${CXX_FLAGS})
  set(CLANG_TIDY_C_FLAGS ${C_FLAGS})

  # Get GCC default flags
  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    execute_process(
      COMMAND "${CMAKE_CXX_COMPILER}" "-v" ERROR_VARIABLE CLANG_TIDY_CXX_FLAGS_COMPILER_DEFAULT
                                                          COMMAND_ERROR_IS_FATAL ANY
    )
    execute_process(
      COMMAND "${CMAKE_CXX_COMPILER}" "-dumpmachine"
      OUTPUT_VARIABLE CLANG_TIDY_CXX_FLAGS_COMPILER_TARGET COMMAND_ERROR_IS_FATAL ANY
    )

    string(STRIP "${CLANG_TIDY_CXX_FLAGS_COMPILER_TARGET}" CLANG_TIDY_CXX_FLAGS_COMPILER_TARGET)
    set(CLANG_TIDY_CXX_FLAGS_COMPILER_TARGET "--target=${CLANG_TIDY_CXX_FLAGS_COMPILER_TARGET}")
  endif()

  if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    execute_process(
      COMMAND "${CMAKE_C_COMPILER}" "-v" ERROR_VARIABLE CLANG_TIDY_C_FLAGS_COMPILER_DEFAULT
                                                        COMMAND_ERROR_IS_FATAL ANY
    )
    execute_process(
      COMMAND "${CMAKE_C_COMPILER}" "-dumpmachine"
      OUTPUT_VARIABLE CLANG_TIDY_C_FLAGS_COMPILER_TARGET COMMAND_ERROR_IS_FATAL ANY
    )

    string(STRIP "${CLANG_TIDY_C_FLAGS_COMPILER_TARGET}" CLANG_TIDY_C_FLAGS_COMPILER_TARGET)
    set(CLANG_TIDY_C_FLAGS_COMPILER_TARGET "--target=${CLANG_TIDY_C_FLAGS_COMPILER_TARGET}")
  endif()

  set(CLANG_TIDY_CXX_FLAGS_COMPILER ${CLANG_TIDY_CXX_FLAGS_COMPILER_TARGET})
  set(CLANG_TIDY_C_FLAGS_COMPILER ${CLANG_TIDY_C_FLAGS_COMPILER_TARGET})

  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_C_COMPILER_ID STREQUAL "GNU")
    # Extract sysroot from GCC default flags
    if(CMAKE_SYSROOT STREQUAL "")
      string(REGEX MATCH "--with-sysroot=[^\n\r ]+" CLANG_TIDY_CXX_FLAGS_COMPILER_DEFAULT
                   "${CLANG_TIDY_CXX_FLAGS_COMPILER_DEFAULT}"
      )
      string(REGEX MATCH "--with-sysroot=[^\n\r ]+" CLANG_TIDY_C_FLAGS_COMPILER_DEFAULT
                   "${CLANG_TIDY_C_FLAGS_COMPILER_DEFAULT}"
      )
      string(REPLACE "with-" "" CLANG_TIDY_CXX_FLAGS_COMPILER_DEFAULT
                     "${CLANG_TIDY_CXX_FLAGS_COMPILER_DEFAULT}"
      )
      string(REPLACE "with-" "" CLANG_TIDY_C_FLAGS_COMPILER_DEFAULT
                     "${CLANG_TIDY_C_FLAGS_COMPILER_DEFAULT}"
      )
      list(APPEND CLANG_TIDY_CXX_FLAGS_COMPILER ${CLANG_TIDY_CXX_FLAGS_COMPILER_DEFAULT})
      list(APPEND CLANG_TIDY_C_FLAGS_COMPILER ${CLANG_TIDY_C_FLAGS_COMPILER_DEFAULT})
    endif()
  endif()

  # Sanitize
  list(TRANSFORM CLANG_TIDY_CXX_FLAGS_COMPILER REPLACE "--extra-arg=" "")
  list(TRANSFORM CLANG_TIDY_C_FLAGS_COMPILER REPLACE "--extra-arg=" "")
  list(TRANSFORM CLANG_TIDY_CXX_FLAGS_COMPILER REPLACE "-extra-arg=" "")
  list(TRANSFORM CLANG_TIDY_C_FLAGS_COMPILER REPLACE "-extra-arg=" "")

  # Add extra-arg to all compiler options
  list(TRANSFORM CLANG_TIDY_CXX_FLAGS_COMPILER PREPEND "-extra-arg=")
  list(TRANSFORM CLANG_TIDY_C_FLAGS_COMPILER PREPEND "-extra-arg=")

  list(APPEND CLANG_TIDY_CXX_FLAGS ${CLANG_TIDY_CXX_FLAGS_COMPILER})
  list(APPEND CLANG_TIDY_C_FLAGS ${CLANG_TIDY_C_FLAGS_COMPILER})

  set(CLANG_TIDY_CXX_FLAGS ${CLANG_TIDY_CXX_FLAGS} PARENT_SCOPE)
  set(CLANG_TIDY_C_FLAGS ${CLANG_TIDY_C_FLAGS} PARENT_SCOPE)
endfunction()

function(_enable_clang_tidy_setup CXX_FLAGS C_FLAGS)
  set(CLANG_TIDY_CXX_FLAGS ${CXX_FLAGS})
  set(CLANG_TIDY_C_FLAGS ${C_FLAGS})

  if(CMAKE_CXX_STANDARD)
    if(CMAKE_CXX_EXTENSIONS)
      list(APPEND CLANG_TIDY_CXX_FLAGS -extra-arg=-std=gnu++${CMAKE_CXX_STANDARD})
    else()
      list(APPEND CLANG_TIDY_CXX_FLAGS -extra-arg=-std=c++${CMAKE_CXX_STANDARD})
    endif()
  endif()

  if(CMAKE_C_STANDARD)
    if(CMAKE_C_EXTENSIONS)
      list(APPEND CLANG_TIDY_C_FLAGS -extra-arg=-std=gnu${CMAKE_C_STANDARD})
    else()
      list(APPEND CLANG_TIDY_C_FLAGS -extra-arg=-std=c${CMAKE_C_STANDARD})
    endif()
  endif()

  if(CMAKE_CROSSCOMPILING)
    _enable_clang_tidy_setup_cross("${CLANG_TIDY_CXX_FLAGS}" "${CLANG_TIDY_C_FLAGS}")
  endif()

  list(APPEND CLANG_TIDY_CXX_FLAGS ${CLANG_TIDY_CXX_FLAGS_COMPILER})
  list(APPEND CLANG_TIDY_C_FLAGS ${CLANG_TIDY_C_FLAGS_COMPILER})

  set(CLANG_TIDY_CXX_FLAGS ${CLANG_TIDY_CXX_FLAGS} PARENT_SCOPE)
  set(CLANG_TIDY_C_FLAGS ${CLANG_TIDY_C_FLAGS} PARENT_SCOPE)
endfunction()

# Enable static analysis with clang-tidy
macro(enable_clang_tidy CLANG_TIDY_EXTRA_ARGUMENTS)
  find_program(CLANGTIDY clang-tidy)
  if(CLANGTIDY)

    # clang-tidy only works with clang when PCH is enabled
    if((NOT CMAKE_CXX_COMPILER_ID MATCHES ".*Clang" OR (NOT CMAKE_C_COMPILER_ID MATCHES ".*Clang"))
       AND ${ProjectOptions_ENABLE_PCH}
    )
      message(
        ${WARNING_MESSAGE}
        "clang-tidy cannot be enabled with non-clang compiler and PCH, clang-tidy fails to handle gcc's PCH file. Disabling PCH..."
      )
      set(ProjectOptions_ENABLE_PCH OFF)
    endif()

    # Generic flags
    set(CLANG_TIDY_CXX_FLAGS "-extra-arg=-Wno-unknown-warning-option")
    set(CLANG_TIDY_C_FLAGS "-extra-arg=-Wno-unknown-warning-option")

    # set warnings as errors
    if(WARNINGS_AS_ERRORS)
      list(APPEND CLANG_TIDY_CXX_FLAGS -warnings-as-errors=*)
      list(APPEND CLANG_TIDY_C_FLAGS -warnings-as-errors=*)
    endif()

    if("${CMAKE_CXX_CLANG_TIDY_DRIVER_MODE}" STREQUAL "cl" OR "${CMAKE_C_CLANG_TIDY_DRIVER_MODE}"
                                                              STREQUAL "cl"
    )
      _enable_clang_tidy_setup_cl("${CLANG_TIDY_CXX_FLAGS}" "${CLANG_TIDY_C_FLAGS}")
    else()
      _enable_clang_tidy_setup("${CLANG_TIDY_CXX_FLAGS}" "${CLANG_TIDY_C_FLAGS}")
    endif()

    # C++ clang-tidy
    set(CMAKE_CXX_CLANG_TIDY ${CLANGTIDY} ${CLANG_TIDY_CXX_FLAGS} ${CLANG_TIDY_EXTRA_ARGUMENTS})
    # C clang-tidy
    set(CMAKE_C_CLANG_TIDY ${CLANGTIDY} ${CLANG_TIDY_C_FLAGS} ${CLANG_TIDY_EXTRA_ARGUMENTS})
  else()
    message(${WARNING_MESSAGE} "clang-tidy requested but executable not found")
  endif()
endmacro()

# Enable static analysis inside Visual Studio IDE
macro(enable_vs_analysis VS_ANALYSIS_RULESET)
  if("${VS_ANALYSIS_RULESET}" STREQUAL "")
    # See for other rulesets: C:\Program Files (x86)\Microsoft Visual Studio\20xx\xx\Team Tools\Static Analysis Tools\Rule Sets\
    set(VS_ANALYSIS_RULESET "AllRules.ruleset")
  endif()
  if(NOT "${CMAKE_CXX_CLANG_TIDY}" STREQUAL "")
    set(_VS_CLANG_TIDY "true")
  else()
    set(_VS_CLANG_TIDY "false")
  endif()
  if(CMAKE_GENERATOR MATCHES "Visual Studio")
    get_all_targets(_targets_list)
    foreach(target IN LISTS ${_targets_list})
      set_target_properties(
        ${target}
        PROPERTIES
          VS_GLOBAL_EnableMicrosoftCodeAnalysis true
          VS_GLOBAL_CodeAnalysisRuleSet "${VS_ANALYSIS_RULESET}"
          VS_GLOBAL_EnableClangTidyCodeAnalysis "${_VS_CLANG_TIDY}"
          # TODO(disabled) This is set to false deliberately. The compiler warnings are already given in the CompilerWarnings.cmake file
          # VS_GLOBAL_RunCodeAnalysis false
      )
    endforeach()
  endif()
endmacro()

# Enable static analysis with include-what-you-use
macro(enable_include_what_you_use)
  find_program(INCLUDE_WHAT_YOU_USE include-what-you-use)
  if(INCLUDE_WHAT_YOU_USE)
    set(CMAKE_CXX_INCLUDE_WHAT_YOU_USE ${INCLUDE_WHAT_YOU_USE})
  else()
    message(${WARNING_MESSAGE} "include-what-you-use requested but executable not found")
  endif()
endmacro()

# Enable static analysis inside GCC
macro(enable_gcc_analyzer _project_name GCC_ANALYZER_EXTRA_ARGUMENTS)
  # gcc analyzer only works with GCC 10 and only for the C language
  if(NOT CMAKE_C_COMPILER_ID STREQUAL "GNU" OR (CMAKE_C_COMPILER_ID STREQUAL "GNU"
                                                AND CMAKE_C_COMPILER_VERSION VERSION_LESS "10")
  )
    message(
      ${WARNING_MESSAGE}
      "gcc analyzer cannot be enabled with non-gcc and any language other than C or with a gcc of version lower than 10"
    )
  else()
    set(_gcc_analyzer_flags -fanalyzer ${GCC_ANALYZER_EXTRA_ARGUMENTS})

    target_compile_options(
      ${_project_name} INTERFACE $<$<COMPILE_LANGUAGE:C>:${_gcc_analyzer_flags}>
    )
  endif()
endmacro()

# Disable clang-tidy for target
macro(target_disable_clang_tidy TARGET)
  find_program(CLANGTIDY clang-tidy)
  if(CLANGTIDY)
    set_target_properties(${TARGET} PROPERTIES C_CLANG_TIDY "")
    set_target_properties(${TARGET} PROPERTIES CXX_CLANG_TIDY "")
  endif()
endmacro()

# Disable cppcheck for target
macro(target_disable_cpp_check TARGET)
  find_program(CPPCHECK cppcheck)
  if(CPPCHECK)
    set_target_properties(${TARGET} PROPERTIES C_CPPCHECK "")
    set_target_properties(${TARGET} PROPERTIES CXX_CPPCHECK "")
  endif()
endmacro()

# Disable vs analysis for target
macro(target_disable_vs_analysis TARGET)
  if(CMAKE_GENERATOR MATCHES "Visual Studio")
    set_target_properties(
      ${TARGET}
      PROPERTIES VS_GLOBAL_EnableMicrosoftCodeAnalysis false VS_GLOBAL_CodeAnalysisRuleSet ""
                 VS_GLOBAL_EnableClangTidyCodeAnalysis ""
    )
  endif()
endmacro()

# Disable include-what-you-use for target
macro(target_disable_include_what_you_use TARGET)
  find_program(INCLUDE_WHAT_YOU_USE include-what-you-use)
  if(INCLUDE_WHAT_YOU_USE)
    set_target_properties(${TARGET} PROPERTIES C_INCLUDE_WHAT_YOU_USE "")
    set_target_properties(${TARGET} PROPERTIES CXX_INCLUDE_WHAT_YOU_USE "")
  endif()
endmacro()

# Disable gcc analyzer for target
macro(target_disable_gcc_analyzer TARGET)
  if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    get_target_property(_compile_options ${TARGET} INTERFACE_COMPILE_OPTIONS)
    if(_compile_options)
      string(REGEX REPLACE "-fanalyzer|-Wanalyzer-[0-9a-zA-Z-]+" ""
                           _compile_options_no_gcc_analyzer "${_compile_options}"
      )
      set_target_properties(
        ${TARGET} PROPERTIES INTERFACE_COMPILE_OPTIONS "${_compile_options_no_gcc_analyzer}"
      )
    endif()
    get_target_property(_compile_options ${TARGET} COMPILE_OPTIONS)
    if(_compile_options)
      string(REGEX REPLACE "-fanalyzer|-Wanalyzer-[0-9a-zA-Z-]+" ""
                           _compile_options_no_gcc_analyzer "${_compile_options}"
      )
      set_target_properties(
        ${TARGET} PROPERTIES COMPILE_OPTIONS "${_compile_options_no_gcc_analyzer}"
      )
    endif()
  endif()
endmacro()

#[[.rst:

``target_disable_static_analysis``
==================================

This function disables static analysis for the given target:

.. code:: cmake

   target_disable_static_analysis(some_external_target)

There is also individual functions to disable a specific analysis for
the target:

-  ``target_disable_cpp_check(target)``
-  ``target_disable_vs_analysis(target)``
-  ``target_disable_clang_tidy(target)``
-  ``target_disable_include_what_you_use(target)``
-  ``target_disable_gcc_analyzer(target)``


]]
macro(target_disable_static_analysis TARGET)
  if(NOT CMAKE_GENERATOR MATCHES "Visual Studio")
    target_disable_clang_tidy(${TARGET})
    target_disable_cpp_check(${TARGET})
    target_disable_gcc_analyzer(${TARGET})
  endif()
  target_disable_vs_analysis(${TARGET})
  target_disable_include_what_you_use(${TARGET})
endmacro()
