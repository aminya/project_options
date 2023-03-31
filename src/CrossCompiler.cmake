include_guard()

#[[.rst:

.. include:: ../../docs/src/enable_cross_compiler.md
   :parser: myst_parser.sphinx_

#]]
macro(enable_cross_compiler)
  set(options)
  set(oneValueArgs
      DEFAULT_TRIPLET
      CC
      CXX
      TARGET_ARCHITECTURE
      CROSS_ROOT
      CROSS_TRIPLET
      TOOLCHAIN_FILE)
  set(multiValueArgs)
  cmake_parse_arguments(
    EnableCrossCompiler
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN})

  include("${ProjectOptions_SRC_DIR}/Utilities.cmake")
  detect_architecture(_arch)

  set(_default_triplet ${DEFAULT_TRIPLET})
  if(NOT
     "${EnableCrossCompiler_DEFAULT_TRIPLET}"
     STREQUAL
     "")
    set(_default_triplet ${EnableCrossCompiler_DEFAULT_TRIPLET})
  endif()

  if(DEFINED CMAKE_TOOLCHAIN_FILE OR DEFINED VCPKG_CHAINLOAD_TOOLCHAIN_FILE)
    detect_compiler()
  endif()
  set(_cc ${CMAKE_C_COMPILER})
  set(_cxx ${CMAKE_CXX_COMPILER})
  if(NOT
     "${EnableCrossCompiler_CC}"
     STREQUAL
     "")
    set(_cc ${EnableCrossCompiler_CC})
  endif()
  if(NOT
     "${EnableCrossCompiler_CXX}"
     STREQUAL
     "")
    set(_cxx ${EnableCrossCompiler_CXX})
  endif()

  set(_target_architecture ${TARGET_ARCHITECTURE})
  if(NOT
     "${EnableCrossCompiler_TARGET_ARCHITECTURE}"
     STREQUAL
     "")
    set(_target_architecture ${EnableCrossCompiler_TARGET_ARCHITECTURE})
  endif()

  set(_cross_root ${CROSS_ROOT})
  if(NOT
     "${EnableCrossCompiler_CROSS_ROOT}"
     STREQUAL
     "")
    set(_cross_root ${EnableCrossCompiler_CROSS_ROOT})
  endif()

  set(_cross_triplet ${CROSS_TRIPLET})
  if(NOT
     "${EnableCrossCompiler_CROSS_TRIPLET}"
     STREQUAL
     "")
    set(_cross_triplet ${EnableCrossCompiler_CROSS_TRIPLET})
  endif()

  # detect triplet by compiler (fallback)
  if("${_default_triplet}" STREQUAL "")
    if(_cc MATCHES "x86_64(-w64)?-mingw32-[gc]..?" OR _cxx MATCHES "x86_64(-w64)?-mingw32-[gc]..?")
      set(_default_triplet "x64-mingw-dynamic")
    elseif(_cc MATCHES "i686(-w64)?-mingw32-[gc]..?" OR _cxx MATCHES "i686(-w64)?-mingw32-[gc]..?")
      set(_default_triplet "i686-mingw-dynamic")
    elseif(_cc MATCHES "(gcc-)?arm-linux-gnueabi-[gc]..?" OR _cxx MATCHES "(gcc-)?arm-linux-gnueabi-[gc]..?")
      set(_default_triplet "arm-linux")
    elseif(_cc MATCHES "(gcc-)?arm-linux-gnueabihf-[gc]..?" OR _cxx MATCHES "(gcc-)?arm-linux-gnueabihf-[gc]..?")
      set(_default_triplet "arm-linux")
    elseif(_cc MATCHES "(gcc-)?aarch64-linux-(gnu-)?[gc]..?" OR _cxx MATCHES "(gcc-)?aarch64-linux-(gnu-)?[gc]..?")
      set(_default_triplet "arm64-linux")
    elseif(_cc MATCHES "emcc" OR _cxx MATCHES "em..")
      set(_default_triplet "wasm32-emscripten")
    endif()
  endif()

  # detect compiler and target_architecture by triplet
  if("${_default_triplet}" STREQUAL "x64-mingw-dynamic" OR "${_default_triplet}" STREQUAL "x64-mingw-static")
    if("${_cc}" STREQUAL "")
      set(_cc "x86_64-w64-mingw32-gcc")
    endif()
    if("${_cxx}" STREQUAL "")
      set(_cxx "x86_64-w64-mingw32-g++")
    endif()
    if("${_target_architecture}" STREQUAL "")
      set(_target_architecture "x64")
    endif()
  elseif("${_default_triplet}" STREQUAL "x86-mingw-dynamic" OR "${_default_triplet}" STREQUAL "x86-mingw-static")
    if("${_cc}" STREQUAL "")
      set(_cc "i686-w64-mingw32-gcc")
    endif()
    if("${_cxx}" STREQUAL "")
      set(_cxx "i686-w64-mingw32-g++")
    endif()
    if("${_target_architecture}" STREQUAL "")
      set(_target_architecture "x86")
    endif()
  elseif("${_default_triplet}" STREQUAL "wasm32-emscripten")
    if("${_cc}" STREQUAL "")
      set(_cc "emcc")
    endif()
    if("${_cxx}" STREQUAL "")
      set(_cxx "em++")
    endif()
    if("${_target_architecture}" STREQUAL "")
      set(_target_architecture "wasm32-emscripten")
    endif()
  elseif("${_default_triplet}" STREQUAL "arm64-linux")
    if("${_target_architecture}" STREQUAL "")
      set(_target_architecture "arm64-linux")
    endif()
  elseif("${_default_triplet}" STREQUAL "arm-linux")
    if("${_target_architecture}" STREQUAL "")
      set(_target_architecture "arm-linux")
    endif()
  endif()
  if("${_cc}" STREQUAL "")
    set(_cc $ENV{CC})
  endif()
  if("${_cxx}" STREQUAL "")
    set(_cxx $ENV{CXX})
  endif()

  if("${_target_architecture}" STREQUAL "")
    if(_cc MATCHES "x86_64(-w64)?-mingw32-[gc]..?" OR _cxx MATCHES "x86_64(-w64)?-mingw32-[gc]..?")
      set(_target_architecture "x64")
    elseif(_cc MATCHES "i686(-w64)?-mingw32-[gc]..?" OR _cxx MATCHES "i686(-w64)?-mingw32-[gc]..?")
      set(_target_architecture "x86")
    elseif(_cc MATCHES "emcc" OR _cxx MATCHES "em..")
      set(_target_architecture "wasm32-emscripten")
    else()
      # TODO: check for arm compiler
      message(WARNING "if you are using arm cross-compiler, please set DEFAULT_TRIPLET")
      set(_target_architecture ${_arch})
    endif()
  endif()

  if("${HOST_TRIPLET}" STREQUAL "")
    if(WIN32)
      set(HOST_TRIPLET "${_arch}-windows")
    elseif(APPLE)
      set(HOST_TRIPLET "${_arch}-osx")
    elseif(UNIX AND NOT APPLE)
      set(HOST_TRIPLET "${_arch}-linux")
    endif()
  endif()

  set(USE_CROSSCOMPILER_MINGW)
  set(USE_CROSSCOMPILER_EMSCRIPTEN)
  set(USE_CROSSCOMPILER_ARM_LINUX)
  set(USE_CROSSCOMPILER_ARM64_LINUX)
  set(USE_CROSSCOMPILER_AARCH64_LINUX)
  set(USE_CROSSCOMPILER_ARM_NONE)
  if(_cc MATCHES "(x86_64|i686)(-w64)?-mingw32-[gc]..?" OR _cxx MATCHES "(x86_64|i686)(-w64)?-mingw32-[gc]..?")
    set(MINGW TRUE)
    set(USE_CROSSCOMPILER_MINGW TRUE)
  elseif(_cc MATCHES "emcc" OR _cxx MATCHES "em..")
    set(USE_CROSSCOMPILER_EMSCRIPTEN TRUE)
  elseif(_cc MATCHES "aarch64-linux-gnu-gcc" OR _cxx MATCHES "aarch64-linux-gnu-g\\+\\+")
    set(USE_CROSSCOMPILER_AARCH64_LINUX TRUE)
  elseif(_default_triplet MATCHES "arm64-linux")
    set(USE_CROSSCOMPILER_ARM64_LINUX TRUE)
  elseif(_default_triplet MATCHES "arm-linux")
    set(USE_CROSSCOMPILER_ARM_LINUX TRUE)
  endif()

  set(LIBRARY_LINKAGE)
  if(BUILD_SHARED_LIBS)
    set(LIBRARY_LINKAGE "dynamic")
    if("${_default_triplet}" STREQUAL "x64-mingw-static" OR "${_default_triplet}" STREQUAL "x86-mingw-static")
      message(WARNING "cross-compiler triplet is set to 'static' but BUILD_SHARED_LIBS is enabled")
    endif()
  else()
    if("${_default_triplet}" STREQUAL "x64-mingw-dynamic" OR "${_default_triplet}" STREQUAL "x86-mingw-dynamic")
      set(LIBRARY_LINKAGE "dynamic")
    elseif("${_default_triplet}" STREQUAL "x64-mingw-static" OR "${_default_triplet}" STREQUAL "x86-mingw-static")
      set(LIBRARY_LINKAGE "static")
    else()
      set(LIBRARY_LINKAGE "static")
    endif()
  endif()

  if(_cc MATCHES "x86_64(-w64)?-mingw32-[gc]..?" OR _cxx MATCHES "x86_64(-w64)?-mingw32-[gc]..?")
    if("${_cross_root}" STREQUAL "")
      set(_cross_root "/usr/x86_64-w64-mingw32")
    endif()
    set(MINGW TRUE)
    set(USE_CROSSCOMPILER_MINGW TRUE)
  elseif(_cc MATCHES "i686(-w64)?-mingw32-[gc]..?" OR _cxx MATCHES "i686(-w64)?-mingw32-[gc]..?")
    if("${_cross_root}" STREQUAL "")
      set(_cross_root "/usr/i686-w64-mingw32")
    endif()
    set(MINGW TRUE)
    set(USE_CROSSCOMPILER_MINGW TRUE)
  elseif(_cc MATCHES "(gcc-)?arm-linux-gnueabi-[gc]..?" OR _cxx MATCHES "(gcc-)?arm-linux-gnueabi-[gc]..?")
    if("${_cross_root}" STREQUAL "")
      set(_cross_root "/usr/gcc-arm-linux-gnueabi")
    endif()
    if("${_cross_triplet}" STREQUAL "")
      set(_cross_triplet "arm-linux-gnueabi")
    endif()
  elseif(_cc MATCHES "(gcc-)?arm-linux-gnueabihf-[gc]..?" OR _cxx MATCHES "(gcc-)?arm-linux-gnueabihf-[gc]..?")
    if("${_cross_root}" STREQUAL "")
      set(_cross_root "/usr/gcc-arm-linux-gnueabihf")
    endif()
    if("${_cross_triplet}" STREQUAL "")
      set(_cross_triplet "arm-linux-gnueabihf")
    endif()
  elseif(_cc MATCHES "(gcc-)?aarch64-linux-(gnu-)?[gc]..?" OR _cxx MATCHES "(gcc-)?aarch64-linux-(gnu-)?[gc]..?")
    if("${_cross_root}" STREQUAL "")
      set(_cross_root "/usr/gcc-aarch64-linux-gnu")
    endif()
    if("${_cross_triplet}" STREQUAL "")
      set(_cross_triplet "gcc-aarch64-linux-gnu")
    endif()
    set(USE_CROSSCOMPILER_AARCH64_LINUX TRUE)
  elseif(_cc MATCHES "(gcc-)?arm-none-eabi-[gc]..?" OR _cxx MATCHES "(gcc-)?arm-none-eabi-[gc]..?")
    if("${_cross_root}" STREQUAL "")
      set(_cross_root "/usr/gcc-arm-none-eabi")
    endif()
    if("${_cross_triplet}" STREQUAL "")
      set(_cross_triplet "arm-none-eabi")
    endif()
    set(USE_CROSSCOMPILER_ARM_NONE TRUE)
  endif()
  # TODO: check if path is right, check for header files or something
  if(NOT
     "${_cross_root}"
     STREQUAL
     ""
     AND "${_cross_triplet}" STREQUAL "")
    message(WARNING "CROSS_ROOT (${_cross_root}) is set, but CROSS_TRIPLET is not")
  endif()

  set(CROSS_C ${_cc})
  set(CROSS_CXX ${_cxx})
  set(CROSS_ROOT ${_cross_root})
  set(CROSS_TRIPLET ${_cross_triplet})
  set(DEFAULT_TRIPLET ${_default_triplet})
  set(TARGET_ARCHITECTURE ${_target_architecture})

  if(USE_CROSSCOMPILER_EMSCRIPTEN)
    if(NOT
       "$ENV{EMSCRIPTEN}"
       STREQUAL
       "")
      set(EMSCRIPTEN_ROOT $ENV{EMSCRIPTEN})
    else()
      if(NOT DEFINED EMSCRIPTEN_ROOT)
        include(FetchContent)
        message(STATUS "fetch emscripten repo. ...")
        FetchContent_Declare(
          emscripten
          GIT_REPOSITORY https://github.com/emscripten-core/emscripten
          GIT_TAG main)
        if(NOT emscripten_POPULATED)
          FetchContent_Populate(emscripten)
          set(EMSCRIPTEN_ROOT "${emscripten_SOURCE_DIR}")
        endif()
      endif()
    endif()
    if(NOT
       "$ENV{EMSDK}"
       STREQUAL
       "")
      set(EMSCRIPTEN_PREFIX "$ENV{EMSDK}/upstream/emscripten")
      set(EMSCRIPTEN_ROOT_PATH "$ENV{EMSDK}/upstream/emscripten")
    endif()
    if(NOT DEFINED CMAKE_CROSSCOMPILING_EMULATOR)
      set(CMAKE_CROSSCOMPILING_EMULATOR "$ENV{EMSDK_NODE};--experimental-wasm-threads")
    endif()
  else()
    if(NOT DEFINED CMAKE_TOOLCHAIN_FILE AND NOT DEFINED VCPKG_CHAINLOAD_TOOLCHAIN_FILE)
      set(CMAKE_C_COMPILER ${_cc})
      set(CMAKE_CXX_COMPILER ${_cxx})
    endif()
  endif()

  set(_toolchain_file)
  if(NOT
     "${EnableCrossCompiler_TOOLCHAIN_FILE}"
     STREQUAL
     "")
    set(_toolchain_file ${EnableCrossCompiler_TOOLCHAIN_FILE})
  else()
    get_toolchain_file(_toolchain_file)
  endif()
  set(CROSS_TOOLCHAIN_FILE ${_toolchain_file})
  if(NOT DEFINED CMAKE_TOOLCHAIN_FILE)
    if(NOT DEFINED VCPKG_CHAINLOAD_TOOLCHAIN_FILE)
      set(CMAKE_TOOLCHAIN_FILE ${_toolchain_file})
    else()
      set(CROSS_TOOLCHAIN_FILE ${VCPKG_CHAINLOAD_TOOLCHAIN_FILE})
    endif()
  else()
    set(CROSS_TOOLCHAIN_FILE ${CMAKE_TOOLCHAIN_FILE})
  endif()
  set(CROSSCOMPILING TRUE)

  message(STATUS "enable cross-compiling")
  #message(STATUS "use CMAKE_C_COMPILER: ${CMAKE_C_COMPILER}")
  #message(STATUS "use CMAKE_CXX_COMPILER: ${CMAKE_CXX_COMPILER}")
  if(USE_CROSSCOMPILER_MINGW)
    message(STATUS "use MINGW cross-compiling")
    message(STATUS "use ROOT_PATH: ${CROSS_ROOT}")
  elseif(USE_CROSSCOMPILER_EMSCRIPTEN)
    message(STATUS "use emscripten cross-compiling")
    message(STATUS "use emscripten root: ${EMSCRIPTEN_ROOT}")
    #message(STATUS "use emscripten root (path): ${EMSCRIPTEN_ROOT_PATH}")
    #message(STATUS "EMSCRIPTEN: $ENV{EMSCRIPTEN}")
    #message(STATUS "EMSDK_NODE: $ENV{EMSDK_NODE}")
    #message(STATUS "EMSDK: $ENV{EMSDK}")
    message(STATUS "use emscripten cross-compiler emulator: ${CMAKE_CROSSCOMPILING_EMULATOR}")
  else()
    if(NOT
       "${CROSS_ROOT}"
       STREQUAL
       "")
      message(STATUS "use SYSROOT: ${CROSS_ROOT}")
    endif()
  endif()
  message(STATUS "Target Architecture: ${TARGET_ARCHITECTURE}")
  if(NOT
     "${DEFAULT_TRIPLET}"
     STREQUAL
     "")
    message(STATUS "Default Triplet: ${DEFAULT_TRIPLET}")
  endif()
  message(STATUS "Host Triplet: ${HOST_TRIPLET}")
  if(NOT
     "${CMAKE_TOOLCHAIN_FILE}"
     STREQUAL
     "")
    message(STATUS "Toolchain File: ${CMAKE_TOOLCHAIN_FILE}")
  else()
    if(NOT DEFINED VCPKG_CHAINLOAD_TOOLCHAIN_FILE)
      message(STATUS "Cross-compile Toolchain File (for vcpkg): ${CROSS_TOOLCHAIN_FILE}")
    endif()
  endif()
