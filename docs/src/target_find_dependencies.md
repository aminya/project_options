# `target_find_dependencies` function

This function `find_package(${dependency} CONFIG REQUIRED)` for all dependencies required and binds them to the target.

Variables `<target_name>_<PRIVATE|PUBLIC|INTERFACE>_DEPENDENCIES` will be created to represent corresponding dependencies.

```cmake
add_library(my_lib)
target_sources(my_lib PRIVATE function.cpp)
target_include_header_directory(my_header_lib)

target_find_dependencies(my_lib
  PUBLIC
  fmt
  PRIVATE
  range-v3
)

target_link_system_libraries(my_lib
  PUBLIC
  fmt::fmt
  PRIVATE
  range-v3::range-v3
)

package_project(
  TARGETS my_lib
  PUBLIC_DEPENDENCIES_CONFIGURED ${my_lib_PUBLIC_DEPENDENCIES}
  PUBLIC_INCLUDES ${my_lib_HEADER_DIRECTORY}
)
```
