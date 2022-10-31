#!/bin/bash

mkdir build
cd build

cmake -B . -G "Ninja" -DCMAKE_BUILD_TYPE:STRING=Debug ..
cmake --build . --config Debug
ctest -C Debug --verbose