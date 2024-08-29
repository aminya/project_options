include_guard()

function(_set_language_standard output language)
  foreach(version IN LISTS ARGN)
    if(DEFINED "CMAKE_${language}${version}_STANDARD_COMPILE_OPTION" OR DEFINED "CMAKE_${language}${version}_EXTENSION_COMPILE_OPTION")
      set("${output}" "${version}" PARENT_SCOPE)
      break()
    endif()
  endforeach()
endfunction()

# Set the default copmiler standards if not specified
macro(set_standards)

  # if the default CMAKE_CXX_STANDARD is not set, detect the latest CXX standard supported by the compiler and use it.
  # This is needed for the tools like clang-tidy, cppcheck, etc.
  # Like not having compiler warnings on by default, this fixes another `bad` default for the compilers
  # If someone needs an older standard like c++11 although their compiler supports c++20, they can override this by passing -D CMAKE_CXX_STANDARD=11.
  if("${CMAKE_CXX_STANDARD}" STREQUAL "")
    _set_language_standard(CXX_LATEST_STANDARD CXX 23 20 17 14 11)
    message(
      STATUS
        "The default CMAKE_CXX_STANDARD used by external targets and tools is not set yet. Using the latest supported C++ standard that is ${CXX_LATEST_STANDARD}"
    )
    set(CMAKE_CXX_STANDARD ${CXX_LATEST_STANDARD})
  endif()

  if("${CMAKE_C_STANDARD}" STREQUAL "")
    _set_language_standard(C_LATEST_STANDARD C 23 20 17 11 99 90)
    message(
      STATUS
        "The default CMAKE_C_STANDARD used by external targets and tools is not set yet. Using the latest supported C standard that is ${C_LATEST_STANDARD}"
    )
    set(CMAKE_C_STANDARD ${C_LATEST_STANDARD})
  endif()

  # strongly encouraged to enable this globally to avoid conflicts between
  # -Wpedantic being enabled and -std=c++xx and -std=gnu++xx when compiling with PCH enabled
  if("${CMAKE_CXX_EXTENSIONS}" STREQUAL "")
    set(CMAKE_CXX_EXTENSIONS OFF)
  endif()

  if("${CMAKE_C_EXTENSIONS}" STREQUAL "")
    set(CMAKE_C_EXTENSIONS OFF)
  endif()

endmacro()
