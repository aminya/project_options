include_guard()

include("${CMAKE_CURRENT_LIST_DIR}/Utilities.cmake")

# Enable the sanitizers for the given project
function(
  enable_sanitizers
  _project_name
  ENABLE_SANITIZER_ADDRESS
  ENABLE_SANITIZER_LEAK
  ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
  ENABLE_SANITIZER_THREAD
  ENABLE_SANITIZER_MEMORY
  ENABLE_SANITIZER_POINTER_COMPARE
  ENABLE_SANITIZER_POINTER_SUBTRACT
)

  # check if the sanitizers are supported
  check_sanitizers_support(
    SUPPORTS_SANITIZER_ADDRESS
    SUPPORTS_SANITIZER_UNDEFINED_BEHAVIOR
    SUPPORTS_SANITIZER_LEAK
    SUPPORTS_SANITIZER_THREAD
    SUPPORTS_SANITIZER_MEMORY
    SUPPORTS_SANITIZER_POINTER_COMPARE
    SUPPORTS_SANITIZER_POINTER_SUBTRACT
  )

  # for each sanitizer, check if it is supported and enabled
  set(SANITIZERS "")
  foreach(
    SANITIZER IN
    ITEMS "address"
          "leak"
          "undefined"
          "thread"
          "memory"
          "pointer-compare"
          "pointer-subtract"
  )
    if(${ENABLE_SANITIZER_${SANITIZER}})
      if(${SUPPORTS_SANITIZER_${SANITIZER}})
        list(APPEND SANITIZERS ${SANITIZER})
      else()
        # do not enable the sanitizer if it is not supported
        message(STATUS "${SANITIZER} sanitizer is not supported. Not enabling it.")
      endif()
    endif()
  endforeach()

  # Info on special cases

  # Address sanitizer requires Leak sanitizer to be disabled
  if(${ENABLE_SANITIZER_THREAD} AND "${SUPPORTS_SANITIZER_THREAD}" STREQUAL "ENABLE_SANITIZER_THREAD")
    if("address" IN_LIST SANITIZERS OR "leak" IN_LIST SANITIZERS)
      message(
        WARNING
          "Thread sanitizer does not work with Address or Leak sanitizer enabled. Disabling the thread sanitizer."
      )
      # remove thread sanitizer from the list
      list(REMOVE_ITEM SANITIZERS "thread")
    endif()
  endif()

  # Memory sanitizer requires all the code (including libc++) to be MSan-instrumented otherwise it reports false positives
  if(${ENABLE_SANITIZER_MEMORY} AND "${SUPPORTS_SANITIZER_MEMORY}" STREQUAL "ENABLE_SANITIZER_MEMORY"
     AND CMAKE_CXX_COMPILER_ID MATCHES ".*Clang"
  )
    message(
      STATUS
        "Memory sanitizer requires all the code (including libc++) to be MSan-instrumented otherwise it reports false positives"
    )
    if("address" IN_LIST SANITIZERS OR "thread" IN_LIST SANITIZERS OR "leak" IN_LIST SANITIZERS)
      message(
        WARNING
          "Memory sanitizer does not work with Address, Thread and Leak sanitizer enabled. Disabling the memory sanitizer."
      )
      # remove memory sanitizer from the list
      list(REMOVE_ITEM SANITIZERS "memory")
    endif()
  endif()

  if((${ENABLE_SANITIZER_POINTER_COMPARE} AND "${SUPPORTS_SANITIZER_POINTER_COMPARE}" STREQUAL
                                              "ENABLE_SANITIZER_POINTER_COMPARE")
     OR (${ENABLE_SANITIZER_POINTER_SUBTRACT} AND "${SUPPORTS_SANITIZER_POINTER_SUBTRACT}" STREQUAL
                                                  "ENABLE_SANITIZER_POINTER_SUBTRACT")
  )
    message(
      STATUS
        "To enable invalid pointer pairs detection, add detect_invalid_pointer_pairs=2 to the environment variable ASAN_OPTIONS."
    )
  endif()

  # Join the sanitizers
  list(JOIN SANITIZERS "," LIST_OF_SANITIZERS)

  if(LIST_OF_SANITIZERS AND NOT "${LIST_OF_SANITIZERS}" STREQUAL "")
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
      if(POLICY CMP0141)
        if("${CMAKE_MSVC_DEBUG_INFORMATION_FORMAT}" STREQUAL "" OR "${CMAKE_MSVC_DEBUG_INFORMATION_FORMAT}"
                                                                   STREQUAL "EditAndContinue"
        )
          set_target_properties(${_project_name} PROPERTIES MSVC_DEBUG_INFORMATION_FORMAT ProgramDatabase)
        endif()
      else()
        target_compile_options(${_project_name} INTERFACE /Zi)
      endif()
      target_compile_options(${_project_name} INTERFACE /fsanitize=${LIST_OF_SANITIZERS} /INCREMENTAL:NO)
      target_link_options(${_project_name} INTERFACE /INCREMENTAL:NO)
    endif()
  endif()

