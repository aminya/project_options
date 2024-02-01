include_guard()

#[[.rst:

``git_clone``
===============

Clone the given repository to the given path

Input variables:

- ``REPOSITORY_PATH``: The path to the repository
- ``REMOTE_URL``: The url of the remote to add
- ``REMOTE_NAME``: The name of the remote to add (defaults to the remote user)
- ``SHALLOW_SINCE``: Create a shallow clone with a history after the specified time. date should be in format of `git log --date=raw`.
- ``BRANCH``: Only clone the given branch
- ``FORCE_CLONE``: Force the clone even if the directory exists

Simple example:

.. code:: cmake

  git_clone(
    REPOSITORY_PATH
    "./vcpkg"
    REMOTE_URL
    "https://github.com/microsoft/vcpkg.git"
  )

Example for a shallow clone and checking out of a specific revision:

.. code:: cmake

  git_clone(
    REPOSITORY_PATH
    "$ENV{HOME}/vcpkg"
    REMOTE_URL
    "https://github.com/microsoft/vcpkg.git"
    SHALLOW_SINCE
    "1686087993 -0700"
    BRANCH
    "master"
  )
  git_checkout(
    REPOSITORY_PATH
    "$ENV{HOME}/vcpkg"
    REVISION
    ecd22cc3acc8ee3c406e566db1e19ece1f17f409
  )


]]
function(git_clone)
  set(oneValueArgs
      REPOSITORY_PATH
      REMOTE_URL
      REMOTE_NAME
      SHALLOW_SINCE
      BRANCH
      FORCE_CLONE
  )
  cmake_parse_arguments(_fun "" "${oneValueArgs}" "" ${ARGN})

  if("${_fun_REPOSITORY_PATH}" STREQUAL "" OR "${_fun_REMOTE_URL}" STREQUAL "")
    message(FATAL_ERROR "REPOSITORY_PATH and _fun_REMOTE_URL are required")
  endif()

  # the folder is created as soon as the clone starts
  if(NOT EXISTS "${_fun_REPOSITORY_PATH}" OR "${_fun_FORCE_CLONE}" STREQUAL "TRUE")
    message(STATUS "Cloning at ${_fun_REPOSITORY_PATH}")

    find_program(GIT_EXECUTABLE "git" REQUIRED)
    get_filename_component(_fun_REPOSITORY_PARENT_PATH "${_fun_REPOSITORY_PATH}" DIRECTORY)

    set(GIT_ARGS "clone" "${_fun_REMOTE_URL}" "${_fun_REPOSITORY_PATH}")

    if(NOT "${_fun_SHALLOW_SINCE}" STREQUAL "")
      list(APPEND GIT_ARGS "--shallow-since=${_fun_SHALLOW_SINCE}")
    endif()

    if(NOT "${_fun_BRANCH}" STREQUAL "")
      list(APPEND GIT_ARGS "--single-branch" "--branch=${_fun_BRANCH}")
    endif()

    execute_process(
      COMMAND "${GIT_EXECUTABLE}" ${GIT_ARGS} WORKING_DIRECTORY "${_fun_REPOSITORY_PARENT_PATH}"
                                                                COMMAND_ERROR_IS_FATAL LAST
    )
  else()
    message(STATUS "Repository already exists at ${_fun_REPOSITORY_PATH}.")
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
        FORCE_CLONE
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

If ``TARGET_REVISION`` is given, the pull is skipped if the current revision is the same as the target revision.

It will temporarily switch back to the previous branch if the head is detached for updating.

Input variables:

