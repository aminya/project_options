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
