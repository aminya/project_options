
add_library(mythirdpartylib STATIC src/Foo.cpp)
generate_export_header(mythirdpartylib)

target_include_directories(mythirdpartylib
    PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src
    PUBLIC "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>" "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>"
)
