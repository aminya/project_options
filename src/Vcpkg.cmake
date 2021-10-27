include(FetchContent)

macro(run_vcpkg)
  # Download vcpkg from Github
  FetchContent_Declare(
    vcpkg
    GIT_REPOSITORY "https://github.com/microsoft/vcpkg"
    GIT_TAG "5568f110b509a9fd90711978a7cb76bae75bb092")
  FetchContent_MakeAvailable(vcpkg)

  # Run vcpkg bootstrap
  execute_process(COMMAND "./vcpkg/bootstrap-vcpkg" WORKING_DIRECTORY "${vcpkg_SOURCE_DIR}")

  # Setting up vcpkg toolchain
  list(APPEND VCPKG_FEATURE_FLAGS "versions")
  set(CMAKE_TOOLCHAIN_FILE
      ${vcpkg_SOURCE_DIR}/scripts/buildsystems/vcpkg.cmake
      CACHE STRING "Vcpkg toolchain file")
endmacro()
