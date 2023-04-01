# `enable_cross_compiler`

**NOTE**: more documentation/examples for this feature is welcome. See the `tests/rpi3`, `tests/rpi4`, `tests/emscripten`, `tests-rpi4-vcpkg` directories in the [repositpry](https://github.com/aminya/project_options/tree/main/tests) for full examples.

The following calls `enable_cross_compiler` to enable the cross-compiler as the current toolchain.

```cmake
enable_cross_compiler(
  CC "arm-none-eabi-gcc"
  CXX "arm-none-eabi-g++"
  TARGET_ARCHITECTURE "arm"
  CROSS_ROOT "/usr/arm-none-eabi-gcc"
  CROSS_TRIPLET "arm-none-eabi-gcc"
)
```

The following examples enables cross-compiling when it is opt-in.

```cmake
# opt-in cross-compiling
if(ENABLE_AARCH64_CROSS_COMPILING)
  # my custom aarch64 settings
  enable_cross_compiler(
    DEFAULT_TRIPLET "arm64-linux"
    CC "aarch64-linux-gnu-gcc"
    CXX "aarch64-linux-gnu-g++"
    TARGET_ARCHITECTURE "arm64-linux"
    CROSS_ROOT "/usr/gcc-aarch64-linux-gnu"
    CROSS_TRIPLET "aarch64-linux-gnu"
    #TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/my-toolchain.cmake"
  )
else()
  option(ENABLE_CROSS_COMPILING "Detect cross compiler and setup toolchain" OFF)
  if(ENABLE_CROSS_COMPILING)
    enable_cross_compiler()
  endif()
endif()
```

`enable_cross_compiler` auto-detects the following cross-compilers, when setting `DEFAULT_TRIPLET`:

- _mingw-w64_ [x86_64-w64-mingw32.toolchain.cmake](https://github.com/abeimler/project_options/blob/feature/open-closed-enable-cross-compiler/src/toolchains/x86_64-w64-mingw32.toolchain.cmake)
- _emscripten_

**Example:**

- `-DENABLE_CROSS_COMPILING:BOOL=ON -DDEFAULT_TRIPLET=x64-mingw-dynamic`
- `-DENABLE_CROSS_COMPILING:BOOL=ON -DDEFAULT_TRIPLET=wasm32-emscripten`

For `arm-linux` or `arm64-linux`, you must set the compiler:

- aarch64-linux-gnu [aarch64-linux.toolchain.cmake](https://github.com/abeimler/project_options/blob/feature/open-closed-enable-cross-compiler/src/toolchains/aarch64-linux.toolchain.cmake)
- arm-linux-gnueabi, arm-linux-gnueabihf [arm-linux.toolchain.cmake](https://github.com/abeimler/project_options/blob/feature/open-closed-enable-cross-compiler/src/toolchains/arm-linux.toolchain.cmake)

**Example:**

- `-DENABLE_CROSS_COMPILING:BOOL=ON -DCMAKE_C_COMPILER=gcc-aarch64-linux-gnu-gcc -DCMAKE_CXX_COMPILER=gcc-aarch64-linux-gnu-g++ -DDEFAULT_TRIPLET=arm64-linux`
- `-DENABLE_CROSS_COMPILING:BOOL=ON -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc -DCMAKE_CXX_COMPILER=arm-linux-gnueabi-g++ -DDEFAULT_TRIPLET=arm-linux -DCROSS_ROOT=/usr/gcc-arm-linux-gnueabihf`

For (bare-metal) you don't need/can't set `arm-linux`/`arm64-linux` for vcpkg:

- arm-none-eabi [arm.toolchain.cmake](https://github.com/abeimler/project_options/blob/feature/open-closed-enable-cross-compiler/src/toolchains/arm.toolchain.cmake)

**Example:**

- `-DENABLE_CROSS_COMPILING:BOOL=ON -DCMAKE_C_COMPILER=arm-none-eabi-gcc -DCMAKE_CXX_COMPILER=arm-none-eabi-g++`
- `-DENABLE_CROSS_COMPILING:BOOL=ON -DCMAKE_C_COMPILER=arm-none-eabi-gcc -DCMAKE_CXX_COMPILER=arm-none-eabi-g++ -DTARGET_ARCHITECTURE:STRING=arm -DCROSS_ROOT:STRING="/usr/arm-none-eabi-gcc"
    -DCROSS_TRIPLET:STRING=arm-none-eabi-gcc`

The option for `DEFAULT_TRIPLET` are the similar to [vcpkg triplets](https://github.com/microsoft/vcpkg/tree/master/triplets/community/)

- x64-mingw-dynamic
- x64-mingw-static
- x86-mingw-dynamic
- x86-mingw-static
- wasm32-emscripten
- arm-linux
- arm64-linux
