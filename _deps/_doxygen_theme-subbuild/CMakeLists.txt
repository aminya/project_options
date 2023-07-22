# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.22.1)

# We name the project and the target for the ExternalProject_Add() call
# to something that will highlight to the user what we are working on if
# something goes wrong and an error message is produced.

project(_doxygen_theme-populate NONE)



include(ExternalProject)
ExternalProject_Add(_doxygen_theme-populate
                     "UPDATE_DISCONNECTED" "False" "URL" "https://github.com/jothepro/doxygen-awesome-css/archive/refs/tags/v2.0.2.zip"
                    SOURCE_DIR          "/home/aminya/GitHub/Cpp/project_options/docs/build/_deps/_doxygen_theme-src"
                    BINARY_DIR          "/home/aminya/GitHub/Cpp/project_options/docs/build/_deps/_doxygen_theme-build"
                    CONFIGURE_COMMAND   ""
                    BUILD_COMMAND       ""
                    INSTALL_COMMAND     ""
                    TEST_COMMAND        ""
                    USES_TERMINAL_DOWNLOAD  YES
                    USES_TERMINAL_UPDATE    YES
)