- ``REPOSITORY_PATH``: The path to the repository
- ``TARGET_REVISION``: if the current revision of the repository is the same as this given revision, the pull is skipped

]]
function(git_pull)
  set(oneValueArgs REPOSITORY_PATH TARGET_REVISION)
  cmake_parse_arguments(_fun "" "${oneValueArgs}" "" ${ARGN})

  if("${_fun_REPOSITORY_PATH}" STREQUAL "")
    message(FATAL_ERROR "REPOSITORY_PATH is required")
  endif()

  # store the current revision
  git_revision(REVISION REPOSITORY_PATH "${_fun_REPOSITORY_PATH}")

  # skip the pull if the revision is the same
  if(NOT "${_fun_TARGET_REVISION}" STREQUAL "" AND "${REVISION}" STREQUAL "${_fun_TARGET_REVISION}")
    message(STATUS "Skipping pull of ${_fun_REPOSITORY_PATH} because it's already at ${REVISION}")
    return()
  else()
    # pull and restore it after the pull
    set(_fun_TARGET_REVISION "${REVISION}")
  endif()

  git_switch_back(REPOSITORY_PATH "${_fun_REPOSITORY_PATH}")

  message(STATUS "Updating ${_fun_REPOSITORY_PATH}")
  find_program(GIT_EXECUTABLE "git" REQUIRED)

  # wait for lock before pulling
  git_wait(REPOSITORY_PATH "${_fun_REPOSITORY_PATH}")

  execute_process(
    COMMAND "${GIT_EXECUTABLE}" "pull" WORKING_DIRECTORY "${_fun_REPOSITORY_PATH}"
                                                         COMMAND_ERROR_IS_FATAL LAST
  )

  # restore the revision
  git_checkout(REPOSITORY_PATH "${_fun_REPOSITORY_PATH}" REVISION "${_fun_TARGET_REVISION}")
endfunction()

#[[.rst:

``git_checkout``
==================

Checkout the given revision

Input variables:

- ``REPOSITORY_PATH``: The path to the repository
- ``REVISION``: The revision to checkout

.. code:: cmake

  git_checkout(
    REPOSITORY_PATH
    "$ENV{HOME}/vcpkg"
    REVISION
    ecd22cc3acc8ee3c406e566db1e19ece1f17f409
  )

.. code:: cmake

  git_checkout(
    REPOSITORY_PATH
    "./some_repo"
    REVISION
    v1.0.0
  )
]]
function(git_checkout)
  set(oneValueArgs REPOSITORY_PATH REVISION)
  cmake_parse_arguments(_fun "" "${oneValueArgs}" "" ${ARGN})

  if("${_fun_REPOSITORY_PATH}" STREQUAL "" OR "${_fun_REVISION}" STREQUAL "")
    message(FATAL_ERROR "REPOSITORY_PATH and REVISION are required")
  endif()

  git_revision(REVISION REPOSITORY_PATH "${_fun_REPOSITORY_PATH}")
  if("${REVISION}" STREQUAL "${_fun_REVISION}")
    return()
  endif()

  # wait for lock before checking out
  git_wait(REPOSITORY_PATH "${_fun_REPOSITORY_PATH}")

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
    OUTPUT_STRIP_TRAILING_WHITESPACE COMMAND_ERROR_IS_FATAL LAST
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
    OUTPUT_STRIP_TRAILING_WHITESPACE COMMAND_ERROR_IS_FATAL LAST
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

Detect if the head is detached, if so, switch/checkout back
If the switch/checkout back fails or goes to a detached state, try to checkout the default branch

This is used before updating the repository in a pull

Input variables:

- ``REPOSITORY_PATH``: The path to the repository

]]
function(git_switch_back)
  set(oneValueArgs REPOSITORY_PATH)
  cmake_parse_arguments(_fun "" "${oneValueArgs}" "" ${ARGN})

  if("${_fun_REPOSITORY_PATH}" STREQUAL "")
    message(FATAL_ERROR "REPOSITORY_PATH is required")
  endif()

  # return if the head is not detached
  git_is_detached(IS_DETACHED REPOSITORY_PATH "${_fun_REPOSITORY_PATH}")
  if(NOT ${IS_DETACHED})
    return()
  endif()

  # first try to switch back
  message(STATUS "Switch back ${_fun_REPOSITORY_PATH}")
  git_wait(REPOSITORY_PATH "${_fun_REPOSITORY_PATH}")
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" "switch" "-" WORKING_DIRECTORY "${_fun_REPOSITORY_PATH}"
    RESULT_VARIABLE _switch_back_result
  )
  git_is_detached(IS_DETACHED REPOSITORY_PATH "${_fun_REPOSITORY_PATH}")
  if(${_switch_back_result} EQUAL 0 AND NOT ${IS_DETACHED})
    return()
  endif()

  # if the switch back failed, try to checkout the previous branch
  message(STATUS "Switch back failed. Trying to checkout previous branch")
  git_wait(REPOSITORY_PATH "${_fun_REPOSITORY_PATH}")
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" "checkout" "-" WORKING_DIRECTORY "${_fun_REPOSITORY_PATH}"
    RESULT_VARIABLE _checkout_result
  )
  git_is_detached(IS_DETACHED REPOSITORY_PATH "${_fun_REPOSITORY_PATH}")
  if(${_checkout_result} EQUAL 0 AND NOT ${IS_DETACHED})
    return()
  endif()

  # switch/checkout back went to a detached state or failed, try to checkout the default branch
  git_is_detached(IS_DETACHED REPOSITORY_PATH "${_fun_REPOSITORY_PATH}")
  if(${IS_DETACHED})
    message(STATUS "Trying to checkout default branch")
    git_default_branch(default_branch REPOSITORY_PATH "${_fun_REPOSITORY_PATH}")
    git_checkout(REPOSITORY_PATH "${_fun_REPOSITORY_PATH}" REVISION "${default_branch}")
  endif()
