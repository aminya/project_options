include_guard()

include(CheckCXXCompilerFlag)

# Enable the sanitizers for the given project
function(
  enable_hardening
  _project_name
  ENABLE_CONTROL_FLOW_PROTECTION
  ENABLE_STACK_PROTECTION
  ENABLE_OVERFLOW_PROTECTION
  ENABLE_ELF_PROTECTION
  ENABLE_RUNTIME_SYMBOLS_RESOLUTION
)
  set(HARDENING_COMPILE_OPTIONS "")
  set(HARDENING_COMPILE_DEFINITIONS "")
  set(HARDENING_LINK_OPTIONS "")

  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    if(ENABLE_CONTROL_FLOW_PROTECTION OR ENABLE_STACK_PROTECTION OR ENABLE_OVERFLOW_PROTECTION OR ENABLE_ELF_PROTECTION)
      list(APPEND HARDENING_COMPILE_DEFINITIONS _GLIBCXX_ASSERTIONS)
    endif()

    if(${ENABLE_CONTROL_FLOW_PROTECTION} AND CMAKE_SYSTEM_PROCESSOR MATCHES
                                             "([xX]86)|(amd64)|(AMD64)|([xX]86_64)|(i686)"
    )
      check_cxx_compiler_flag("-fcf-protection=full" PROJECT_OPTIONS_HAS_CF_PROTECTION)
      if(PROJECT_OPTIONS_HAS_CF_PROTECTION)
        list(APPEND HARDENING_COMPILE_OPTIONS -fcf-protection=full)
        list(APPEND HARDENING_LINK_OPTIONS -fcf-protection=full)
      endif()
    endif()

    if(${ENABLE_STACK_PROTECTION})
      check_cxx_compiler_flag("-fstack-protector-strong" PROJECT_OPTIONS_HAS_STACK_PROTECTOR)
      if(PROJECT_OPTIONS_HAS_STACK_PROTECTOR)
        list(APPEND HARDENING_COMPILE_OPTIONS -fstack-protector-strong)
      endif()

      set(_enable_stack_clash_protection TRUE)
      if(APPLE)
        # `-fstack-clash-protection` doesn't work on MacOS M1 with clang
        if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64" AND CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
          set(_enable_stack_clash_protection FALSE)
        endif()
      endif()

      if(_enable_stack_clash_protection)
        check_cxx_compiler_flag("-fstack-clash-protection" PROJECT_OPTIONS_HAS_STACK_CLASH_PROTECTION)
        if(PROJECT_OPTIONS_HAS_STACK_CLASH_PROTECTION)
          list(APPEND HARDENING_COMPILE_OPTIONS -fstack-clash-protection)
        endif()
      endif()
    endif()

    if(${ENABLE_OVERFLOW_PROTECTION})
      list(APPEND HARDENING_COMPILE_OPTIONS -Wstrict-overflow=4)

      if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        list(APPEND HARDENING_COMPILE_OPTIONS -Wstringop-overflow=4 -Wformat-overflow=2)
      endif()

      target_compile_options(
        ${_project_name} INTERFACE $<$<CONFIG:Release,RelWithDebInfo>:-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3>
      )
    endif()

    if(${ENABLE_ELF_PROTECTION})
      set_target_properties(${_project_name} PROPERTIES POSITION_INDEPENDENT_CODE ON)
      list(APPEND HARDENING_LINK_OPTIONS -Wl,-z,relro -Wl,-z,noexecstack -Wl,-z,separate-code)
      if(NOT ENABLE_RUNTIME_SYMBOLS_RESOLUTION)
        list(APPEND HARDENING_LINK_OPTIONS -Wl,-z,now)
      endif()
    endif()
  endif()

  if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    if(${ENABLE_CONTROL_FLOW_PROTECTION})
      check_cxx_compiler_flag("/guard:cf" PROJECT_OPTIONS_HAS_GUARD_CF)
      if(PROJECT_OPTIONS_HAS_GUARD_CF)
        list(APPEND HARDENING_COMPILE_OPTIONS /guard:cf)
        list(APPEND HARDENING_LINK_OPTIONS /guard:cf)
      endif()
    endif()

    list(APPEND HARDENING_COMPILE_OPTIONS $<$<CONFIG:Debug>:/RTC1>)

    if(${ENABLE_OVERFLOW_PROTECTION})
      check_cxx_compiler_flag("/sdl" PROJECT_OPTIONS_HAS_SDL)
      if(PROJECT_OPTIONS_HAS_SDL)
        list(APPEND HARDENING_COMPILE_OPTIONS /sdl)
      endif()
    endif()
  endif()

  target_compile_options(
    ${_project_name} INTERFACE $<$<COMPILE_LANGUAGE:CXX>:${HARDENING_COMPILE_OPTIONS}>
                               $<$<COMPILE_LANGUAGE:C>:${HARDENING_COMPILE_OPTIONS}>
  )

  target_compile_definitions(${_project_name} INTERFACE ${HARDENING_COMPILE_DEFINITIONS})

  target_link_options(
    ${_project_name} INTERFACE $<$<COMPILE_LANGUAGE:CXX>:${HARDENING_LINK_OPTIONS}>
    $<$<COMPILE_LANGUAGE:C>:${HARDENING_LINK_OPTIONS}>
  )
endfunction()
