# `package_project`

A function that packages the project for external usage (e.g. from vcpkg, Conan, etc).

The following arguments specify the package:

- `TARGETS`: the targets you want to package. It is recursively found for the current folder if not specified

- `INTERFACE_INCLUDES` or `PUBLIC_INCLUDES`: a list of interface/public include directories or files.

  <sub>NOTE: The given include directories are directly installed to the install destination. To have an `include` folder in the install destination with the content of your include directory, name your directory `include`.</sub>

- `INTERFACE_DEPENDENCIES_CONFIGURED` or `PUBLIC_DEPENDENCIES_CONFIGURED`: the names of the interface/public dependencies that are found using `CONFIG`.

- `INTERFACE_DEPENDENCIES` or `PUBLIC_DEPENDENCIES`: the interface/public dependencies that will be found by any means using `find_dependency`. The arguments must be specified within quotes (e.g.`"<dependency> 1.0.0 EXACT"` or `"<dependency> CONFIG"`).

- `PRIVATE_DEPENDENCIES_CONFIGURED`: the names of the PRIVATE dependencies found using `CONFIG`. Only included when `BUILD_SHARED_LIBS` is `OFF`.

- `PRIVATE_DEPENDENCIES`: the PRIVATE dependencies found by any means using `find_dependency`. Only included when `BUILD_SHARED_LIBS` is `OFF`

Other arguments that are automatically found and manually specifying them is not recommended:

- `NAME`: the name of the package. Defaults to `${PROJECT_NAME}`.

- `VERSION`: the version of the package. Defaults to `${PROJECT_VERSION}`.

- `COMPATIBILITY`: the compatibility version of the package. Defaults to `SameMajorVersion`.

- `CONFIG_EXPORT_DESTINATION`: the destination for exporting the configuration files. Defaults to `${CMAKE_BINARY_DIR}/${NAME}`

- `CONFIG_INSTALL_DESTINATION`: the destination for installation of the configuration files. Defaults to `${CMAKE_INSTALL_DATADIR}/${NAME}`
