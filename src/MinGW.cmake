include_guard()

# detect mingw
function(is_mingw value)
  set(_value OFF)
  if("${MINGW}" STREQUAL "True" OR (WIN32 AND ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU"
                                               OR "${DETECTED_CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")))
    set(_value ON)
  endif()
  set(${value}
      "${_value}"
      PARENT_SCOPE)
endfunction()

# configure mingw toolchain for vcpkg
# if mingw, use the correct triplet (otherwise it will fail to link libraries)
macro(configure_mingw_vcpkg)
  if(WIN32 AND NOT MSVC)

    # detect mingw if not already done
    if(NOT
       "${MINGW}"
       STREQUAL
       "True")
      include("${ProjectOptions_SRC_DIR}/DetectCompiler.cmake")
    endif()

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
      set(VCPKG_DEFAULT_HOST_TRIPLET
          "${_arch}-mingw-${MINGW_LINKAGE}"
          CACHE STRING "Default target triplet for vcpkg")
      set($ENV{VCPKG_DEFAULT_TRIPLET} "${_arch}-mingw-${MINGW_LINKAGE}")
      set($ENV{VCPKG_DEFAULT_HOST_TRIPLET} "${_arch}-mingw-${MINGW_LINKAGE}")
    endif()
  endif()
endmacro()

# corrects the mingw toolchain type after including the vcpkg toolchain
# Requires to be called in the same scope as configure_mingw_vcpkg()
macro(configure_mingw_vcpkg_after)
  if(WIN32 AND MINGW)
    set(Z_VCPKG_TARGET_TRIPLET_PLAT mingw-${MINGW_LINKAGE})

    include("${ProjectOptions_SRC_DIR}/Utilities.cmake")
    detect_architecture(_arch)
    string(TOLOWER "${_arch}" _arch)
    set(Z_VCPKG_TARGET_TRIPLET_ARCH ${_arch})

    set(VCPKG_TARGET_TRIPLET
        "${Z_VCPKG_TARGET_TRIPLET_ARCH}-${Z_VCPKG_TARGET_TRIPLET_PLAT}"
        CACHE STRING "Vcpkg target triplet (ex. x86-windows)" FORCE)
  endif()
endmacro()

# fix unicode and main function entry on mingw
macro(mingw_unicode target)
  is_mingw(_is_mingw)
  if(${_is_mingw})
    include(CheckCXXCompilerFlag)
    check_cxx_compiler_flag("-municode" _cxx_supports_municode)
    if(${_cxx_supports_municode})
      target_compile_definitions(${target} INTERFACE "UNICODE" "_UNICODE")
      target_compile_options(${target} INTERFACE "-municode")
    endif()
  endif()
endmacro()
