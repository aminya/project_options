include_guard()

include("${CMAKE_CURRENT_LIST_DIR}/Utilities.cmake")

#[[.rst:

``check_clang_gnu_driver_on_windows``
===============

Sets ``<output_variable>`` to ``ON`` when the compiler is clang targeting Windows through its *GNU*
command line (``clang++``) rather than through the MSVC one (``clang-cl``).

CMake only sets ``MSVC`` for compilers that emulate the ``cl`` command line, so this configuration
matches neither the "not Windows" nor the ``MSVC`` branch of the usual platform checks and needs
handling of its own.

.. code:: cmake

  check_clang_gnu_driver_on_windows(IS_CLANG_GNU_ON_WINDOWS)

]]
function(check_clang_gnu_driver_on_windows output_variable)
  if("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows"
     AND CMAKE_CXX_COMPILER_ID MATCHES ".*Clang"
     AND NOT MSVC
     AND "${CMAKE_CXX_SIMULATE_ID}" STREQUAL "MSVC"
  )
    set(${output_variable} ON PARENT_SCOPE)
  else()
    set(${output_variable} OFF PARENT_SCOPE)
  endif()
endfunction()

#[[.rst:

``enable_windows_clang_sanitizers``
===============

Apply the extra settings clang's sanitizers need when targeting Windows through the GNU driver.
Called by ``enable_sanitizers()``; you do not need to call it yourself.

.. code:: cmake

  enable_windows_clang_sanitizers(<target> "<list of sanitizers>")

]]
function(enable_windows_clang_sanitizers _project_name SANITIZERS)
  if(NOT "address" IN_LIST SANITIZERS)
    return()
  endif()

  # Windows only has a *shared* ASan runtime (`clang_rt.asan_dynamic-<arch>.dll`), and a shared
  # runtime is required anyway whenever an instrumented DLL is loaded by a host that did not link
  # ASan itself.
  target_compile_options(${_project_name} INTERFACE "-shared-libsan")
  target_link_options(${_project_name} INTERFACE "-shared-libsan")

  # The MSVC STL turns on ASan container annotations as soon as `__SANITIZE_ADDRESS__` is defined and
  # stamps every object with `#pragma detect_mismatch("annotate_vector"/"annotate_string", "1")`.
  # Prebuilt dependencies (vcpkg, Conan, a system SDK) carry "0", so linking against them fails with
  #
  #   lld-link: error: /failifmismatch: mismatch detected for 'annotate_string'
  #
  # Opting out puts both sides on "0". The defines are inert without `__SANITIZE_ADDRESS__`.
  target_compile_definitions(
    ${_project_name} INTERFACE "_DISABLE_VECTOR_ANNOTATION" "_DISABLE_STRING_ANNOTATION"
  )

  # ASan is incompatible with the debug CRT: `msvcp140d.dll` allocates during its static init and
  # frees through the debug heap at teardown, which ASan's interceptors do not own, so every process
  # — down to a hello-world using `std::string` — aborts with "attempting free on address which was
  # not malloc()-ed". Only Debug can be checked here; a multi-config generator picks its runtime at
  # build time.
  if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug" OR "${CMAKE_MSVC_RUNTIME_LIBRARY}" MATCHES "Debug")
    message(
      WARNING
        "clang's address sanitizer does not work against the debug CRT on Windows: the process aborts at exit with \"attempting free on address which was not malloc()-ed\". Use RelWithDebInfo, or set CMAKE_MSVC_RUNTIME_LIBRARY to a non-debug runtime."
    )
  endif()
endfunction()

#[[.rst:

``get_sanitizer_runtime_libraries``
===============

Sets ``<output_variable>`` to the sanitizer runtime files that must sit next to an instrumented
binary for it to start, or to an empty list when the loader resolves them on its own.

Only Windows needs this: the ASan runtime is a DLL found through the standard search order. Copy it
into the output directory of every instrumented executable, for example with

