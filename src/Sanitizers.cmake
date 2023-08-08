include_guard()

# Enable the sanitizers for the given project
function(
  enable_sanitizers
  _project_name
  ENABLE_SANITIZER_ADDRESS
  ENABLE_SANITIZER_LEAK
  ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
  ENABLE_SANITIZER_THREAD
  ENABLE_SANITIZER_MEMORY
)

  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    set(SANITIZERS "")

    if(${ENABLE_SANITIZER_ADDRESS})
      list(APPEND SANITIZERS "address")
      if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL
                                                  8
      )
        list(APPEND SANITIZERS "pointer-compare" "pointer-subtract")
        message(
          STATUS
            "To enable invalid pointer pairs detection, add detect_invalid_pointer_pairs=2 to the environment variable ASAN_OPTIONS."
        )
      endif()
    endif()

    if(${ENABLE_SANITIZER_LEAK})
      list(APPEND SANITIZERS "leak")
    endif()

    if(${ENABLE_SANITIZER_UNDEFINED_BEHAVIOR})
      list(APPEND SANITIZERS "undefined")
    endif()

    if(${ENABLE_SANITIZER_THREAD})
      if("address" IN_LIST SANITIZERS OR "leak" IN_LIST SANITIZERS)
        message(WARNING "Thread sanitizer does not work with Address and Leak sanitizer enabled")
      else()
        list(APPEND SANITIZERS "thread")
      endif()
    endif()

    if(${ENABLE_SANITIZER_MEMORY} AND CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
      message(
        WARNING
          "Memory sanitizer requires all the code (including libc++) to be MSan-instrumented otherwise it reports false positives"
      )
      if("address" IN_LIST SANITIZERS OR "thread" IN_LIST SANITIZERS OR "leak" IN_LIST SANITIZERS)
        message(
          WARNING "Memory sanitizer does not work with Address, Thread and Leak sanitizer enabled"
        )
      else()
        list(APPEND SANITIZERS "memory")
      endif()
    endif()
  elseif(MSVC)
    if(${ENABLE_SANITIZER_ADDRESS})
      list(APPEND SANITIZERS "address")
    endif()
    if(${ENABLE_SANITIZER_LEAK}
       OR ${ENABLE_SANITIZER_UNDEFINED_BEHAVIOR}
       OR ${ENABLE_SANITIZER_THREAD}
       OR ${ENABLE_SANITIZER_MEMORY}
    )
      message(WARNING "MSVC only supports address sanitizer")
    endif()
  endif()

  list(JOIN SANITIZERS "," LIST_OF_SANITIZERS)

  if(LIST_OF_SANITIZERS)
    if(NOT "${LIST_OF_SANITIZERS}" STREQUAL "")
      if(NOT MSVC)
        target_compile_options(${_project_name} INTERFACE -fsanitize=${LIST_OF_SANITIZERS})
        target_link_options(${_project_name} INTERFACE -fsanitize=${LIST_OF_SANITIZERS})
      else()
        string(FIND "$ENV{PATH}" "$ENV{VSINSTALLDIR}" index_of_vs_install_dir)
        if("${index_of_vs_install_dir}" STREQUAL "-1")
          message(
            SEND_ERROR
              "Using MSVC sanitizers requires setting the MSVC environment before building the project. Please manually open the MSVC command prompt and rebuild the project."
          )
        endif()
        target_compile_options(
          ${_project_name} INTERFACE /fsanitize=${LIST_OF_SANITIZERS} /Zi /INCREMENTAL:NO
        )
        target_link_options(${_project_name} INTERFACE /INCREMENTAL:NO)
      endif()
    endif()
  endif()

endfunction()

#[[.rst:

``check_sanitizers_support``
===============

Detect sanitizers support for compiler.

Note that some sanitizers cannot be enabled together, and this function doesn't check that. You should decide which sanitizers to enable based on your needs.

Output variables:

- ``ENABLE_SANITIZER_ADDRESS``: Address sanitizer is supported
- ``ENABLE_SANITIZER_UNDEFINED_BEHAVIOR``: Undefined behavior sanitizer is supported
- ``ENABLE_SANITIZER_LEAK``: Leak sanitizer is supported
- ``ENABLE_SANITIZER_THREAD``: Thread sanitizer is supported
- ``ENABLE_SANITIZER_MEMORY``: Memory sanitizer is supported


.. code:: cmake

  check_sanitizers_support(ENABLE_SANITIZER_ADDRESS
                           ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
                           ENABLE_SANITIZER_LEAK
                           ENABLE_SANITIZER_THREAD
                           ENABLE_SANITIZER_MEMORY)

  # then pass the sanitizers (e.g. ${ENABLE_SANITIZER_ADDRESS}) to project_options(... ${ENABLE_SANITIZER_ADDRESS} ...)

]]
function(
  check_sanitizers_support
  ENABLE_SANITIZER_ADDRESS
  ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
  ENABLE_SANITIZER_LEAK
  ENABLE_SANITIZER_THREAD
  ENABLE_SANITIZER_MEMORY
)
  set(SANITIZERS "")
  if(NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
    list(APPEND SANITIZERS "address")
    list(APPEND SANITIZERS "undefined")
    list(APPEND SANITIZERS "leak")
    list(APPEND SANITIZERS "thread")
    list(APPEND SANITIZERS "memory")
  elseif(MSVC)
    # or it is MSVC and has run vcvarsall
    string(FIND "$ENV{PATH}" "$ENV{VSINSTALLDIR}" index_of_vs_install_dir)
    if("${index_of_vs_install_dir}" STREQUAL "-1")
      list(APPEND SANITIZERS "address")
    endif()
  endif()

  list(JOIN SANITIZERS "," LIST_OF_SANITIZERS)

  if(LIST_OF_SANITIZERS)
    if(NOT "${LIST_OF_SANITIZERS}" STREQUAL "")
      if("address" IN_LIST SANITIZERS)
        set(${ENABLE_SANITIZER_ADDRESS} "ENABLE_SANITIZER_ADDRESS" PARENT_SCOPE)
      endif()
      if("undefined" IN_LIST SANITIZERS)
        set(${ENABLE_SANITIZER_UNDEFINED_BEHAVIOR} "ENABLE_SANITIZER_UNDEFINED_BEHAVIOR"
            PARENT_SCOPE
        )
      endif()
      if("leak" IN_LIST SANITIZERS)
        set(${ENABLE_SANITIZER_LEAK} "ENABLE_SANITIZER_LEAK" PARENT_SCOPE)
      endif()
      if("thread" IN_LIST SANITIZERS)
        set(${ENABLE_SANITIZER_THREAD} "ENABLE_SANITIZER_THREAD" PARENT_SCOPE)
      endif()
      if("memory" IN_LIST SANITIZERS)
        set(${ENABLE_SANITIZER_MEMORY} "ENABLE_SANITIZER_MEMORY" PARENT_SCOPE)
      endif()
    endif()
  endif()
endfunction()
