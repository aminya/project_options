include_guard()

#[[.rst:

``git_clone``
===============

Clone the given repository to the given path

Input variables:

- ``REPOSITORY_PATH``: The path to the repository
- ``REMOTE_URL``: The url of the remote to add
- ``REMOTE_NAME``: The name of the remote to add (defaults to the remote user)

]]
function(git_clone)
  set(oneValueArgs REPOSITORY_PATH REMOTE_URL REMOTE_NAME FORCE)
  cmake_parse_arguments(_fun "" "${oneValueArgs}" "" ${ARGN})

  if("${_fun_REPOSITORY_PATH}" STREQUAL "" OR "${_fun_REMOTE_URL}" STREQUAL "")
    message(FATAL_ERROR "REPOSITORY_PATH and _fun_REMOTE_URL are required")
  endif()

  # the folder is created as soon as the clone starts
  if(NOT EXISTS "${_fun_REPOSITORY_PATH}" OR "${_fun_FORCE}" STREQUAL "TRUE")
    message(STATUS "Cloning at ${_fun_REPOSITORY_PATH}")

    find_program(GIT_EXECUTABLE "git" REQUIRED)
    get_filename_component(_fun_REPOSITORY_PARENT_PATH "${_fun_REPOSITORY_PATH}" DIRECTORY)
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" "clone" "${_fun_REMOTE_URL}"
      WORKING_DIRECTORY "${_fun_REPOSITORY_PARENT_PATH}" COMMAND_ERROR_IS_FATAL LAST
    )
  else()
    message(
      STATUS "Repository already exists at ${_fun_REPOSITORY_PATH}. Waiting for git lock file.."
    )
    git_wait(REPOSITORY_PATH "${_fun_REPOSITORY_PATH}")

    if(NOT EXISTS "${_fun_REPOSITORY_PATH}/.git")
      message(
        STATUS
          "Folder ${_fun_REPOSITORY_PATH} exists but is not a git repository. Trying to force clone"
      )
      # recall the function with the force flag
      git_clone(
        REPOSITORY_PATH
        "${_fun_REPOSITORY_PATH}"
        REMOTE_URL
        "${_fun_REMOTE_URL}"
        REMOTE_NAME
        "${_fun_REMOTE_NAME}"
        FORCE
        TRUE
      )
    endif()

    git_add_remote(
      REMOTE_URL
      "${_fun_REMOTE_URL}"
      REPOSITORY_PATH
      "${_fun_REPOSITORY_PATH}"
      REMOTE_NAME
      "${_fun_REMOTE_NAME}"
    )
  endif()
endfunction()

#[[.rst:

``git_pull``
============

Pull the given repository

It will temporarily switch back to the previous branch if the head is detached for updating

Input variables:

- ``REPOSITORY_PATH``: The path to the repository

]]
function(git_pull)
  set(oneValueArgs REPOSITORY_PATH)
  cmake_parse_arguments(_fun "" "${oneValueArgs}" "" ${ARGN})

  if("${_fun_REPOSITORY_PATH}" STREQUAL "")
    message(FATAL_ERROR "REPOSITORY_PATH is required")
  endif()

  # store the current revision
  git_revision(REVISION REPOSITORY_PATH "${_fun_REPOSITORY_PATH}")

  git_switch_back(REPOSITORY_PATH "${_fun_REPOSITORY_PATH}")

  message(STATUS "Updating ${_fun_REPOSITORY_PATH}")
  find_program(GIT_EXECUTABLE "git" REQUIRED)
  execute_process(COMMAND "${GIT_EXECUTABLE}" "pull" WORKING_DIRECTORY "${_fun_REPOSITORY_PATH}")

  # restore the revision
  git_checkout(REPOSITORY_PATH "${_fun_REPOSITORY_PATH}" REVISION "${REVISION}")
endfunction()

#[[.rst:

``git_checkout``
==================

Checkout the given revision

Input variables:

- ``REPOSITORY_PATH``: The path to the repository
- ``REVISION``: The revision to checkout

]]
function(git_checkout)
  set(oneValueArgs REPOSITORY_PATH REVISION)
  cmake_parse_arguments(_fun "" "${oneValueArgs}" "" ${ARGN})

  if("${_fun_REPOSITORY_PATH}" STREQUAL "" OR "${_fun_REVISION}" STREQUAL "")
    message(FATAL_ERROR "REPOSITORY_PATH and REVISION are required")
  endif()

  find_program(GIT_EXECUTABLE "git" REQUIRED)
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" "-c" "advice.detachedHead=false" "checkout" "${_fun_REVISION}"
    WORKING_DIRECTORY "${_fun_REPOSITORY_PATH}" COMMAND_ERROR_IS_FATAL LAST
  )
