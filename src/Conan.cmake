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

# Run Conan for dependency management
macro(run_conan)
  conan_get_version(_conan_current_version)
  if(_conan_current_version VERSION_GREATER_EQUAL "2.0.0")
    message(FATAL_ERROR
      "ENABLE_CONAN in project_options(...) only supports conan 1.\n"
      "  If you're using conan 2, disable ENABLE_CONAN and use run_conan2(...) before project(...).")
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

    foreach(TYPE ${LIST_OF_BUILD_TYPES})
      message(STATUS "Running Conan for build type '${TYPE}'")

      if("${ProjectOptions_CONAN_PROFILE}" STREQUAL "")
        # Detects current build settings to pass into conan
        conan_cmake_autodetect(settings BUILD_TYPE ${TYPE})
        set(CONAN_SETTINGS SETTINGS ${settings})
        set(CONAN_ENV ENV "CC=${CMAKE_C_COMPILER}" "CXX=${CMAKE_CXX_COMPILER}")
      else()
        # Derive all conan settings from a conan profile
        set(CONAN_SETTINGS PROFILE ${ProjectOptions_CONAN_PROFILE} SETTINGS "build_type=${TYPE}")
        # CONAN_ENV should be redundant, since the profile can set CC & CXX
      endif()

      if("${ProjectOptions_CONAN_PROFILE}" STREQUAL "")
        set(CONAN_DEFAULT_PROFILE "default")
      else()
        set(CONAN_DEFAULT_PROFILE ${ProjectOptions_CONAN_PROFILE})
      endif()
      if("${ProjectOptions_CONAN_BUILD_PROFILE}" STREQUAL "")
        set(CONAN_BUILD_PROFILE ${CONAN_DEFAULT_PROFILE})
      else()
        set(CONAN_BUILD_PROFILE ${ProjectOptions_CONAN_BUILD_PROFILE})
      endif()

      if("${ProjectOptions_CONAN_HOST_PROFILE}" STREQUAL "")
        set(CONAN_HOST_PROFILE ${CONAN_DEFAULT_PROFILE})
      else()
        set(CONAN_HOST_PROFILE ${ProjectOptions_CONAN_HOST_PROFILE})
      endif()

      # PATH_OR_REFERENCE ${CMAKE_SOURCE_DIR} is used to tell conan to process
      # the external "conanfile.py" provided with the project
      # Alternatively a conanfile.txt could be used
      conan_cmake_install(
        PATH_OR_REFERENCE
        ${CMAKE_SOURCE_DIR}
        BUILD
        missing
        # Pass compile-time configured options into conan
        OPTIONS
        ${ProjectOptions_CONAN_OPTIONS}
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

#[[.rst:

``run_conan2``
=============

Install conan 2 and conan 2 dependencies:

.. code:: cmake

  run_conan2()

]]
macro(run_conan2)
  if(CMAKE_VERSION VERSION_LESS "3.24.0")
    message(FATAL_ERROR
      "run_conan2 only supports cmake 3.24+, please update your cmake.\n"
      "  If you're using conan 1, set ENABLE_CONAN using project_options(...) or dynamic_project_options(...) after project().")
  endif()

  conan_get_version(_conan_current_version)
  if(_conan_current_version VERSION_LESS "2.0.5")
    message(FATAL_ERROR
      "run_conan2 only supports conan 2.0.5+, please update your conan.\n"
      "  If you're using conan 1, set ENABLE_CONAN using project_options(...) or dynamic_project_options(...) after project().")
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

  # A workaround from https://github.com/conan-io/cmake-conan/issues/595
  list(APPEND CMAKE_PROJECT_TOP_LEVEL_INCLUDES ${CMAKE_BINARY_DIR}/conan_provider.cmake)
endmacro()