.. code:: cmake

  get_sanitizer_runtime_libraries(SANITIZER_RUNTIME)
  foreach(runtime IN LISTS SANITIZER_RUNTIME)
    add_custom_command(
      TARGET my_exe POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_if_different "${runtime}" "$<TARGET_FILE_DIR:my_exe>"
    )
  endforeach()

]]
function(get_sanitizer_runtime_libraries output_variable)
  set(RUNTIME_LIBRARIES "")

  check_clang_gnu_driver_on_windows(IS_CLANG_GNU_ON_WINDOWS)

  if(IS_CLANG_GNU_ON_WINDOWS)
    detect_architecture(ARCHITECTURE)

    if("${ARCHITECTURE}" STREQUAL "arm64")
      set(ASAN_DLL "clang_rt.asan_dynamic-aarch64.dll")
    else()
      set(ASAN_DLL "clang_rt.asan_dynamic-x86_64.dll")
    endif()

    # `-print-file-name` resolves against the compiler's own library search paths, which is the only
    # dependable way to find the runtime: clang moved it from `lib/windows` to `lib/<triple>` and
    # which layout is installed varies by release. When it cannot resolve the file clang echoes the
    # bare name back, hence the EXISTS check.
    execute_process(
      COMMAND "${CMAKE_CXX_COMPILER}" "-print-file-name=${ASAN_DLL}" OUTPUT_VARIABLE ASAN_PATH
      OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET
    )
    file(TO_CMAKE_PATH "${ASAN_PATH}" ASAN_PATH)

    if(EXISTS "${ASAN_PATH}")
      list(APPEND RUNTIME_LIBRARIES "${ASAN_PATH}")
    endif()
  endif()

  set(${output_variable} "${RUNTIME_LIBRARIES}" PARENT_SCOPE)
endfunction()

# Enable the sanitizers for the given project
function(
  enable_sanitizers
  _project_name
  ENABLE_SANITIZER_ADDRESS
  ENABLE_SANITIZER_LEAK
  ENABLE_SANITIZER_UNDEFINED
  ENABLE_SANITIZER_THREAD
  ENABLE_SANITIZER_MEMORY
  ENABLE_SANITIZER_POINTER_COMPARE
  ENABLE_SANITIZER_POINTER_SUBTRACT
)

  # check if the sanitizers are supported
  check_sanitizers_support(
    SUPPORTS_SANITIZER_ADDRESS
    SUPPORTS_SANITIZER_UNDEFINED
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
    set(SANITIZER_UPPERCASE "${SANITIZER}")
    string(TOUPPER ${SANITIZER} SANITIZER_UPPERCASE)

    if(${ENABLE_SANITIZER_${SANITIZER_UPPERCASE}})
      if(${SUPPORTS_SANITIZER_${SANITIZER_UPPERCASE}})
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

      check_clang_gnu_driver_on_windows(IS_CLANG_GNU_ON_WINDOWS)
      if(IS_CLANG_GNU_ON_WINDOWS)
        enable_windows_clang_sanitizers(${_project_name} "${SANITIZERS}")
      endif()
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
- ``ENABLE_SANITIZER_UNDEFINED``: Undefined behavior sanitizer is supported
- ``ENABLE_SANITIZER_LEAK``: Leak sanitizer is supported
- ``ENABLE_SANITIZER_THREAD``: Thread sanitizer is supported
- ``ENABLE_SANITIZER_MEMORY``: Memory sanitizer is supported
- ``ENABLE_SANITIZER_POINTER_COMPARE``: Pointer compare sanitizer is supported
- ``ENABLE_SANITIZER_POINTER_SUBTRACT``: Pointer subtract sanitizer is supported


.. code:: cmake

  check_sanitizers_support(ENABLE_SANITIZER_ADDRESS
                           ENABLE_SANITIZER_UNDEFINED
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
  ENABLE_SANITIZER_UNDEFINED
  ENABLE_SANITIZER_LEAK
  ENABLE_SANITIZER_THREAD
  ENABLE_SANITIZER_MEMORY
  ENABLE_SANITIZER_POINTER_COMPARE
  ENABLE_SANITIZER_POINTER_SUBTRACT
)
  set(SUPPORTED_SANITIZERS "")
  check_clang_gnu_driver_on_windows(IS_CLANG_GNU_ON_WINDOWS)

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
  elseif(IS_CLANG_GNU_ON_WINDOWS)
    # clang++/clang driving its GNU command line while targeting MSVC. CMake leaves `MSVC` unset for
    # this compiler, so it reaches neither branch above even though clang ships working ASan and
    # UBSan runtimes for the `*-pc-windows-msvc` triple.
    #
    # Leak, thread and memory sanitizers have no Windows runtime, and pointer-compare/subtract are
    # GCC-only, so address and undefined are the whole list.
    list(APPEND SUPPORTED_SANITIZERS "address" "undefined")
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