endfunction()

#[[.rst:

``git_parse_url``
====================

Parse the given Git url into its components

It expects the url to be in the form of:
`[protocol://][host]/user/repo[.git]`

Input variables:

- ``INPUT_URL``: The url to parse

Output variables:

- ``PROTOCOL``: The protocol of the url (http, https, ssh, etc)
- ``HOST``: The host of the url (github, gitlab, etc)
- ``USER``: The user of the url (username, organization, etc)
- ``REPOSITORY_NAME``: The repository of the url (project name)
- ``FULL_URL``: The url of the repository (protocol + host + user + repo)

#]]
function(
  git_parse_url
  INPUT_URL
  # output variables
  PROTOCOL
  HOST
  USER
  REPOSITORY_NAME
  FULL_URL
)
  # https://regex101.com/r/gVep0l/1
  string(REGEX MATCH "([a-z]+:\/\/)?(.*\/)?([^/]*)\/(.*)" _matched "${INPUT_URL}")
  if(NOT "${_matched}" STREQUAL "${INPUT_URL}")
    message(SEND_ERROR "Could not parse git url: ${URL}")
    return()
  endif()
  set(_PROTOCOL ${CMAKE_MATCH_1})
  set(_HOST ${CMAKE_MATCH_2})
  set(_USER ${CMAKE_MATCH_3})
  set(_REPOSITORY_NAME ${CMAKE_MATCH_4})

  if(NOT _USER OR NOT _REPOSITORY_NAME)
    message(SEND_ERROR "Could not parse git url: ${URL}")
    return()
  endif()

  if(NOT _PROTOCOL)
    set(_PROTOCOL "https://")
  endif()

  if(NOT _HOST)
    set(_HOST "github.com")
  endif()

  # strip .git from the end of the repository name
  string(REGEX REPLACE "\.git$" "" _REPOSITORY_NAME "${_REPOSITORY_NAME}")

  # construct the full url
  set(_FULL_URL "${_PROTOCOL}${_HOST}/${_USER}/${_REPOSITORY_NAME}.git")

  set(${PROTOCOL} ${_PROTOCOL} PARENT_SCOPE)
  set(${HOST} ${_HOST} PARENT_SCOPE)
  set(${USER} ${_USER} PARENT_SCOPE)
  set(${REPOSITORY_NAME} ${_REPOSITORY_NAME} PARENT_SCOPE)
  set(${FULL_URL} ${_FULL_URL} PARENT_SCOPE)
endfunction()

#[[.rst:

``git_add_remote``
=====================

Add a remote to the given repository on the given path

Input variables:

- ``REPOSITORY_PATH``: The path to the repository
- ``REMOTE_URL``: The url of the remote to add
- ``REMOTE_NAME``: The name of the remote to add (defaults to the remote user)

]]
function(git_add_remote)
  set(oneValueArgs REPOSITORY_PATH REMOTE_URL REMOTE_NAME)
  cmake_parse_arguments(_fun "" "${oneValueArgs}" "" ${ARGN})

  if("${_fun_REPOSITORY_PATH}" STREQUAL "" OR "${_fun_REMOTE_URL}" STREQUAL "")
    message(FATAL_ERROR "REPOSITORY_PATH and REMOTE_URL are required")
  endif()

  find_program(GIT_EXECUTABLE "git" REQUIRED)

  # ensure that the given repository's remote is the current remote
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" "remote" "-v" WORKING_DIRECTORY "${_fun_REPOSITORY_PATH}"
                                                                COMMAND_ERROR_IS_FATAL LAST
    OUTPUT_VARIABLE _remote_output
  )
  string(FIND "${_remote_output}" "${_fun_REMOTE_URL}" _find_index)

  # Add the given remote if it doesn't exist
  if(${_find_index} EQUAL -1)
    if("${_fun_REMOTE_NAME}" STREQUAL "")
      # use the remote user as the remote name if it's not given
      git_parse_url(
        "${_fun_REMOTE_URL}"
        _PROTOCOL
        _HOST
        _USER
        _REPOSITORY_NAME
        _FULL_URL
      )
      set(_fun_REMOTE_NAME "${_USER}")
    endif()

    execute_process(
      COMMAND "${GIT_EXECUTABLE}" "remote" "add" "${_fun_REMOTE_NAME}" "${_fun_REMOTE_URL}"
      WORKING_DIRECTORY "${_fun_REPOSITORY_PATH}" COMMAND_ERROR_IS_FATAL LAST
    )
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" "fetch" "${_fun_REMOTE_NAME}"
      WORKING_DIRECTORY "${_fun_REPOSITORY_PATH}" COMMAND_ERROR_IS_FATAL LAST
    )
  endif()
