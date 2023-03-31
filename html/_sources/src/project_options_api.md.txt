## `project_options` parameters

`project_options` function accepts the following named flags:

- `ENABLE_CACHE`: Enable cache if available
- `ENABLE_CPPCHECK`: Enable static analysis with Cppcheck
- `ENABLE_CLANG_TIDY`: Enable static analysis with clang-tidy
- `ENABLE_VS_ANALYSIS`: Enable Visual Studio IDE code analysis if the generator is Visual Studio.
- `ENABLE_CONAN`: Use Conan for dependency management
- `ENABLE_INTERPROCEDURAL_OPTIMIZATION`: Enable Interprocedural Optimization (Link Time Optimization, LTO) in the release build
- `ENABLE_NATIVE_OPTIMIZATION`: Enable the optimizations specific to the build machine (e.g. SSE4_1, AVX2, etc.).
- `ENABLE_COVERAGE`: Enable coverage reporting for gcc/clang
- `ENABLE_DOXYGEN`: Enable Doxygen documentation. The added `doxygen-docs` target can be built via `cmake --build ./build --target doxygen-docs`.
- `WARNINGS_AS_ERRORS`: Treat compiler and static code analyzer warnings as errors. This also affects CMake warnings related to those.
- `ENABLE_SANITIZER_ADDRESS`: Enable address sanitizer
- `ENABLE_SANITIZER_LEAK`: Enable leak sanitizer
- `ENABLE_SANITIZER_UNDEFINED_BEHAVIOR`: Enable undefined behavior sanitizer
- `ENABLE_SANITIZER_THREAD`: Enable thread sanitizer
- `ENABLE_SANITIZER_MEMORY`: Enable memory sanitizer
- `ENABLE_PCH`: Enable Precompiled Headers
- `ENABLE_INCLUDE_WHAT_YOU_USE`: Enable static analysis with include-what-you-use
- `ENABLE_BUILD_WITH_TIME_TRACE`: Enable `-ftime-trace` to generate time tracing `.json` files on clang
- `ENABLE_UNITY`: Enable Unity builds of projects

It gets the following named parameters that can have different values in front of them:

- `PREFIX`: the optional prefix that is used to define `${PREFIX}_project_options` and `${PREFIX}_project_warnings` targets when the function is used in a multi-project fashion.
- `DOXYGEN_THEME`: the name of the Doxygen theme to use. Supported themes:
  - `awesome-sidebar` (default)
  - `awesome`
  - `original`
  - Alternatively you can supply a list of css files to be added to [DOXYGEN_HTML_EXTRA_STYLESHEET](https://www.doxygen.nl/manual/config.html#cfg_html_extra_stylesheet)
- `LINKER`: choose a specific linker (e.g. lld, gold, bfd). If set to OFF (default), the linker is automatically chosen.
- `PCH_HEADERS`: the list of the headers to precompile
- `MSVC_WARNINGS`: Override the defaults for the MSVC warnings
- `CLANG_WARNINGS`: Override the defaults for the CLANG warnings
- `GCC_WARNINGS`: Override the defaults for the GCC warnings
- `CUDA_WARNINGS`: Override the defaults for the CUDA warnings
- `CPPCHECK_OPTIONS`: Override the defaults for the options passed to cppcheck
- `VS_ANALYSIS_RULESET`: Override the defaults for the code analysis rule set in Visual Studio.
- `CONAN_OPTIONS`: Extra Conan options
