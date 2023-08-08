include_guard()

# Test linker option support
function(test_linker_option output_linker_test linker)
  set(output_linker_test OFF PARENT_SCOPE)
  if(NOT "${linker}" STREQUAL "")
    include(CheckCXXCompilerFlag)

    set(_linker_flag "-fuse-ld=${linker}")

    check_cxx_compiler_flag(${_linker_flag} _cxx_supports_linker)
    if("${_cxx_supports_linker}" STREQUAL "1")
      set(${output_linker_test} ON PARENT_SCOPE)
    else()
      set(${output_linker_test} OFF PARENT_SCOPE)
    endif()
  endif()
endfunction()

# Set the linker to use for the linking phase
macro(configure_linker _project_name _linker)
  if(NOT "${_linker}" STREQUAL "")

    include(CheckCXXCompilerFlag)

    set(_linker_flag "-fuse-ld=${_linker}")

    test_linker_option(_cxx_supports_linker ${_linker})
    if(_cxx_supports_linker)
      message(TRACE "Using ${_linker} as the linker for ${_project_name}")
      target_link_options(${_project_name} INTERFACE ${_linker_flag})
    else()
      message(
        WARNING "Linker ${_linker} is not supported by the compiler. Using the default linker."
      )
    endif()
  endif()
endmacro()

# detect custom linker
function(detect_custom_linker LINKER)
  set(SUPPORTS_LLD OFF)
  set(SUPPORTS_GOLD OFF)
  set(SUPPORTS_MOLD OFF)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*") AND NOT WIN32)
    find_program(PROGRAM_LLD NAMES "lld")
    if(EXISTS ${PROGRAM_LLD})
      test_linker_option(SUPPORTS_LLD "lld")
    endif()
  endif()
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    find_program(PROGRAM_GOLD NAMES "gold")
    if(EXISTS ${PROGRAM_GOLD})
      test_linker_option(SUPPORTS_GOLD "gold")
    endif()
  endif()
  if(UNIX AND NOT WIN32 AND NOT APPLE)
    find_program(PROGRAM_MOLD NAMES "mold")
    if(EXISTS ${PROGRAM_MOLD})
      test_linker_option(SUPPORTS_MOLD "mold")
    endif()
  endif()

  if(SUPPORTS_MOLD)
    set(${LINKER} "mold" PARENT_SCOPE)
  elseif(SUPPORTS_LLD)
    set(${LINKER} "lld" PARENT_SCOPE)
  elseif(SUPPORTS_GOLD)
    set(${LINKER} "gold" PARENT_SCOPE)
  endif()
endfunction()
