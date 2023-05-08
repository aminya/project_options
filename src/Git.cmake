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
# - REMOTE_NAME: The repository of the url (project name)
# - REMOTE_FULL_URL: The url of the repository (protocol + host + user + repo)
function(
  git_parse_url
  URL
  # output variables
  REMOTE_PROTOCOL
  REMOTE_HOST
  REMOTE_USER
  REMOTE_NAME
  REMOTE_FULL_URL)
  # https://regex101.com/r/jfU0cz/1
  string(
    REGEX MATCH
          "([a-z]+://)?([^/]*)/([^/]*)/(.*)(\\.git)?"
          _
          ${URL})
  set(REMOTE_PROTOCOL ${CMAKE_MATCH_1})
  set(REMOTE_HOST ${CMAKE_MATCH_2})
  set(REMOTE_USER ${CMAKE_MATCH_3})
  set(REMOTE_NAME ${CMAKE_MATCH_4})

  if(NOT REMOTE_USER OR NOT REMOTE_NAME)
    message(SEND_ERROR "Could not parse git url: ${URL}")
    return()
  endif()

  if(NOT REMOTE_PROTOCOL)
    set(REMOTE_PROTOCOL "https://")
  endif()

  if(NOT REMOTE_HOST)
    set(REMOTE_HOST "github.com")
  endif()

  set(REMOTE_FULL_URL "${REMOTE_PROTOCOL}${REMOTE_HOST}/${REMOTE_USER}/${REMOTE_NAME}.git")

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
