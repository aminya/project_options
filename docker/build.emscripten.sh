#!/bin/bash

# setup compiler
export CC=emcc
export CXX=em++

mkdir build
cd build

# don't use emcmake, this overrides the CMAKE_TOOLCHAIN_FILE variable
#   emcmake passes the following arguments: -DCMAKE_TOOLCHAIN_FILE=/root/emsdk/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake -DCMAKE_CROSSCOMPILING_EMULATOR=/root/emsdk/node/14.18.2_64bit/bin/node;--experimental-wasm-threads'
#   we don't need it here

cmake -B . -G "Ninja" -DCMAKE_BUILD_TYPE:STRING=Release \
    -DENABLE_CROSS_COMPILING:BOOL=ON ..
cmake --build . --config Release
