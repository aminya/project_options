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
          --inconclusive)
    else()
      # if the user provides a CPPCHECK_OPTIONS with a template specified, it will override this template
      set(CMAKE_CXX_CPPCHECK ${CPPCHECK} --template=${CPPCHECK_TEMPLATE} ${CPPCHECK_OPTIONS})
    endif()

    if(WARNINGS_AS_ERRORS)
      list(APPEND CMAKE_CXX_CPPCHECK --error-exitcode=2)
    endif()

    # C cppcheck
    set(CMAKE_C_CPPCHECK ${CMAKE_CXX_CPPCHECK})

    if(NOT
       "${CMAKE_CXX_STANDARD}"
       STREQUAL
       "")
      set(CMAKE_CXX_CPPCHECK ${CMAKE_CXX_CPPCHECK} --std=c++${CMAKE_CXX_STANDARD})
    endif()

    if(NOT
       "${CMAKE_C_STANDARD}"
       STREQUAL
       "")
      set(CMAKE_C_CPPCHECK ${CMAKE_C_CPPCHECK} --std=c${CMAKE_C_STANDARD})
    endif()

  else()
    message(${WARNING_MESSAGE} "cppcheck requested but executable not found")
  endif()
endmacro()

# Enable static analysis with clang-tidy
macro(enable_clang_tidy)
  find_program(CLANGTIDY clang-tidy)
  if(CLANGTIDY)

    # clang-tidy only works with clang when PCH is enabled
    if((NOT
        CMAKE_CXX_COMPILER_ID
        MATCHES
        ".*Clang"
        OR (NOT
            CMAKE_C_COMPILER_ID
            MATCHES
            ".*Clang"
           )
       )
       AND ${ProjectOptions_ENABLE_PCH})
      message(
        ${WARNING_MESSAGE}
        "clang-tidy cannot be enabled with non-clang compiler and PCH, clang-tidy fails to handle gcc's PCH file. Disabling PCH..."
      )
      set(ProjectOptions_ENABLE_PCH OFF)
    endif()

    # construct the clang-tidy command line
    set(CMAKE_CXX_CLANG_TIDY ${CLANGTIDY} -extra-arg=-Wno-unknown-warning-option)

    # set warnings as errors
    if(WARNINGS_AS_ERRORS)
      list(APPEND CMAKE_CXX_CLANG_TIDY -warnings-as-errors=*)
    endif()

    # C clang-tidy
    set(CMAKE_C_CLANG_TIDY ${CMAKE_CXX_CLANG_TIDY})

    # set C++ standard
    if(NOT
       "${CMAKE_CXX_STANDARD}"
       STREQUAL
       "")
      if("${CMAKE_CXX_CLANG_TIDY_DRIVER_MODE}" STREQUAL "cl")
        set(CMAKE_CXX_CLANG_TIDY ${CMAKE_CXX_CLANG_TIDY} -extra-arg=/std:c++${CMAKE_CXX_STANDARD})
      else()
        set(CMAKE_CXX_CLANG_TIDY ${CMAKE_CXX_CLANG_TIDY} -extra-arg=-std=c++${CMAKE_CXX_STANDARD})
      endif()
    endif()

    # set C standard
    if(NOT
       "${CMAKE_C_STANDARD}"
       STREQUAL
       "")
      if("${CMAKE_C_CLANG_TIDY_DRIVER_MODE}" STREQUAL "cl")
        set(CMAKE_C_CLANG_TIDY ${CMAKE_C_CLANG_TIDY} -extra-arg=/std:c${CMAKE_C_STANDARD})
      else()
        set(CMAKE_C_CLANG_TIDY ${CMAKE_C_CLANG_TIDY} -extra-arg=-std=c${CMAKE_C_STANDARD})
      endif()
    endif()

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
  if(NOT
     "${CMAKE_CXX_CLANG_TIDY}"
     STREQUAL
     "")
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
      PROPERTIES
        VS_GLOBAL_EnableMicrosoftCodeAnalysis false
        VS_GLOBAL_CodeAnalysisRuleSet ""
        VS_GLOBAL_EnableClangTidyCodeAnalysis ""
    )
  endif()
endmacro()

# Disable static analysis for target
macro(target_disable_static_analysis TARGET)
  if(NOT CMAKE_GENERATOR MATCHES "Visual Studio")
    target_disable_clang_tidy(${TARGET})
    target_disable_cpp_check(${TARGET})
  endif()
  target_disable_vs_analysis(${TARGET})
endmacro()
