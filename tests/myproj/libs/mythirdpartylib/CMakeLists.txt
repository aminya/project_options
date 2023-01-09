add_library(mythirdpartylib STATIC src/Foo.cpp)
generate_export_header(mythirdpartylib)

target_include_directories(mythirdpartylib PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
                                                  $<INSTALL_INTERFACE:include>)
target_include_directories(mythirdpartylib PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>)
