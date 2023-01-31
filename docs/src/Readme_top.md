# project_options

A general-purpose CMake library that provides functions that improve the CMake experience following the best practices.

[![documentation](https://img.shields.io/badge/documentation-blue?style=flat&logo=docs.rs&link=https://aminya.github.io/project_options/)](https://aminya.github.io/project_options/)

[![ci](https://github.com/aminya/project_options/actions/workflows/ci.yml/badge.svg)](https://github.com/aminya/project_options/actions/workflows/ci.yml)

## Features

- `project_options`:
  - compiler warnings,
  - compiler optimizations (intraprocedural, native),
  - caching (ccache, sccache),
  - sanitizers,
  - static code analyzers (clang-tidy, cppcheck, visual studio, include-what-you-use),
  - document generation (doxygen),
  - test coverage analysis,
  - precompiled headers,
  - build time measurement,
  - unity builds
  - using custom linkers (e.g. lld)
- `package_project`: automatic packaging/installation of the project for seamless usage via find_package/target_link through CMake's FetchContent, vcpkg, etc.
- `run_vcpkg`: automatic installation of vcpkg and the project dependencies
- `ENABLE_CONAN` in `project_options`: automatic installation of Conan and the project dependencies
- `dynamic_project_options`: a wrapper around `project_options` to change the options on the fly dynamically
- `target_link_system_libraries` and `target_include_system_directories`: linking/including external dependencies/headers without warnings
- `target_link_cuda`: linking Cuda to a target

## Documentation

The full documentation is available here:

[https://aminya.github.io/project_options/](https://aminya.github.io/project_options/)
