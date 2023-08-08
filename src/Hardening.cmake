include_guard()

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
  set(HARDENING_LINK_OPTIONS "")

  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    if(${ENABLE_CONTROL_FLOW_PROTECTION} AND CMAKE_SYSTEM_PROCESSOR MATCHES
                                             "([xX]86)|(amd64)|(AMD64)|([xX]86_64)|(i686)"
    )
      list(APPEND HARDENING_COMPILE_OPTIONS -fcf-protection=full)
      list(APPEND HARDENING_LINK_OPTIONS -fcf-protection=full)
    endif()

    if(${ENABLE_STACK_PROTECTION})
      set(_enable_stack_clash_protection TRUE)
      if(APPLE)
        # `-fstack-clash-protection` doesn't work on MacOS M1 with clang
        if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64" AND CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
          set(_enable_stack_clash_protection FALSE)
        endif()
      endif()

      if(_enable_stack_clash_protection)
        list(APPEND HARDENING_COMPILE_OPTIONS -fstack-clash-protection)
      endif()

      list(APPEND HARDENING_COMPILE_OPTIONS -fstack-protector-strong)
    endif()

    if(${ENABLE_OVERFLOW_PROTECTION})
      list(APPEND HARDENING_COMPILE_OPTIONS -Wstrict-overflow=4)

      if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        list(APPEND HARDENING_COMPILE_OPTIONS -Wstringop-overflow=4 -Wformat-overflow=2)
      endif()

      if(CMAKE_BUILD_TYPE STREQUAL "Release" OR CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
        target_compile_definitions(${_project_name} INTERFACE _FORTIFY_SOURCE=3)
      endif()
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
      list(APPEND HARDENING_COMPILE_OPTIONS /guard:cf)
      list(APPEND HARDENING_LINK_OPTIONS /guard:cf)
    endif()

    if(${ENABLE_STACK_PROTECTION} AND CMAKE_BUILD_TYPE STREQUAL "Debug")
      list(APPEND HARDENING_COMPILE_OPTIONS /RTC1)
    endif()

    if(${ENABLE_OVERFLOW_PROTECTION})
      list(APPEND HARDENING_COMPILE_OPTIONS /sdl)
    endif()
  endif()

  target_compile_options(
    ${_project_name} INTERFACE $<$<COMPILE_LANGUAGE:CXX>:${HARDENING_COMPILE_OPTIONS}>
                               $<$<COMPILE_LANGUAGE:C>:${HARDENING_COMPILE_OPTIONS}>
  )

  target_link_options(
    ${_project_name} INTERFACE $<$<COMPILE_LANGUAGE:CXX>:${HARDENING_LINK_OPTIONS}>
    $<$<COMPILE_LANGUAGE:C>:${HARDENING_LINK_OPTIONS}>
  )
endfunction()