endfunction()

#[[.rst:

``check_sanitizers_support``
===============

Detect sanitizers support for compiler. You don't need to call this function directly anymore.

Note that some sanitizers cannot be enabled together, and this function doesn't check that. You should decide which sanitizers to enable based on your needs.

Output variables:

- ``ENABLE_SANITIZER_ADDRESS``: Address sanitizer is supported
- ``ENABLE_SANITIZER_UNDEFINED_BEHAVIOR``: Undefined behavior sanitizer is supported
- ``ENABLE_SANITIZER_LEAK``: Leak sanitizer is supported
- ``ENABLE_SANITIZER_THREAD``: Thread sanitizer is supported
- ``ENABLE_SANITIZER_MEMORY``: Memory sanitizer is supported
- ``ENABLE_SANITIZER_POINTER_COMPARE``: Pointer compare sanitizer is supported
- ``ENABLE_SANITIZER_POINTER_SUBTRACT``: Pointer subtract sanitizer is supported


.. code:: cmake

  check_sanitizers_support(ENABLE_SANITIZER_ADDRESS
                           ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
                           ENABLE_SANITIZER_LEAK
                           ENABLE_SANITIZER_THREAD
                           ENABLE_SANITIZER_MEMORY
                           ENABLE_SANITIZER_POINTER_COMPARE
                           ENABLE_SANITIZER_POINTER_SUBTRACT)

  # then pass the sanitizers (e.g. ${ENABLE_SANITIZER_ADDRESS}) to project_options(... ${ENABLE_SANITIZER_ADDRESS} ...)

]]
function(
  check_sanitizers_support
  ENABLE_SANITIZER_ADDRESS
  ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
  ENABLE_SANITIZER_LEAK
  ENABLE_SANITIZER_THREAD
  ENABLE_SANITIZER_MEMORY
  ENABLE_SANITIZER_POINTER_COMPARE
  ENABLE_SANITIZER_POINTER_SUBTRACT
)
  set(SUPPORTED_SANITIZERS "")
  if(NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Windows" AND (CMAKE_CXX_COMPILER_ID STREQUAL "GNU"
                                                        OR CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
  )
    set(HAS_SANITIZER_SUPPORT ON)

    # Disable gcc sanitizer on some macos according to https://github.com/orgs/Homebrew/discussions/3384#discussioncomment-6264292
    if((CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND APPLE)
      detect_macos_version(MACOS_VERSION)
      if(MACOS_VERSION VERSION_GREATER_EQUAL 13)
        set(HAS_SANITIZER_SUPPORT OFF)
      endif()

      detect_architecture(ARCHITECTURE)
      if(ARCHITECTURE STREQUAL "arm64")
        set(HAS_SANITIZER_SUPPORT OFF)
      endif()
    endif()

    if(HAS_SANITIZER_SUPPORT)
      set(SUPPORTED_SANITIZERS "")
      foreach(
        SANITIZER IN
        ITEMS "address"
              "undefined"
              "leak"
              "thread"
              "memory"
              "pointer-compare"
              "pointer-subtract"
      )
        if((SANITIZER STREQUAL "pointer-compare" OR SANITIZER STREQUAL "pointer-subtract")
           AND (NOT CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_VERSION VERSION_LESS 8)
        )
          # pointer-compare and pointer-subtract are supported only by GCC 8 and later
          continue()
        endif()

        list(APPEND SUPPORTED_SANITIZERS ${SANITIZER})
      endforeach()
    endif()
  elseif(MSVC)
    # or it is MSVC and has run vcvarsall
    string(FIND "$ENV{PATH}" "$ENV{VSINSTALLDIR}" index_of_vs_install_dir)
    if(NOT "${index_of_vs_install_dir}" STREQUAL "-1")
      list(APPEND SUPPORTED_SANITIZERS "address")
    endif()
  endif()

  if(NOT SUPPORTED_SANITIZERS OR "${SUPPORTED_SANITIZERS}" STREQUAL "")
    message(STATUS "No sanitizer is supported for the current platform/compiler")
    return()
  endif()

  # Set the output variables
  foreach(
    SANITIZER IN
    ITEMS "address"
          "undefined"
          "leak"
          "thread"
          "memory"
          "pointer-compare"
          "pointer-subtract"
  )
    set(SANITIZER_UPPERCASE "${SANITIZER}")
    string(TOUPPER ${SANITIZER} SANITIZER_UPPERCASE)

    if(${SANITIZER} IN_LIST SUPPORTED_SANITIZERS)
      set(${ENABLE_SANITIZER_${SANITIZER_UPPERCASE}} "ENABLE_SANITIZER_${SANITIZER_UPPERCASE}" PARENT_SCOPE)
    else()
      set(${ENABLE_SANITIZER_${SANITIZER_UPPERCASE}} "" PARENT_SCOPE)
    endif()
  endforeach()
endfunction()
