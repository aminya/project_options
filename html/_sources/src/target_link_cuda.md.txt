# `target_link_cuda`

Link Cuda to the given target.

```cmake
add_executable(main_cuda main.cu)
target_compile_features(main_cuda PRIVATE cxx_std_17)
target_link_libraries(main_cuda PRIVATE project_options project_warnings)
target_link_cuda(main_cuda)
```
