cmake_minimum_required(VERSION 3.21...3.29)

set(CMAKE_CXX_STANDARD 20)

project(myproj_test VERSION 0.2.0 LANGUAGES CXX)

find_package(myproj_header_only_lib 0.2.0 CONFIG REQUIRED)

# Executable
add_executable(main ../src/main/main.cpp)
target_link_libraries(
  main
  PRIVATE myproj_header_only_lib::lib #
          myproj_header_only_lib::myproj_project_options
          myproj_header_only_lib::myproj_project_warnings
)

## tests
enable_testing()
add_test(NAME main COMMAND main)
