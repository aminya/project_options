# - A workaround to correctly resolve installed runtime dependencies on unix for now
# Include this module in the main CMakeLists.txt before adding targets to make use
include_guard()

include(GNUInstallDirs)

set(CMAKE_SKIP_INSTALL_RPATH OFF)

if(APPLE)
  set(CMAKE_MACOSX_RPATH ON)
  list(APPEND CMAKE_INSTALL_RPATH @loader_path/../${CMAKE_INSTALL_LIBDIR})
else()
  list(APPEND CMAKE_INSTALL_RPATH $ORIGIN/../${CMAKE_INSTALL_LIBDIR})
endif()