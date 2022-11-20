include_guard()

# detect mingw
function(is_mingw value)
  if(USE_CROSSCOMPILER_MINGW)
    set(${value}
        ON
        PARENT_SCOPE)
    return()
  else()
    if(NOT WIN32 OR MSVC)
      set(${value}
          OFF
          PARENT_SCOPE)
      return()
    endif()
  endif()

  if(MINGW
     OR ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU" AND "${CMAKE_C_COMPILER_ID}" STREQUAL "GNU")
     OR ("${DETECTED_CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU" AND "${DETECTED_CMAKE_C_COMPILER_ID}" STREQUAL "GNU"))
    set(${value}
        ON
        PARENT_SCOPE)
    return()
  endif()

  # if the compiler is unknown by CMake
  if(NOT CMAKE_CXX_COMPILER
     AND NOT CMAKE_C_COMPILER
     AND NOT CMAKE_CXX_COMPILER_ID
     AND NOT CMAKE_C_COMPILER_ID)

    # if mingw is inferred by cmake later
    include("${ProjectOptions_SRC_DIR}/DetectCompiler.cmake")
    detect_compiler()

    if((DETECTED_CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND DETECTED_CMAKE_C_COMPILER_ID STREQUAL "GNU"))
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

# configure mingw toolchain for vcpkg
# if mingw, use the correct triplet (otherwise it will fail to link libraries)
macro(configure_mingw_vcpkg)
  is_mingw(_is_mingw)
  if(${_is_mingw})
    include("${ProjectOptions_SRC_DIR}/Utilities.cmake")
    detect_architecture(_arch)
    string(TOLOWER "${_arch}" _arch)

    # https://github.com/microsoft/vcpkg/blob/4b766c1cd17205e1b768c4fadfd5f867c1d0510e/scripts/buildsystems/vcpkg.cmake#L340
    set(MINGW TRUE)

    # https://github.com/microsoft/vcpkg/blob/7aa1a14c5f5707373b73e909ed6aa12b7bae8ee7/scripts/cmake/vcpkg_common_definitions.cmake#L54
    set(VCPKG_CMAKE_SYSTEM_NAME
        "MinGW"
        CACHE STRING "")
    set(VCPKG_TARGET_IS_MINGW
        TRUE
        CACHE STRING "")

    # choose between static or dynamic
    set(MINGW_LINKAGE)
    if(BUILD_SHARED_LIBS)
      set(MINGW_LINKAGE "dynamic")
      message(
        STATUS
          "Enabled dynamic toolchain for mingw. Make sure that the mingw64/bin directory is on the PATH when running the final executables."
      )
    else()
      set(MINGW_LINKAGE "static")
    endif()

    set(VCPKG_LIBRARY_LINKAGE
        ${MINGW_LINKAGE}
        CACHE STRING "")
    set(VCPKG_CRT_LINKAGE
        ${MINGW_LINKAGE}
        CACHE STRING "")

    # Based on the docs https://github.com/microsoft/vcpkg/blob/master/docs/users/mingw.md (but it doesn't work!)
    set(VCPKG_DEFAULT_TRIPLET
        "${_arch}-mingw-${MINGW_LINKAGE}"
        CACHE STRING "Default triplet for vcpkg")
    set($ENV{VCPKG_DEFAULT_TRIPLET} "${_arch}-mingw-${MINGW_LINKAGE}")
    if(WIN32 AND NOT MSVC)
      set(VCPKG_DEFAULT_HOST_TRIPLET
          "${_arch}-mingw-${MINGW_LINKAGE}"
          CACHE STRING "Default target triplet for vcpkg")
      set($ENV{VCPKG_DEFAULT_HOST_TRIPLET} "${_arch}-mingw-${MINGW_LINKAGE}")
    elseif(CROSSCOMPILING AND HOST_TRIPLET)
      set(VCPKG_DEFAULT_HOST_TRIPLET
          "${HOST_TRIPLET}"
          CACHE STRING "Default target triplet for vcpkg")
      set($ENV{VCPKG_DEFAULT_HOST_TRIPLET} "${HOST_TRIPLET}")
    endif()
  endif()
endmacro()

# corrects the mingw toolchain type after including the vcpkg toolchain
# Requires to be called in the same scope as configure_mingw_vcpkg()
macro(configure_mingw_vcpkg_after)
  if(MINGW)
    set(Z_VCPKG_TARGET_TRIPLET_PLAT mingw-${MINGW_LINKAGE})

    include("${ProjectOptions_SRC_DIR}/Utilities.cmake")
    detect_architecture(_arch)
    string(TOLOWER "${_arch}" _arch)
    if(CROSSCOMPILING AND TARGET_ARCHITECTURE)
      set(Z_VCPKG_TARGET_TRIPLET_ARCH ${TARGET_ARCHITECTURE})
    else()
      set(Z_VCPKG_TARGET_TRIPLET_ARCH ${_arch})
    endif()

    set(VCPKG_TARGET_TRIPLET
        "${Z_VCPKG_TARGET_TRIPLET_ARCH}-${Z_VCPKG_TARGET_TRIPLET_PLAT}"
        CACHE STRING "Vcpkg target triplet (ex. x86-windows)" FORCE)
  endif()
endmacro()

# Add -municode to fix undefined reference to `WinMain'
macro(mingw_unicode)
  is_mingw(_is_mingw)
  if(${_is_mingw})
    include(CheckCXXCompilerFlag)
    check_cxx_compiler_flag("-municode" _cxx_supports_municode)
    if(${_cxx_supports_municode})
      message(STATUS "Enabling Unicode for MinGW in the current project to fix undefined references to WinMain")
      add_compile_definitions("UNICODE" "_UNICODE")
      add_compile_options("-municode")
    endif()
  endif()
endmacro()
