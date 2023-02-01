# `target_include_interface_directory` function

This function that includes `${CMAKE_CURRENT_SOURCE_DIR}/include`
(i.e. the `include` directory under the path of CMakeLists.txt which calls the function)
as the header directory of the target.

A variable `<target_name>_INTERFACE_DIRECTORY` will be created to represent the header directory path.

```cmake
add_library(my_header_lib INTERFACE)
target_include_interface_directory(my_header_lib)

add_library(my_lib)
target_sources(my_lib PRIVATE function.cpp)
target_include_interface_directory(my_lib)

package_project(
  TARGETS my_header_lib my_lib
  PUBLIC_INCLUDES ${my_lib_INTERFACE_DIRECTORY}
  INTERFACE_INCLUDES ${my_header_lib_INTERFACE_DIRECTORY}
)
```