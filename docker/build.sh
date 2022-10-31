#!/bin/bash

mkdir build
cd build

cmake -B . -G "Ninja" -DCMAKE_BUILD_TYPE:STRING=Release ..
cmake --build . --config Release
