# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.5)

file(MAKE_DIRECTORY
  "/media/aminya/Linux/GitHub/Cpp/project_options/docs/build/_deps/_doxygen_theme-src"
  "/media/aminya/Linux/GitHub/Cpp/project_options/docs/build/_deps/_doxygen_theme-build"
  "/media/aminya/Linux/GitHub/Cpp/project_options/docs/build/_deps/_doxygen_theme-subbuild/_doxygen_theme-populate-prefix"
  "/media/aminya/Linux/GitHub/Cpp/project_options/docs/build/_deps/_doxygen_theme-subbuild/_doxygen_theme-populate-prefix/tmp"
  "/media/aminya/Linux/GitHub/Cpp/project_options/docs/build/_deps/_doxygen_theme-subbuild/_doxygen_theme-populate-prefix/src/_doxygen_theme-populate-stamp"
  "/media/aminya/Linux/GitHub/Cpp/project_options/docs/build/_deps/_doxygen_theme-subbuild/_doxygen_theme-populate-prefix/src"
  "/media/aminya/Linux/GitHub/Cpp/project_options/docs/build/_deps/_doxygen_theme-subbuild/_doxygen_theme-populate-prefix/src/_doxygen_theme-populate-stamp"
)

set(configSubDirs Debug)
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "/media/aminya/Linux/GitHub/Cpp/project_options/docs/build/_deps/_doxygen_theme-subbuild/_doxygen_theme-populate-prefix/src/_doxygen_theme-populate-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "/media/aminya/Linux/GitHub/Cpp/project_options/docs/build/_deps/_doxygen_theme-subbuild/_doxygen_theme-populate-prefix/src/_doxygen_theme-populate-stamp${cfgdir}") # cfgdir has leading slash
endif()
