cmake_minimum_required(VERSION 3.16)
enable_language(CXX)
enable_language(C)

set(CMAKE_CXX_COMPILER_ID
    "${CMAKE_CXX_COMPILER_ID}"
    CACHE STRING "The CXX compiler id.")
set(CMAKE_C_COMPILER_ID
    "${CMAKE_C_COMPILER_ID}"
    CACHE STRING "The C compiler id.")
set(CMAKE_SYSTEM_PROCESSOR
    "${CMAKE_SYSTEM_PROCESSOR}"
    CACHE STRING "The target system processor.")
set(CMAKE_HOST_SYSTEM_PROCESSOR
    "${CMAKE_HOST_SYSTEM_PROCESSOR}"
    CACHE STRING "The host system processor.")
