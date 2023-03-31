cmake_minimum_required(VERSION 3.16)

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR "x64")

if(NOT
   "${CROSS_ROOT}"
   STREQUAL
   "")
  set(CMAKE_SYSROOT ${CROSS_ROOT})
  #set(CMAKE_FIND_ROOT_PATH ${CROSS_ROOT})
elseif("${CMAKE_SYSROOT}" STREQUAL "")
  set(CMAKE_SYSROOT /usr/x86_64-w64-mingw32)
  #set(CMAKE_FIND_ROOT_PATH /usr/x86_64-w64-mingw32)
endif()

if(NOT
   "${CROSS_C}"
   STREQUAL
   "")
  set(CMAKE_C_COMPILER ${CROSS_C})
else()
  set(CMAKE_C_COMPILER x86_64-w64-mingw32-gcc)
endif()
if(NOT
   "${CROSS_CXX}"
   STREQUAL
   "")
  set(CMAKE_CXX_COMPILER ${CROSS_CXX})
else()
  set(CMAKE_CXX_COMPILER x86_64-w64-mingw32-g++)
endif()
if(NOT
   "${CROSS_RC}"
   STREQUAL
   "")
  set(CMAKE_RC_COMPILER ${CROSS_RC})
else()
  set(CMAKE_RC_COMPILER x86_64-w64-mingw32-windres)
endif()

# search for programs in the build host directories
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# for libraries and headers in the target directories
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# override boost thread component suffix as mingw-w64-boost is compiled with threadapi=win32
set(Boost_THREADAPI win32)
