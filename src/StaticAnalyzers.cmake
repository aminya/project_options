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
      message(${WARNING_MESSAGE}
              "clang-tidy cannot be enabled with non-clang compiler and PCH, clang-tidy fails to handle gcc's PCH file")
      return()
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

macro(enable_include_what_you_use)
  find_program(INCLUDE_WHAT_YOU_USE include-what-you-use)
  if(INCLUDE_WHAT_YOU_USE)
    set(CMAKE_CXX_INCLUDE_WHAT_YOU_USE ${INCLUDE_WHAT_YOU_USE})
  else()
    message(${WARNING_MESSAGE} "include-what-you-use requested but executable not found")
  endif()
endmacro()
