# `target_link_system_libraries`

Link multiple library targets as system libraries (which suppresses their warnings).

The function accepts the same arguments as `target_link_libraries`. It has the following features:

- The include directories of the library are included as `SYSTEM` to suppress their warnings. This helps in enabling `WARNINGS_AS_ERRORS` for your own source code.
- For installation of the package, the includes are considered to be at `${CMAKE_INSTALL_INCLUDEDIR}`.
