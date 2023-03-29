# `target_include_interface_directories` function

```cmake
target_include_interface_directories(<target_name> [<include_dir> ...])
```

This function includes `include_dir` as the header interface directory of `target_name`.
If the given `include_dir` path is relative, the function assumes the path is `${CMAKE_CURRENT_SOURCE_DIR}/${include_dir}`
(i.e. the path is related to the path of CMakeLists.txt which calls the function).

A property named `PROJECT_OPTIONS_INTERFACE_DIRECTORIES` will be created in `target_name` to represent the header directory path.
When adding the target to `package_project`, directories in this property will be automatically added.

You can call this function with the same `target_name` multiple times to add more header interface directories.

```cmake
add_library(my_header_lib INTERFACE)
target_include_interface_directories(my_header_lib "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_include_interface_directories(my_header_lib ../include)

add_library(my_lib)
target_sources(my_lib PRIVATE function.cpp)
target_include_interface_directories(my_lib include ../include)

package_project(TARGETS my_header_lib my_lib)
```
