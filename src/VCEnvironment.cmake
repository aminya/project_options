include_guard()

include("${CMAKE_CURRENT_LIST_DIR}/Utilities.cmake")

# detect if the compiler is msvc
function(is_msvc value)
  if(NOT WIN32)
    set(${value}
        OFF
        PARENT_SCOPE)
    return()
  endif()

  if(MSVC
     # if cl specified using -DCMAKE_CXX_COMPILER=cl and -DCMAKE_C_COMPILER=cl
     OR (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" AND CMAKE_C_COMPILER_ID STREQUAL "MSVC")
     OR (CMAKE_CXX_COMPILER MATCHES "^cl(.exe)?$" AND CMAKE_C_COMPILER MATCHES "^cl(.exe)?$"))

    set(${value}
        ON
        PARENT_SCOPE)
    return()
  endif()

  # if the copmiler is unknown by CMake
  if(NOT CMAKE_CXX_COMPILER
     AND NOT CMAKE_C_COMPILER
     AND NOT CMAKE_CXX_COMPILER_ID
     AND NOT CMAKE_C_COMPILER_ID)

    # if cl specified using CC and CXX
    if("$ENV{CXX}" MATCHES "^cl(.exe)?$" AND "$ENV{CC}" MATCHES "^cl(.exe)?$")
      set(${value}
          ON
          PARENT_SCOPE)
      return()
    endif()

    # if cl is inferred by cmake later
    include("${ProjectOptions_SRC_DIR}/DetectCompiler.cmake")
    detect_compiler()

    if((DETECTED_CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" AND DETECTED_CMAKE_C_COMPILER_ID STREQUAL "MSVC"))
      set(${value}
          ON
          PARENT_SCOPE)
      return()
    endif()
  endif()

  set(${value}
      OFF
      PARENT_SCOPE)
endfunction()

# Include msvc toolchain on windows if the generator is not visual studio. Should be called before run_vcpkg and run_conan to be effective
macro(msvc_toolchain)
  if(# if on windows and the generator is not Visual Studio
     WIN32
     AND NOT
         CMAKE_GENERATOR
         MATCHES
         "Visual Studio*")
    is_msvc(_is_msvc)
    if(${_is_msvc})
      # if msvc
      message(STATUS "Using Windows Windows toolchain")
      include(FetchContent)
      FetchContent_Declare(_msvc_toolchain
                           URL "https://github.com/MarkSchofield/WindowsToolchain/archive/refs/tags/v0.5.1.zip")
      FetchContent_MakeAvailable(_msvc_toolchain)
      include("${_msvc_toolchain_SOURCE_DIR}/Windows.MSVC.toolchain.cmake")
      message(STATUS "Setting CXX/C compiler to ${CMAKE_CXX_COMPILER}")
      set(ENV{CXX} ${CMAKE_CXX_COMPILER})
      set(ENV{CC} ${CMAKE_C_COMPILER})
      set(MSVC_FOUND TRUE)
      run_vcvarsall()
    endif()
  endif()
endmacro()

# Run vcvarsall.bat and set CMake environment variables
macro(run_vcvarsall)
  # detect the architecture
  detect_architecture(VCVARSALL_ARCH)

  # If MSVC is being used, and ASAN is enabled, we need to set the debugger environment
  # so that it behaves well with MSVC's debugger, and we can run the target from visual studio
  if(MSVC)
    string(TOUPPER "${VCVARSALL_ARCH}" VCVARSALL_ARCH_UPPER)
    set(VS_DEBUGGER_ENVIRONMENT "PATH=\$(VC_ExecutablePath_${VCVARSALL_ARCH_UPPER});%PATH%")

    get_all_targets(all_targets)
    set_target_properties(${all_targets} PROPERTIES VS_DEBUGGER_ENVIRONMENT "${VS_DEBUGGER_ENVIRONMENT}")
  endif()

  # if msvc_found is set by msvc_toolchain
  # or if MSVC but VSCMD_VER is not set, which means vcvarsall has not run
  if((MSVC_FOUND OR MSVC) AND "$ENV{VSCMD_VER}" STREQUAL "")

    # find vcvarsall.bat
    get_filename_component(MSVC_DIR ${CMAKE_CXX_COMPILER} DIRECTORY)
    find_file(
      VCVARSALL_FILE
      NAMES vcvarsall.bat
      PATHS "${MSVC_DIR}"
            "${MSVC_DIR}/.."
            "${MSVC_DIR}/../.."
            "${MSVC_DIR}/../../../../../../../.."
            "${MSVC_DIR}/../../../../../../.."
      PATH_SUFFIXES "VC/Auxiliary/Build" "Common7/Tools" "Tools")

    if(EXISTS ${VCVARSALL_FILE})
      # run vcvarsall and print the environment variables
      message(STATUS "Running `${VCVARSALL_FILE} ${VCVARSALL_ARCH}` to set up the MSVC environment")

      # make vcvarsall quiet
      set(VSCMD_DEBUG "$ENV{VSCMD_DEBUG}")
      set($ENV{VSCMD_DEBUG} 0)

      execute_process(
        COMMAND
          "cmd" "/c" "${VCVARSALL_FILE}" "${VCVARSALL_ARCH}" "1>NUL" #
          "&&" "call" "echo" "VCVARSALL_ENV_START" # a starting point
          "&" "set" # print the environment variables
        OUTPUT_VARIABLE VCVARSALL_OUTPUT
        ERROR_VARIABLE VCVARSALL_ERROR
        OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_STRIP_TRAILING_WHITESPACE)

      # recover VSCMD_DEBUG variable
      set($ENV{VSCMD_DEBUG} "${VSCMD_DEBUG}")

      if("${VCVARSALL_ERROR}" STREQUAL ""
         AND NOT
             "${VCVARSALL_OUTPUT}"
             STREQUAL
             "")
        # parse the output and get the environment variables string
        find_substring_by_prefix(VCVARSALL_ENV "VCVARSALL_ENV_START" "${VCVARSALL_OUTPUT}")

        # set the environment variables
        set_env_from_string("${VCVARSALL_ENV}")
      else()
        message(WARNING "Failed to parse the vcvarsall output. ${VCVARSALL_ERROR}.\nIgnoring this error")

      endif()

    else()
      message(
        WARNING
          "Could not find `vcvarsall.bat` for automatic MSVC environment preparation. Please manually open the MSVC command prompt and rebuild the project.
      ")
    endif()
  endif()
endmacro()
