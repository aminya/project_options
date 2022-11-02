#!/bin/bash

# setup compiler
export CC=emcc
export CXX=em++

mkdir build
cd build

emcmake cmake -B . -G "Ninja" -DCMAKE_BUILD_TYPE:STRING=Release \
    -DENABLE_CROSS_COMPILING:BOOL=ON ..
cmake --build . --config Release
