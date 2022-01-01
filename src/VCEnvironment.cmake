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
              AND ("$ENV{CXX}" MATCHES "^cl(.exe)?$" AND "$ENV{CC}" MATCHES "^cl(.exe)?$"))
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
      FetchContent_Declare(_msvctoolchain URL https://github.com/aminya/Toolchain/archive/refs/tags/2021-dec-11.zip)
      FetchContent_MakeAvailable(_msvctoolchain)
      include("${_msvctoolchain_SOURCE_DIR}/VSWhere.cmake")

      if(NOT CMAKE_VS_VERSION_RANGE)
        set(CMAKE_VS_VERSION_RANGE OFF)
      endif()

      if(NOT CMAKE_VS_VERSION_PRERELEASE)
        set(CMAKE_VS_VERSION_PRERELEASE OFF)
      endif()

      if(NOT CMAKE_VS_PRODUCTS)
        set(CMAKE_VS_PRODUCTS "*")
      endif()

      if(NOT CMAKE_VS_PLATFORM_TOOLSET_HOST_ARCHITECTURE)
        set(CMAKE_VS_PLATFORM_TOOLSET_HOST_ARCHITECTURE x64)
      endif()

      # Find Visual Studio
      #
      findvisualstudio(
        VERSION
        ${CMAKE_VS_VERSION_RANGE}
        PRERELEASE
        ${CMAKE_VS_VERSION_PRERELEASE}
        PRODUCTS
        ${CMAKE_VS_PRODUCTS}
        PROPERTIES
        installationVersion
        VS_INSTALLATION_VERSION
        installationPath
        VS_INSTALLATION_PATH)

      if(NOT VS_INSTALLATION_PATH)
        message(STATUS "Could not find Visual Studio.")
        return()
      endif()

      cmake_path(NORMAL_PATH VS_INSTALLATION_PATH)
      set(VS_MSVC_PATH "${VS_INSTALLATION_PATH}/VC/Tools/MSVC")

      if(NOT VS_PLATFORM_TOOLSET_VERSION)
        file(
          GLOB VS_TOOLSET_VERSIONS
          RELATIVE ${VS_MSVC_PATH}
          ${VS_MSVC_PATH}/*)
        list(
          SORT VS_TOOLSET_VERSIONS
          COMPARE NATURAL
          ORDER DESCENDING)
        list(POP_FRONT VS_TOOLSET_VERSIONS VS_TOOLSET_VERSION)
      endif()

      set(VS_TOOLSET_PATH "${VS_INSTALLATION_PATH}/VC/Tools/MSVC/${VS_TOOLSET_VERSION}")

      # detect the architecture (sets VCVARSALL_ARCH)
      detect_architecture()
      set(CMAKE_VS_PLATFORM_TOOLSET_ARCHITECTURE ${VCVARSALL_ARCH})

      set(CMAKE_CXX_COMPILER
          "${VS_TOOLSET_PATH}/bin/Host${CMAKE_VS_PLATFORM_TOOLSET_HOST_ARCHITECTURE}/${CMAKE_VS_PLATFORM_TOOLSET_ARCHITECTURE}/cl.exe"
      )
      set(CMAKE_C_COMPILER
          "${VS_TOOLSET_PATH}/bin/Host${CMAKE_VS_PLATFORM_TOOLSET_HOST_ARCHITECTURE}/${CMAKE_VS_PLATFORM_TOOLSET_ARCHITECTURE}/cl.exe"
      )
      set(ENV{CXX} ${CMAKE_CXX_COMPILER})
      set(ENV{CC} ${CMAKE_C_COMPILER})
      message(STATUS "Setting CMAKE_CXX_COMPILER to ${CMAKE_CXX_COMPILER}")
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
