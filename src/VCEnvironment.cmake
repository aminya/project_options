include_guard()

include("${ProjectOptions_SRC_DIR}/Utilities.cmake")

macro(find_msvc)
  # Try finding MSVC
  if(# if MSVC is not found by CMake yet,
     NOT MSVC
     AND # if the user has specified cl using -DCMAKE_CXX_COMPILER=cl or -DCMAKE_C_COMPILER=cl
         ((CMAKE_CXX_COMPILER MATCHES "^cl(.exe)?$" AND CMAKE_C_COMPILER MATCHES "^cl(.exe)?$")
          # if the user has specified cl using CC and CXX but not using -DCMAKE_CXX_COMPILER or -DCMAKE_C_COMPILER
          OR (NOT CMAKE_CXX_COMPILER
              AND NOT CMAKE_C_COMPILER
              AND ("$ENV{CXX}" MATCHES "^cl(.exe)?$" AND "$ENV{CC}" MATCHES "^cl(.exe)?$"))
         ))
    message(STATUS "Finding MSVC cl.exe ...")
    include(FetchContent)
    FetchContent_Declare(_msvctoolchain URL "https://github.com/MarkSchofield/Toolchain/archive/cc3855512b884e7a2a52cab086abab3f357e2460.zip")
    FetchContent_MakeAvailable(_msvctoolchain)
    include("${_msvctoolchain_SOURCE_DIR}/Windows.MSVC.toolchain.cmake")
    message(STATUS "Setting CMAKE_CXX_COMPILER to ${CMAKE_CXX_COMPILER}")
    set(ENV{CXX} ${CMAKE_CXX_COMPILER})
    set(ENV{CC} ${CMAKE_C_COMPILER})
    set(MSVC_FOUND TRUE)
    run_vcvarsall()
  endif()
endmacro()

# Run vcvarsall.bat and set CMake environment variables
function(run_vcvarsall)
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

  # if msvc_found is set by find_msvc 
  # or if MSVC but VSCMD_VER is not set, which means vcvarsall has not run
  if(MSVC_FOUND OR (MSVC AND "$ENV{VSCMD_VER}" STREQUAL ""))

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
      execute_process(
        COMMAND
          "cmd" "/c" ${VCVARSALL_FILE} ${VCVARSALL_ARCH} #
          "&&" "call" "echo" "VCVARSALL_ENV_START" #
          "&" "set" #
        OUTPUT_VARIABLE VCVARSALL_OUTPUT
        OUTPUT_STRIP_TRAILING_WHITESPACE)

      # parse the output and get the environment variables string
      find_substring_by_prefix(VCVARSALL_ENV "VCVARSALL_ENV_START" "${VCVARSALL_OUTPUT}")

      # set the environment variables
      set_env_from_string("${VCVARSALL_ENV}")
    else()
      message(
        WARNING
          "Could not find `vcvarsall.bat` for automatic MSVC environment preparation. Please manually open the MSVC command prompt and rebuild the project.
      ")
    endif()
  endif()
endmacro()
