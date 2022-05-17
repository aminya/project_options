include_guard()

# Set the linker to use for the linking phase
macro(configure_linker project_name linker)
  if(NOT
     "${linker}"
     STREQUAL
     "")

    include(CheckCXXCompilerFlag)

    set(_linker_flag "-fuse-ld=${linker}")

    check_cxx_compiler_flag(${_linker_flag} _cxx_supports_linker)
    if(_cxx_supports_linker)
      target_compile_options(${project_name} INTERFACE ${_linker_flag})
    endif()
  endif()
endmacro()
