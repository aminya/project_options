include_guard()

# Parse the given Git url into its components
#
# It expects the url to be in the form of:
# `[protocol://][host]/user/repo[.git]`
#
# Input variables:
# - URL: The url to parse
#
# Output variables:
# - REMOTE_PROTOCOL: The protocol of the url (http, https, ssh, etc)
# - REMOTE_HOST: The host of the url (github, gitlab, etc)
# - REMOTE_USER: The user of the url (username, organization, etc)
# - REMOTE_REPOSITORY_NAME: The repository of the url (project name)
# - REMOTE_FULL_URL: The url of the repository (protocol + host + user + repo)
function(
  git_parse_url
  INPUT_URL
  # output variables
  REMOTE_PROTOCOL
  REMOTE_HOST
  REMOTE_USER
  REMOTE_REPOSITORY_NAME
  REMOTE_FULL_URL)
  # https://regex101.com/r/jfU0cz/1
  string(
    REGEX MATCH
          "([a-z]+://)?([^/]*)/([^/]*)/(.*)(\\.git)?"
          _
          ${INPUT_URL})
  set(REMOTE_PROTOCOL ${CMAKE_MATCH_1})
  set(REMOTE_HOST ${CMAKE_MATCH_2})
  set(REMOTE_USER ${CMAKE_MATCH_3})
  set(REMOTE_REPOSITORY_NAME ${CMAKE_MATCH_4})

  if(NOT REMOTE_USER OR NOT REMOTE_REPOSITORY_NAME)
    message(SEND_ERROR "Could not parse git url: ${URL}")
    return()
  endif()

  if(NOT REMOTE_PROTOCOL)
    set(REMOTE_PROTOCOL "https://")
  endif()

  if(NOT REMOTE_HOST)
    set(REMOTE_HOST "github.com")
  endif()

  set(REMOTE_FULL_URL "${REMOTE_PROTOCOL}${REMOTE_HOST}/${REMOTE_USER}/${REMOTE_REPOSITORY_NAME}.git")

  set(${REMOTE_PROTOCOL}
      ${REMOTE_PROTOCOL}
      PARENT_SCOPE)
  set(${REMOTE_HOST}
      ${REMOTE_HOST}
      PARENT_SCOPE)
  set(${REMOTE_USER}
      ${REMOTE_USER}
      PARENT_SCOPE)
  set(${GIT_REPO}
      ${GIT_REPO}
      PARENT_SCOPE)
  set(${REMOTE_FULL_URL}
      ${REMOTE_FULL_URL}
      PARENT_SCOPE)
endfunction()

# Add a remote to the given repository on the given path
#
# Input variables:
# - REPOSITORY_PATH: The path to the repository
# - REMOTE_URL: The url of the remote to add
# - REMOTE_NAME: The name of the remote to add (defaults to the remote user)
function(git_add_remote)
  set(oneValueArgs REPOSITORY_PATH REMOTE_URL REMOTE_NAME)
  cmake_parse_arguments(
    _fun
    ""
    "${oneValueArgs}"
    ""
    ${ARGN})

  if("${_fun_REPOSITORY_PATH}" STREQUAL "")
    message(FATAL_ERROR "REPOSITORY_PATH is required")
  endif()

  if("${_fun_REMOTE_URL}" STREQUAL "")
    message(FATAL_ERROR "REMOTE_URL is required")
  endif()

  find_program(GIT_EXECUTABLE "git" REQUIRED)

  # ensure that the given repository's remote is the current remote
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" "remote" "-v"
    WORKING_DIRECTORY "${_fun_REPOSITORY_PATH}" COMMAND_ERROR_IS_FATAL LAST
    OUTPUT_VARIABLE _remote_output)
  string(FIND "${_remote_output}" "${_fun_REMOTE_URL}" _find_index)

  # Add the given remote if it doesn't exist
  if(${_find_index} EQUAL -1)
    if("${_fun_REMOTE_NAME}" STREQUAL "")
      # use the remote user as the remote name if it's not given
      git_parse_url(
        "${_fun_REMOTE_URL}"
        _REMOTE_PROTOCOL
        _REMOTE_HOST
        _REMOTE_USER
        _REMOTE_REPOSITORY_NAME
        _REMOTE_FULL_URL)
      set(_fun_REMOTE_NAME "${_REMOTE_USER}")
    endif()

    execute_process(COMMAND "${GIT_EXECUTABLE}" "remote" "add" "${_fun_REMOTE_NAME}" "${_fun_REMOTE_URL}"
                    WORKING_DIRECTORY "${_fun_REPOSITORY_PATH}" COMMAND_ERROR_IS_FATAL LAST)
    execute_process(COMMAND "${GIT_EXECUTABLE}" "fetch" "${_fun_REMOTE_NAME}"
                    WORKING_DIRECTORY "${_fun_REPOSITORY_PATH}" COMMAND_ERROR_IS_FATAL LAST)
  endif()
endfunction()

# Clone the given repository to the given path
#
# Input variables:
# - REPOSITORY_PATH: The path to the repository
# - REMOTE_URL: The url of the remote to add
# - REMOTE_NAME: The name of the remote to add (defaults to the remote user)
function(git_clone)
  set(oneValueArgs REPOSITORY_PATH REMOTE_URL REMOTE_NAME)
  cmake_parse_arguments(
    _fun
    ""
    "${oneValueArgs}"
    ""
    ${ARGN})

  if(NOT EXISTS "${_fun_REPOSITORY_PATH}")
    message(STATUS "Cloning at ${_fun_REPOSITORY_PATH}")

    find_program(GIT_EXECUTABLE "git" REQUIRED)
    get_filename_component(_fun_REPOSITORY_PARENT_PATH "${_fun_REPOSITORY_PATH}" DIRECTORY)
    execute_process(COMMAND "${GIT_EXECUTABLE}" "clone" "${_fun_REMOTE_URL}"
                    WORKING_DIRECTORY "${_fun_REPOSITORY_PARENT_PATH}" COMMAND_ERROR_IS_FATAL LAST)
  else()
    message(STATUS "Repository already exists at ${_fun_REPOSITORY_PATH}.")
    git_add_remote(
      REMOTE_URL
      "${_fun_REMOTE_URL}"
      REPOSITORY_PATH
      "${_fun_REPOSITORY_PATH}"
      REMOTE_NAME
      "${_fun_REMOTE_NAME}")
  endif()
endfunction()
