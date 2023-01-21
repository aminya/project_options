include_guard()

# find a subtring from a string by a given prefix such as VCVARSALL_ENV_START
function(
  find_substring_by_prefix
  output
  prefix
  input)
  # find the prefix
  string(FIND "${input}" "${prefix}" prefix_index)
  if("${prefix_index}" STREQUAL "-1")
    message(SEND_ERROR "Could not find ${prefix} in ${input}")
  endif()
  # find the start index
  string(LENGTH "${prefix}" prefix_length)
  math(EXPR start_index "${prefix_index} + ${prefix_length}")

  string(
    SUBSTRING "${input}"
              "${start_index}"
              "-1"
              _output)
  set("${output}"
      "${_output}"
      PARENT_SCOPE)
endfunction()

# A function to set environment variables of CMake from the output of `cmd /c set`
function(set_env_from_string _env_string)
  # replace ; in paths with __sep__ so we can split on ;
  string(
    REGEX
    REPLACE ";"
            "__sep__"
            _env_string_sep_added
            "${_env_string}")

  # the variables are separated by \r?\n
  string(
    REGEX
    REPLACE "\r?\n"
            ";"
            _env_list
            "${_env_string_sep_added}")

  foreach(_env_var ${_env_list})
    # split by =
    string(
      REGEX
      REPLACE "="
              ";"
              _env_parts
              "${_env_var}")

    list(LENGTH _env_parts _env_parts_length)
    if("${_env_parts_length}" EQUAL "2")
      # get the variable name and value
      list(
        GET
        _env_parts
        0
        _env_name)
      list(
        GET
        _env_parts
        1
        _env_value)

      # recover ; in paths
      string(
        REGEX
        REPLACE "__sep__"
                ";"
                _env_value
                "${_env_value}")

      # set _env_name to _env_value
      set(ENV{${_env_name}} "${_env_value}")

      # update cmake program path
      if("${_env_name}" EQUAL "PATH")
        list(APPEND CMAKE_PROGRAM_PATH ${_env_value})
      endif()
    endif()
  endforeach()
endfunction()

# Get all the CMake targets
function(get_all_targets var)
  set(targets)
  get_all_targets_recursive(targets ${CMAKE_CURRENT_SOURCE_DIR})
  set(${var}
      ${targets}
      PARENT_SCOPE)
endfunction()

# Get all the installable CMake targets
function(get_all_installable_targets var)
  set(targets)
  get_all_targets(targets)
  foreach(_target ${targets})
    get_target_property(_target_type ${_target} TYPE)
    if(NOT
       ${_target_type}
       MATCHES
       ".*LIBRARY|EXECUTABLE")
      list(REMOVE_ITEM targets ${_target})
    endif()
  endforeach()
  set(${var}
      ${targets}
      PARENT_SCOPE)
endfunction()

# Get all the CMake targets in the given directory
macro(get_all_targets_recursive targets dir)
  get_property(
    subdirectories
    DIRECTORY ${dir}
    PROPERTY SUBDIRECTORIES)
  foreach(subdir ${subdirectories})
    get_all_targets_recursive(${targets} ${subdir})
  endforeach()

  get_property(
    current_targets
    DIRECTORY ${dir}
    PROPERTY BUILDSYSTEM_TARGETS)
  list(APPEND ${targets} ${current_targets})
endmacro()

# Is CMake verbose?
function(is_verbose var)
  if("${CMAKE_MESSAGE_LOG_LEVEL}" STREQUAL "VERBOSE"
     OR "${CMAKE_MESSAGE_LOG_LEVEL}" STREQUAL "DEBUG"
     OR "${CMAKE_MESSAGE_LOG_LEVEL}" STREQUAL "TRACE")
    set(${var}
        ON
        PARENT_SCOPE)
  else()
    set(${var}
        OFF
        PARENT_SCOPE)
  endif()
endfunction()

# detect the architecture of the target build system or the host system as a fallback
function(detect_architecture arch)
  # if the target processor is not known, fallback to the host processor
  if("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL ""
     AND NOT
         "${CMAKE_HOST_SYSTEM_PROCESSOR}"
         STREQUAL
         "")
    set(_arch "${CMAKE_HOST_SYSTEM_PROCESSOR}")
  elseif(
    NOT
    "${CMAKE_SYSTEM_PROCESSOR}"
    STREQUAL
    "")
    set(_arch "${CMAKE_SYSTEM_PROCESSOR}")
  elseif(
    NOT
    "${DETECTED_CMAKE_SYSTEM_PROCESSOR}" # set by detect_compiler()
    STREQUAL
    "")
    set(_arch "${DETECTED_CMAKE_SYSTEM_PROCESSOR}")
  endif()

  # make it lowercase for comparison
  string(TOLOWER "${_arch}" _arch)

  if(_arch STREQUAL x86 OR _arch MATCHES "^i[3456]86$")
    set(${arch}
        x86
        PARENT_SCOPE)
  elseif(
    _arch STREQUAL x64
    OR _arch STREQUAL x86_64
    OR _arch STREQUAL amd64)
    set(${arch}
        x64
        PARENT_SCOPE)
  elseif(_arch STREQUAL arm)
    set(${arch}
        arm
        PARENT_SCOPE)
  elseif(_arch STREQUAL arm64 OR _arch STREQUAL aarch64)
    set(${arch}
        arm64
        PARENT_SCOPE)
  elseif(_arch STREQUAL riscv64)
    set(${arch}
        rv64
        PARENT_SCOPE)
  elseif(_arch STREQUAL riscv32)
    set(${arch}
        rv32
        PARENT_SCOPE)
  else()
    # fallback to the most common architecture
    message(STATUS "Unknown architecture ${_arch} - using x64")
    set(${arch}
        x64
        PARENT_SCOPE)
  endif()
endfunction()
