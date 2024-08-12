include_guard()

set(ProjectOptions_SRC_DIR "${CMAKE_CURRENT_LIST_DIR}")

# detect clang
function(is_clang value)
  if(clang
     OR ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" AND "${CMAKE_C_COMPILER_ID}" STREQUAL "Clang")
     OR ("${DETECTED_CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" AND "${DETECTED_CMAKE_C_COMPILER_ID}"
                                                                  STREQUAL "Clang")
  )
    set(${value} ON PARENT_SCOPE)
    return()
  endif()

  # if the compiler is unknown by CMake
  if(NOT CMAKE_CXX_COMPILER
     AND NOT CMAKE_C_COMPILER
     AND NOT CMAKE_CXX_COMPILER_ID
     AND NOT CMAKE_C_COMPILER_ID
  )

    # if clang is inferred by cmake later
    include("${ProjectOptions_SRC_DIR}/DetectCompiler.cmake")
    detect_compiler()

    if((DETECTED_CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND DETECTED_CMAKE_C_COMPILER_ID STREQUAL
                                                            "Clang")
    )
      set(${value} ON PARENT_SCOPE)
      return()
    endif()

  endif()

  set(${value} OFF PARENT_SCOPE)
endfunction()

# configure clang toolchain for vcpkg
macro(configure_clang_vcpkg)
  if(WIN32)
    is_clang(_is_clang)
    if(${_is_clang})
      # Disable /utf-8 flag in the vcpkg toolchain file
      # https://github.com/microsoft/vcpkg/blob/e590c2b30c08caf1dd8d612ec602a003f9784b7d/scripts/toolchains/windows.cmake#L68
      message(STATUS "Disabling /utf-8 flag in the vcpkg toolchain file for Clang")
      set(VCPKG_SET_CHARSET_FLAG "OFF" CACHE STRING "Vcpkg set charset flag" FORCE)
    endif()
  endif()
endmacro()