endfunction()

#[[.rst:

``git_wait``
============

Wait for the git lock file to be released

Input variables:

- ``REPOSITORY_PATH``: The path to the repository
- ``TIMEOUT_COUNTER``: The number of times to wait before timing out

]]
function(git_wait)
  set(oneValueArgs REPOSITORY_PATH TIMEOUT_COUNTER)
  cmake_parse_arguments(_fun "" "${oneValueArgs}" "" ${ARGN})

  if("${_fun_REPOSITORY_PATH}" STREQUAL "")
    message(FATAL_ERROR "REPOSITORY_PATH is required")
  endif()

  if("${_fun_TIMEOUT_COUNTER}" STREQUAL "")
    set(_fun_TIMEOUT_COUNTER 20)
  endif()

  set(counter 0)

  # wait until .git/index is present (in case a parallel clone is running)
  while(NOT EXISTS "${_fun_REPOSITORY_PATH}/.git/index"
        OR EXISTS "${_fun_REPOSITORY_PATH}/.git/index.lock"
  )
    message(STATUS "Waiting for git lock file...[${counter}/${_fun_TIMEOUT_COUNTER}]")
    execute_process(COMMAND ${CMAKE_COMMAND} -E sleep 0.5 COMMAND_ERROR_IS_FATAL LAST)

    math(EXPR counter "${counter} + 1")
    if(${counter} GREATER ${_fun_TIMEOUT_COUNTER})
      message(STATUS "Timeout waiting for git lock file. Continuing...")
      return()
    endif()
  endwhile()
endfunction()

#[[.rst:

``git_default_branch``
======================
Get the default branch of the given repository. Defaults to master in case of failure

Input variables:
- ``REPOSITORY_PATH``: The path to the repository

Output variables:
- ``default_branch``: The variable to store the default branch in


.. code:: cmake

  git_default_branch(
    REPOSITORY_PATH
    "$ENV{HOME}/vcpkg"
    default_branch
  )

]]
function(git_default_branch default_branch)
  # use git symbolic-ref refs/remotes/origin/HEAD to get the default branch

  set(oneValueArgs REPOSITORY_PATH)
  cmake_parse_arguments(_fun "" "${oneValueArgs}" "" ${ARGN})

  if("${_fun_REPOSITORY_PATH}" STREQUAL "")
    message(FATAL_ERROR "REPOSITORY_PATH is required")
  endif()

  find_program(GIT_EXECUTABLE "git" REQUIRED)
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" "symbolic-ref" "refs/remotes/origin/HEAD"
    OUTPUT_VARIABLE _default_branch
    WORKING_DIRECTORY "${_fun_REPOSITORY_PATH}"
    OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE _default_branch_result
  )

  if(${_default_branch_result} EQUAL 0)
    string(REGEX REPLACE "refs/remotes/origin/" "" _default_branch "${_default_branch}")
  else()
    message(
      WARNING "Could not get default branch of ${_fun_REPOSITORY_PATH}. Considering it as master"
    )
    set(_default_branch "master")
  endif()

  set(${default_branch} ${_default_branch} PARENT_SCOPE)
endfunction()
