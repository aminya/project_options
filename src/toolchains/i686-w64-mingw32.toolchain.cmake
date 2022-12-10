cmake_minimum_required(VERSION 3.16)

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR "i686")

if(NOT
   "$ENV{CROSS_ROOT}"
   STREQUAL
   "")
  set(CMAKE_SYSROOT $ENV{CROSS_ROOT})
  #set(CMAKE_FIND_ROOT_PATH $ENV{CROSS_ROOT})
elseif("${CMAKE_SYSROOT}" STREQUAL "")
  set(CMAKE_SYSROOT /usr/i686-w64-mingw32)
  #set(CMAKE_FIND_ROOT_PATH /usr/i686-w64-mingw32)
endif()

set(CMAKE_C_COMPILER i686-w64-mingw32-gcc)
set(CMAKE_CXX_COMPILER i686-w64-mingw32-g++)
set(CMAKE_RC_COMPILER i686-w64-mingw32-windres)

# search for programs in the build host directories
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# for libraries and headers in the target directories
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# override boost thread component suffix as mingw-w64-boost is compiled with threadapi=win32
set(Boost_THREADAPI win32)
