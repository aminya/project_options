# `target_find_dependencies` function

```cmake
target_find_dependencies(<target_name>
  [INTERFACE [dependency ...]]
  [PUBLIC [dependency ...]]
  [PRIVATE [dependency ...]]
  [INTERFACE_CONFIG [dependency ...]]
  [PUBLIC_CONFIG [dependency ...]]
  [PRIVATE_CONFIG [dependency ...]]
)
```

This macro calls `find_package(${dependency} [CONFIG] REQUIRED)` for all dependencies required and binds them to the target.

Properties named `PROJECT_OPTIONS_<PRIVATE|PUBLIC|INTERFACE>[_CONFIG]_DEPENDENCIES` will be created in `target_name` to represent corresponding dependencies.
When adding the target to `package_project`, directories in this property will be automatically added.

You can call this function with the same `target_name` multiple times to add more dependencies.

```cmake
add_library(my_lib)
target_sources(my_lib PRIVATE function.cpp)
target_include_interface_directories(my_lib "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_find_dependencies(my_lib
  PUBLIC_CONFIG
  fmt
  PRIVATE_CONFIG
  Microsoft.GSL
)
target_find_dependencies(my_lib
  PRIVATE_CONFIG
  range-v3
)

target_link_system_libraries(my_lib
  PUBLIC
  fmt::fmt
  PRIVATE
  Microsoft.GSL::GSL
  range-v3::range-v3
)

package_project(TARGETS my_lib)
```
