cmake_minimum_required(VERSION 3.16)

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

if(NOT
   "${CROSS_ROOT}"
   STREQUAL
   "")
  set(CMAKE_SYSROOT ${CROSS_ROOT})
  #set(CMAKE_FIND_ROOT_PATH ${CROSS_ROOT})
elseif("${CMAKE_SYSROOT}" STREQUAL "")
  #set(CMAKE_SYSROOT /usr/aarch64-linux-gnu)
  set(CMAKE_FIND_ROOT_PATH /usr/aarch64-linux-gnu)
endif()

if(NOT
   "${CROSS_C}"
   STREQUAL
   "")
  set(CMAKE_C_COMPILER ${CROSS_C})
else()
  set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
endif()
if(NOT
   "${CROSS_CXX}"
   STREQUAL
   "")
  set(CMAKE_CXX_COMPILER ${CROSS_CXX})
else()
  set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
endif()

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# The target triple needs to match the prefix of the binutils exactly
# (e.g. CMake looks for arm-none-eabi-ar)
#set(CLANG_TARGET_TRIPLE ${CROSS_TRIPLET})
#set(GCC_ARM_TOOLCHAIN_PREFIX ${CROSS_TRIPLET})
#set(CMAKE_C_COMPILER_TARGET ${CROSS_TRIPLET})
#set(CMAKE_CXX_COMPILER_TARGET ${CROSS_TRIPLET})
#set(CMAKE_ASM_COMPILER_TARGET ${CROSS_TRIPLET})
