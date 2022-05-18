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
macro(configure_mingw_vcpkg)
  # if mingw, use the correct triplet (otherwise it will fail to link libraries)
  include("${ProjectOptions_SRC_DIR}/DetectCompiler.cmake")
  is_mingw(_is_mingw)
  if(${_is_mingw})
    include("${ProjectOptions_SRC_DIR}/Utilities.cmake")
    detect_architecture(_arch)
    string(TOLOWER "${_arch}" _arch)

    # Based on this issue, vcpkg uses MINGW variable https://github.com/microsoft/vcpkg/issues/23607#issuecomment-1071966853
    set(MINGW TRUE)

    # Based on the docs https://github.com/microsoft/vcpkg/blob/master/docs/users/mingw.md (but it doesn't work!)
    set(VCPKG_DEFAULT_TRIPLET
        "${_arch}-mingw-dynamic"
        CACHE STRING "Default triplet for vcpkg" FORCE)
    set(VCPKG_DEFAULT_HOST_TRIPLET
        "${_arch}-mingw-dynamic"
        CACHE STRING "Default target triplet for vcpkg" FORCE)
    set($ENV{VCPKG_DEFAULT_TRIPLET} "${_arch}-mingw-dynamic")
    set($ENV{VCPKG_DEFAULT_HOST_TRIPLET} "${_arch}-mingw-dynamic")

    message(
      STATUS
        "Enabled mingw dynamic toolchain for vcpkg. Make sure that the mingw64/bin directory is on the PATH when running the final executables."
    )
  endif()
endmacro()

# fix unicode and main function entry on mingw
macro(mingw_unicode target)
  is_mingw(_is_mingw)
  if(${_is_mingw})
    target_compile_definitions(${target} INTERFACE "UNICODE" "_UNICODE")
    target_link_options(${target} INTERFACE "-municode")
  endif()
endmacro()
