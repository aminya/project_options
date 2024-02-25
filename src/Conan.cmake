include_guard()

function(conan_get_version conan_current_version)
  find_program(conan_command "conan" REQUIRED)
  execute_process(
    COMMAND ${conan_command} --version
    OUTPUT_VARIABLE conan_output
    RESULT_VARIABLE conan_result
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )

  if(conan_result)
    message(FATAL_ERROR "Error when trying to run Conan")
  endif()

  string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" conan_version ${conan_output})
  set(${conan_current_version} ${conan_version} PARENT_SCOPE)
endfunction()

# Run Conan 1 for dependency management
macro(_run_conan1)
  set(options
    DEPRECATED_CALL # For backward compability
  )
  set(one_value_args
    DEPRECATED_PROFILE # For backward compability
  )
  set(multi_value_args
    HOST_PROFILE
    BUILD_PROFILE
    INSTALL_ARGS
    DEPRECATED_OPTIONS # For backward compability
  )
  cmake_parse_arguments(_args "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})

  conan_get_version(_conan_current_version)
  if(_conan_current_version VERSION_GREATER_EQUAL "2.0.0")
    message(FATAL_ERROR
      "ENABLE_CONAN in `project_options(...)` only supports conan 1.\n"
      "  If you're using conan 2, disable ENABLE_CONAN and use `run_conan(...)` before `project(...)`.")
  endif()

  # Download automatically, you can also just copy the conan.cmake file
  if(NOT EXISTS "${CMAKE_BINARY_DIR}/conan.cmake")
    message(STATUS "Downloading conan.cmake from https://github.com/conan-io/cmake-conan")
    file(
      DOWNLOAD "https://raw.githubusercontent.com/conan-io/cmake-conan/0.17.0/conan.cmake"
      "${CMAKE_BINARY_DIR}/conan.cmake"
      EXPECTED_HASH SHA256=3bef79da16c2e031dc429e1dac87a08b9226418b300ce004cc125a82687baeef
      # TLS_VERIFY ON # fails on some systems
    )
  endif()

  set(ENV{CONAN_REVISIONS_ENABLED} 1)
  list(APPEND CMAKE_MODULE_PATH ${CMAKE_BINARY_DIR})
  list(APPEND CMAKE_PREFIX_PATH ${CMAKE_BINARY_DIR})

  include(${CMAKE_BINARY_DIR}/conan.cmake)

  # Add (or remove) remotes as needed
  # conan_add_remote(NAME conan-center URL https://center.conan.io)
  conan_add_remote(
    NAME
    conancenter
    URL
    https://center.conan.io
    INDEX
    0
  )
  conan_add_remote(
    NAME bincrafters URL https://bincrafters.jfrog.io/artifactory/api/conan/public-conan
  )

  if(CONAN_EXPORTED)
    # standard conan installation, in which deps will be defined in conanfile. It is not necessary to call conan again, as it is already running.
    if(EXISTS "${CMAKE_BINARY_DIR}/../conanbuildinfo.cmake")
      include(${CMAKE_BINARY_DIR}/../conanbuildinfo.cmake)
    else()
      message(
        FATAL_ERROR
          "Could not set up conan because \"${CMAKE_BINARY_DIR}/../conanbuildinfo.cmake\" does not exist"
      )
    endif()
    conan_basic_setup()
  else()
    # For multi configuration generators, like VS and XCode
    if(NOT CMAKE_CONFIGURATION_TYPES)
      message(STATUS "Single configuration build!")
      set(LIST_OF_BUILD_TYPES ${CMAKE_BUILD_TYPE})
    else()
      message(STATUS "Multi-configuration build: '${CMAKE_CONFIGURATION_TYPES}'!")
      set(LIST_OF_BUILD_TYPES ${CMAKE_CONFIGURATION_TYPES})
    endif()

    is_verbose(_is_verbose)
    if(NOT ${_is_verbose})
      set(OUTPUT_QUIET "OUTPUT_QUIET")
    else()
      set(OUTPUT_QUIET)
    endif()

    set(_should_detect FALSE)
    if(((NOT _args_DEPRECATED_CALL) AND ((NOT _args_HOST_PROFILE) OR ("auto-cmake" IN_LIST _args_HOST_PROFILE)))
        OR ((_args_DEPRECATED_CALL) AND (NOT _args_DEPRECATED_PROFILE)))
      set(_should_detect TRUE)
      list(REMOVE_ITEM _args_HOST_PROFILE "auto-cmake")
    endif()

    if(NOT _args_DEPRECATED_PROFILE)
      set(CONAN_DEFAULT_PROFILE "default")
    else()
      set(CONAN_DEFAULT_PROFILE ${_args_DEPRECATED_PROFILE})
    endif()

    if(NOT _args_HOST_PROFILE)
      set(CONAN_HOST_PROFILE ${CONAN_DEFAULT_PROFILE})
    else()
      set(CONAN_HOST_PROFILE ${_args_HOST_PROFILE})
    endif()

    if(NOT _args_BUILD_PROFILE)
      set(CONAN_BUILD_PROFILE ${CONAN_DEFAULT_PROFILE})
    else()
      set(CONAN_BUILD_PROFILE ${_args_BUILD_PROFILE})
    endif()

    foreach(_install_args IN LISTS _args_INSTALL_ARGS)
      string(REGEX MATCH "--build=.*" _possible_build_arg "${_install_args}")

      if(_possible_build_arg)
        string(SUBSTRING "${_possible_build_arg}" 8 -1 CONAN_BUILD_ARG)
      endif()
    endforeach()
    if(NOT CONAN_BUILD_ARG)
      set(CONAN_BUILD_ARG "missing")
      set(CONAN_INSTALL_ARGS "")
    else()
      list(REMOVE_ITEM _args_INSTALL_ARGS "--build=${CONAN_BUILD_ARG}")
      set(CONAN_INSTALL_ARGS ${_args_INSTALL_ARGS})
    endif()

    foreach(TYPE ${LIST_OF_BUILD_TYPES})
      message(STATUS "Running Conan for build type '${TYPE}'")

      if(_should_detect)
        # Detects current build settings to pass into conan
        conan_cmake_autodetect(settings BUILD_TYPE ${TYPE})
        set(CONAN_SETTINGS SETTINGS ${settings})
        set(CONAN_ENV ENV "CC=${CMAKE_C_COMPILER}" "CXX=${CMAKE_CXX_COMPILER}")
      elseif(_args_DEPRECATED_CALL)
        # Derive all conan settings from a conan profile
        set(CONAN_SETTINGS PROFILE ${CONAN_DEFAULT_PROFILE} SETTINGS "build_type=${TYPE}")

        # CONAN_ENV should be redundant, since the profile can set CC & CXX
      endif()

      # PATH_OR_REFERENCE ${CMAKE_SOURCE_DIR} is used to tell conan to process
      # the external "conanfile.py" provided with the project
      # Alternatively a conanfile.txt could be used
      conan_cmake_install(
        PATH_OR_REFERENCE
        ${CMAKE_SOURCE_DIR}
        BUILD
        ${CONAN_BUILD_ARG}
        # Pass compile-time configured options into conan
        OPTIONS
        ${CONAN_INSTALL_ARGS}
        # Pass CMake compilers to Conan
        ${CONAN_ENV}
        PROFILE_HOST
        ${CONAN_HOST_PROFILE}
        PROFILE_BUILD
        ${CONAN_BUILD_PROFILE}
        # Pass either autodetected settings or a conan profile
        ${CONAN_SETTINGS}
        ${OUTPUT_QUIET}
      )
    endforeach()
  endif()

endmacro()

# Run Conan 2 for dependency management
macro(_run_conan2)
  set(options)
  set(one_value_args)
  set(multi_value_args
    HOST_PROFILE
    BUILD_PROFILE
    INSTALL_ARGS
  )
  cmake_parse_arguments(_args "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})

  if(CMAKE_VERSION VERSION_LESS "3.24.0")
    message(FATAL_ERROR
      "`run_conan(...)` with conan 2 only supports cmake 3.24+, please update your cmake.\n"
      "  Or you can downgrade your conan to use conan 1.")
  endif()

  conan_get_version(_conan_current_version)
  if(_conan_current_version VERSION_LESS "2.0.5")
    message(FATAL_ERROR
      "`run_conan(...)` with conan 2 only supports conan 2.0.5+, please update your conan.\n"
      "  Or You can downgrade your conan to use conan 1.")
  endif()

  # Download automatically, you can also just copy the conan.cmake file
  if(NOT EXISTS "${CMAKE_BINARY_DIR}/conan_provider.cmake")
    message(STATUS "Downloading conan_provider.cmake from https://github.com/conan-io/cmake-conan")
    file(
      DOWNLOAD "https://raw.githubusercontent.com/conan-io/cmake-conan/f6464d1e13ef7a47c569f5061f9607ea63339d39/conan_provider.cmake"
      "${CMAKE_BINARY_DIR}/conan_provider.cmake"
      EXPECTED_HASH SHA256=0a5eb4afbdd94faf06dcbf82d3244331605ef2176de32c09ea9376e768cbb0fc

      # TLS_VERIFY ON # fails on some systems
    )
  endif()

  if(NOT _args_HOST_PROFILE)
    set(_args_HOST_PROFILE "default;auto-cmake")
  endif()

  if(NOT _args_BUILD_PROFILE)
    set(_args_BUILD_PROFILE "default")
  endif()

  if(NOT _args_INSTALL_ARGS)
    set(_args_INSTALL_ARGS "--build=missing")
  endif()

  set(CONAN_HOST_PROFILE "${_args_HOST_PROFILE}" CACHE STRING "Conan host profile" FORCE)
  set(CONAN_BUILD_PROFILE "${_args_BUILD_PROFILE}" CACHE STRING "Conan build profile" FORCE)
  set(CONAN_INSTALL_ARGS "${_args_INSTALL_ARGS}" CACHE STRING "Command line arguments for conan install" FORCE)

  # A workaround from https://github.com/conan-io/cmake-conan/issues/595
  list(APPEND CMAKE_PROJECT_TOP_LEVEL_INCLUDES "${CMAKE_BINARY_DIR}/conan_provider.cmake")

  # Add this to invoke conan even when there's no find_package in CMakeLists.txt.
  # This helps users get the third-party package names, which is used in later find_package.
  cmake_language(DEFER DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" CALL find_package Git QUIET)
endmacro()

#[[.rst:

``run_conan``
=============

Install conan and conan dependencies:

.. code:: cmake

  run_conan()

.. code:: cmake

  run_conan(
    HOST_PROFILE default auto-cmake
    BUILD_PROFILE default
    INSTALL_ARGS --build=missing
  )

Note that it should be called before defining ``project()``.

Named String:

- Values are semicolon separated, e.g. ``"--build=never;--update;--lockfile-out=''"``.
  However, you can make use of the cmake behaviour that automatically concatenates
  multiple space separated string into a semicolon seperated list, e.g.
  ``--build=never --update --lockfile-out=''``.

-  ``HOST_PROFILE``: (Defaults to ``"default;auto-cmake"``). This option
  sets the host profile used by conan. When ``auto-cmake`` is specified,
  cmake-conan will invoke conan's autodetection mechanism which tries to
  guess the system defaults. If multiple profiles are specified, a
  `compound profile <https://docs.conan.io/2.0/reference/commands/install.html#profiles-settings-options-conf>`_
  will be used - compounded from left to right, where right has the highest priority.

-  ``BUILD_PROFILE``: (Defaults to ``"default"``). This option
  sets the build profile used by conan. If multiple profiles are specified,
  a `compound profile <https://docs.conan.io/2.0/reference/commands/install.html#profiles-settings-options-conf>`_
  will be used - compounded from left to right, where right has the highest priority.

-  ``INSTALL_ARGS``: (Defaults to ``"--build=missing"``). This option
  customizes ``conan install`` command invocation. Note that ``--build``
  must be specified, otherwise conan will revert to its default behaviour.

  - Two arguments are reserved to the dependency provider implementation
    and must not be set: the path to a ``conanfile.txt|.py``, and the output
    format (``--format``).

]]
macro(run_conan)
  conan_get_version(_conan_current_version)

  if(_conan_current_version VERSION_LESS "2.0.0")
    set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY PROJECT_OPTIONS_SHOULD_INVOKE_CONAN1 TRUE)
    set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY PROJECT_OPTIONS_CONAN1_ARGS ${ARGN})
  else()
    _run_conan2(${ARGN})
  endif()
endmacro()