macro(configure_mingw_vcpkg)
  # if mingw, use the correct triplet (otherwise it will fail to link libraries)
  include("${ProjectOptions_SRC_DIR}/DetectCompiler.cmake")
  if(MinGW OR (WIN32 AND "${DETECTED_CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU"))
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
  endif()
endmacro()
