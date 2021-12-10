include("${ProjectOptions_SRC_DIR}/Utilities.cmake")

macro(detect_architecture)
  # detect the architecture
  string(TOLOWER "${CMAKE_SYSTEM_PROCESSOR}" CMAKE_SYSTEM_PROCESSOR_LOWER)
  if(CMAKE_SYSTEM_PROCESSOR_LOWER STREQUAL x86 OR CMAKE_SYSTEM_PROCESSOR_LOWER MATCHES "^i[3456]86$")
    set(VCVARSALL_ARCH x86)
  elseif(CMAKE_SYSTEM_PROCESSOR_LOWER STREQUAL x86_64 OR CMAKE_SYSTEM_PROCESSOR_LOWER STREQUAL amd64)
    set(VCVARSALL_ARCH x64)
  elseif(CMAKE_SYSTEM_PROCESSOR_LOWER STREQUAL arm)
    set(VCVARSALL_ARCH arm)
  elseif(CMAKE_SYSTEM_PROCESSOR_LOWER STREQUAL arm64 OR CMAKE_SYSTEM_PROCESSOR_LOWER STREQUAL aarch64)
    set(VCVARSALL_ARCH arm64)
  else()
    if(CMAKE_HOST_SYSTEM_PROCESSOR)
      set(VCVARSALL_ARCH ${CMAKE_HOST_SYSTEM_PROCESSOR})
    else()
      set(VCVARSALL_ARCH x64)
    endif()
      message(
        STATUS "Unkown architecture CMAKE_SYSTEM_PROCESSOR: ${CMAKE_HOST_SYSTEM_PROCESSOR} - using ${VCVARSALL_ARCH}")
  endif()
endmacro()

macro(find_msvc)
  # Try finding MSVC
  if(# if MSVC is not found by CMake yet,
     NOT MSVC
     AND # if the user has specified cl using -DCMAKE_CXX_COMPILER=cl or -DCMAKE_C_COMPILER=cl
         ((CMAKE_CXX_COMPILER MATCHES "^cl(.exe)?$" AND CMAKE_C_COMPILER MATCHES "^cl(.exe)?$")
          # if the user has specified cl using CC and CXX but not using -DCMAKE_CXX_COMPILER or -DCMAKE_C_COMPILER
          OR (NOT CMAKE_CXX_COMPILER
              AND NOT CMAKE_C_COMPILER
              AND ($ENV{CXX} MATCHES "^cl(.exe)?$" AND $ENV{CC} MATCHES "^cl(.exe)?$"))
         ))
    find_program(
      CL_EXECUTABLE
      NAMES cl
      PATHS ${CL_EXECUTABLE})
    if(CL_EXECUTABLE)
      message(STATUS "Setting CMAKE_CXX_COMPILER to ${CL_EXECUTABLE}")
      set(CMAKE_CXX_COMPILER ${CL_EXECUTABLE})
      set(CMAKE_C_COMPILER ${CL_EXECUTABLE})
      set(ENV{CXX} ${CMAKE_CXX_COMPILER})
      set(ENV{CC} ${CMAKE_C_COMPILER})
    else()
      message(STATUS "Finding MSVC cl.exe ...")
      include(FetchContent)
      FetchContent_Declare(_msvctoolchain URL https://github.com/aminya/Toolchain/archive/refs/tags/v0.1.1.zip)
      FetchContent_MakeAvailable(_msvctoolchain)
      include("${_msvctoolchain_SOURCE_DIR}/Windows.MSVC.toolchain.cmake")
      message(STATUS "Setting CMAKE_CXX_COMPILER to ${CMAKE_CXX_COMPILER}")
      set(ENV{CXX} ${CMAKE_CXX_COMPILER})
      set(ENV{CC} ${CMAKE_C_COMPILER})
      set(CL_EXECUTABLE
          ${CMAKE_CXX_COMPILER}
          CACHE INTERNAL "CL_EXECUTABLE")
    endif()
    set(MSVC_FOUND TRUE)
    run_vcvarsall()
  endif()
endmacro()

# Run vcvarsall.bat and set CMake environment variables
macro(run_vcvarsall)
  # if msvc_found is set by find_msvc
  # if MSVC but VSCMD_VER is not set, which means vcvarsall has not run
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
      # detect the architecture (sets VCVARSALL_ARCH)
      detect_architecture()

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