endfunction()

#[[.rst:

``git_revision``
================

Find the current git revision of the given repository

Input variables:

- ``REPOSITORY_PATH``: The path to the repository

Output variables:

- ``REVISION``: The variable to store the revision in

]]
function(git_revision REVISION)
  set(oneValueArgs REPOSITORY_PATH)
  cmake_parse_arguments(_fun "" "${oneValueArgs}" "" ${ARGN})

  if("${_fun_REPOSITORY_PATH}" STREQUAL "")
    message(FATAL_ERROR "REPOSITORY_PATH is required")
  endif()

  find_program(GIT_EXECUTABLE "git" REQUIRED)
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" "rev-parse" "HEAD"
    OUTPUT_VARIABLE _git_revision
    WORKING_DIRECTORY "${_fun_REPOSITORY_PATH}"
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  set(${REVISION} ${_git_revision} PARENT_SCOPE)
endfunction()

#[[.rst:

``git_is_detached``
===================

Check if the given repository is in a detached state

Input variables:

- ``REPOSITORY_PATH``: The path to the repository

Output variables:

- ``IS_DETACHED``: The variable to store the result in

]]
function(git_is_detached IS_DETACHED)
  set(oneValueArgs REPOSITORY_PATH)
  cmake_parse_arguments(_fun "" "${oneValueArgs}" "" ${ARGN})

  if("${_fun_REPOSITORY_PATH}" STREQUAL "")
    message(FATAL_ERROR "REPOSITORY_PATH is required")
  endif()

  set(_git_status "")
  find_program(GIT_EXECUTABLE "git" REQUIRED)
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" "rev-parse" "--abbrev-ref" "--symbolic-full-name" "HEAD"
    OUTPUT_VARIABLE _git_status
    WORKING_DIRECTORY "${_fun_REPOSITORY_PATH}"
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  if("${_git_status}" STREQUAL "HEAD")
    set(${IS_DETACHED} TRUE PARENT_SCOPE)
  else()
    set(${IS_DETACHED} FALSE PARENT_SCOPE)
  endif()
endfunction()

#[[.rst:

``git_switch_back``
===================

Detect if the head is detached, if so, switch back before calling git pull on a detached head

Input variables:

- ``REPOSITORY_PATH``: The path to the repository

]]
function(git_switch_back)
  set(oneValueArgs REPOSITORY_PATH)
  cmake_parse_arguments(_fun "" "${oneValueArgs}" "" ${ARGN})

  if("${_fun_REPOSITORY_PATH}" STREQUAL "")
    message(FATAL_ERROR "REPOSITORY_PATH is required")
  endif()

  git_is_detached(IS_DETACHED REPOSITORY_PATH "${_fun_REPOSITORY_PATH}")

  if(${IS_DETACHED})
    message(STATUS "Switch back ${_fun_REPOSITORY_PATH}")
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" "switch" "-" WORKING_DIRECTORY "${_fun_REPOSITORY_PATH}"
    )
  endif()
endfunction()

function(git_wait)
  set(oneValueArgs REPOSITORY_PATH)
  cmake_parse_arguments(_fun "" "${oneValueArgs}" "" ${ARGN})

  if("${_fun_REPOSITORY_PATH}" STREQUAL "")
    message(FATAL_ERROR "REPOSITORY_PATH is required")
  endif()

  set(counter 0)

  # wait until .git/index is present (in case a parallel clone is running)
  while(NOT EXISTS "${_fun_REPOSITORY_PATH}/.git/index"
        OR EXISTS "${_fun_REPOSITORY_PATH}/.git/index.lock"
  )
    execute_process(COMMAND ${CMAKE_COMMAND} -E sleep 0.5)

    math(EXPR counter "${counter} + 1")
    if(${counter} GREATER 20)
      message(STATUS "Timeout waiting for git lock file. Continuing...")
      return()
    endif()
  endwhile()
endfunction()
