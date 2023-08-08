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
macro(configure_linker _target _linker)
  if(NOT "${_linker}" STREQUAL "")
    test_linker_option(_cxx_supports_linker ${_linker})
    if(_cxx_supports_linker)
      message(TRACE "Using ${_linker} as the linker for ${_target}")
      set(_linker_flag "-fuse-ld=${_linker}")
      target_link_options(${_target} INTERFACE ${_linker_flag})
    else()
      message(
        WARNING "Linker ${_linker} is not supported by the compiler. Using the default linker."
      )
    endif()
  endif()
endmacro()

#[[.rst:

``find_linker``
===============

Find a linker prefering the linkers in this order: sold, mold, lld, gold, the system linker

Output variables:

- ``LINKER``: the linker to use

.. code:: cmake

      find_linker(LINKER)
      # then pass ${LINKER} to project_options(... LINKER ${LINKER} ...)

]]
function(find_linker LINKER)
  find_sold(_PROGRAM_sold)
  if(_PROGRAM_sold)
    set(${LINKER} "sold" PARENT_SCOPE)
    return()
  endif()

  find_mold(_PROGRAM_mold)
  if(_PROGRAM_mold)
    set(${LINKER} "mold" PARENT_SCOPE)
    return()
  endif()

  find_lld(_PROGRAM_lld)
  if(_PROGRAM_lld)
    set(${LINKER} "lld" PARENT_SCOPE)
    return()
  endif()

  find_gold(_PROGRAM_gold)
  if(_PROGRAM_gold)
    set(${LINKER} "gold" PARENT_SCOPE)
    return()
  endif()

  # else, use the default linker
  set(${LINKER} "" PARENT_SCOPE)
endfunction()

function(find_sold PROGRAM_sold)
  if(UNIX AND NOT WIN32)
    find_program(_PROGRAM_sold NAMES "sold")
    if(EXISTS ${_PROGRAM_sold})
      test_linker_option(SUPPORTS_SOLD "sold")
      if(SUPPORTS_SOLD)
        set(${PROGRAM_sold} ${_PROGRAM_sold} PARENT_SCOPE)
        return()
      endif()
    endif()
  endif()
  set(${PROGRAM_sold} OFF PARENT_SCOPE)
endfunction()

function(find_mold PROGRAM_mold)
  if(UNIX AND NOT WIN32)
    find_program(_PROGRAM_MOLD NAMES "mold")
    if(EXISTS ${_PROGRAM_MOLD})
      test_linker_option(SUPPORTS_MOLD "mold")
      if(SUPPORTS_MOLD)
        set(${PROGRAM_mold} ${_PROGRAM_MOLD} PARENT_SCOPE)
        return()
      endif()
    endif()
  endif()
  set(${PROGRAM_mold} OFF PARENT_SCOPE)
endfunction()

function(find_lld PROGRAM_lld)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*"))
    find_program(_PROGRAM_LLD NAMES "lld")
    if(EXISTS ${_PROGRAM_LLD})
      test_linker_option(SUPPORTS_LLD "lld")
      if(SUPPORTS_LLD)
        set(${PROGRAM_lld} ${_PROGRAM_LLD} PARENT_SCOPE)
        return()
      endif()
    endif()
  endif()
  set(${PROGRAM_lld} OFF PARENT_SCOPE)
endfunction()

function(find_gold PROGRAM_gold)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    find_program(_PROGRAM_GOLD NAMES "gold")
    if(EXISTS ${_PROGRAM_GOLD})
      test_linker_option(SUPPORTS_GOLD "gold")
      if(SUPPORTS_GOLD)
        set(${PROGRAM_gold} ${_PROGRAM_GOLD} PARENT_SCOPE)
        return()
      endif()
    endif()
  endif()
  set(${PROGRAM_gold} OFF PARENT_SCOPE)
endfunction()
