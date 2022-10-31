#!/bin/bash

# setup compiler
export CC=${CROSS_CC:-x86_64-w64-mingw32-gcc}
export CXX=${CROSS_CXX:-x86_64-w64-mingw32-g++}

mkdir build
cd build

cmake -B . -G "Ninja" -DCMAKE_BUILD_TYPE:STRING=Release \
    -DENABLE_CROSS_COMPILING:BOOL=ON ..
cmake --build . --config Release
