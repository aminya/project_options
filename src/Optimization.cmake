include_guard()

macro(enable_interprocedural_optimization project_name)
  if(CMAKE_BUILD_TYPE STREQUAL "Release" OR CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    include(CheckIPOSupported)
    check_ipo_supported(RESULT result OUTPUT output)
    is_mingw(_is_mingw)
    if(result AND NOT ${_is_mingw})
      # If a static library of this project is used in another project that does not have `CMAKE_INTERPROCEDURAL_OPTIMIZATION` enabled, a linker error might happen.
      # TODO set this option in `package_project` function.
      message(
        STATUS
          "Interprocedural optimization is enabled. In other projects, linking with the compiled libraries of this project might require `set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)`"
      )
      set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
      set_target_properties(${project_name} PROPERTIES INTERPROCEDURAL_OPTIMIZATION ON)
    else()
      message(WARNING "Interprocedural Optimization is not supported. Not using it. Here is the error log: ${output}")
    endif()
  endif()
endmacro()

macro(enable_native_optimization project_name)
  detect_architecture(_arch)
  if("${_arch}" STREQUAL "x64")
    message(STATUS "Enabling the optimizations specific to the current build machine (less portable)")
    if(MSVC)
      # TODO It seems it only accepts the exact instruction set like AVX https://docs.microsoft.com/en-us/cpp/build/reference/arch-x64
      # target_compile_options(${project_name} INTERFACE /arch:native)
    else()
      target_compile_options(${project_name} INTERFACE -march=native)
    endif()
  endif()
endmacro()

macro(disable_exceptions project_name)
  target_compile_options(${project_name} INTERFACE $<$<CXX_COMPILER_ID:MSVC>:/EHs-c- /D_HAS_EXCEPTIONS=0>)
  target_compile_options(${project_name} INTERFACE $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-fno-exceptions>)
endmacro()

macro(disable_rtti project_name)
  target_compile_options(${project_name} INTERFACE $<$<CXX_COMPILER_ID:MSVC>:/GR->)
  target_compile_options(${project_name} INTERFACE $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-fno-rtti>)
endmacro()