cmake_minimum_required(VERSION 3.20)

if(NOT DEFINED REPO_DIR)
  message(FATAL_ERROR "REPO_DIR must name the generated fake vcpkg repository")
endif()

find_program(GIT_EXECUTABLE git REQUIRED)
file(REMOVE_RECURSE "${REPO_DIR}")
file(MAKE_DIRECTORY "${REPO_DIR}/scripts/buildsystems")

file(WRITE "${REPO_DIR}/bootstrap-vcpkg.sh" [=[
#!/bin/sh
set -eu

part="vcpkg.part"
if ! mkdir "$part" 2>/dev/null; then
  echo "fake bootstrap collision on vcpkg.part" >&2
  exit 42
fi

sleep 3
printf '#!/bin/sh\nexit 0\n' > vcpkg
chmod +x vcpkg
rmdir "$part"
]=])
file(CHMOD "${REPO_DIR}/bootstrap-vcpkg.sh"
     PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
)

file(WRITE "${REPO_DIR}/bootstrap-vcpkg.bat" [=[
@echo off

mkdir vcpkg.part >nul 2>&1
if errorlevel 1 (
  echo fake bootstrap collision on vcpkg.part 1>&2
  exit /b 42
)

timeout /t 3 /nobreak >nul
>vcpkg.exe echo @echo off
rmdir vcpkg.part
exit /b 0
]=])

file(WRITE "${REPO_DIR}/scripts/buildsystems/vcpkg.cmake" [=[
# The generated fixture only needs a valid toolchain file.
]=])

function(run_git)
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" ${ARGV}
    WORKING_DIRECTORY "${REPO_DIR}"
    RESULT_VARIABLE GIT_RESULT
    OUTPUT_VARIABLE GIT_OUTPUT
    ERROR_VARIABLE GIT_ERROR
  )
  if(GIT_RESULT)
    message(
      FATAL_ERROR
      "git ${ARGV} failed (${GIT_RESULT}):\n${GIT_OUTPUT}\n${GIT_ERROR}"
    )
  endif()
endfunction()

run_git(init)
run_git(config user.email test@example.invalid)
run_git(config user.name "vcpkg parallel regression")
run_git(add --all)
run_git(commit --message "Create fake vcpkg fixture")