endmacro()

# Get the toolchain file
function(get_toolchain_file value)
  include("${ProjectOptions_SRC_DIR}/Utilities.cmake")
  detect_architecture(_arch)
  if(DEFINED TARGET_ARCHITECTURE)
    set(_arch ${TARGET_ARCHITECTURE})
  endif()
  if("${_arch}" MATCHES "x64")
    set(_arch "x86_64")
  elseif("${_arch}" MATCHES "x86")
    set(_arch "i686")
  endif()

  if(USE_CROSSCOMPILER_MINGW)
    set(${value}
        ${ProjectOptions_SRC_DIR}/toolchains/${_arch}-w64-mingw32.toolchain.cmake
        PARENT_SCOPE)
  elseif(USE_CROSSCOMPILER_EMSCRIPTEN)
    if(EMSCRIPTEN_ROOT)
      set(${value}
          ${EMSCRIPTEN_ROOT}/cmake/Modules/Platform/Emscripten.cmake
          PARENT_SCOPE)
    else()
      message(ERROR "EMSCRIPTEN_ROOT is not set, please define EMSCRIPTEN_ROOT (emscripten repo)")
    endif()
  elseif(USE_CROSSCOMPILER_AARCH64_LINUX)
    set(${value}
        ${ProjectOptions_SRC_DIR}/toolchains/aarch64-linux.toolchain.cmake
        PARENT_SCOPE)
  elseif(USE_CROSSCOMPILER_ARM_LINUX)
    set(${value}
        ${ProjectOptions_SRC_DIR}/toolchains/arm-linux.toolchain.cmake
        PARENT_SCOPE)
  elseif(USE_CROSSCOMPILER_ARM64_LINUX)
    set(${value}
        ${ProjectOptions_SRC_DIR}/toolchains/arm64-linux.toolchain.cmake
        PARENT_SCOPE)
  elseif(USE_CROSSCOMPILER_ARM_NONE)
    set(${value}
        ${ProjectOptions_SRC_DIR}/toolchains/arm.toolchain.cmake
        PARENT_SCOPE)
  elseif(DEFAULT_TRIPLET MATCHES "arm")
    message(STATUS "Don't forget to provide an cmake-toolchain file (for ${DEFAULT_TRIPLET})")
  endif()
endfunction()
