cmake_minimum_required(VERSION 3.16)
project(libr)

set(CMAKE_CXX_STANDARD 14)
include(CMakePackageConfigHelpers)
add_library(libr SHARED hello.cpp)
# Install the project targets.
install(TARGETS libr
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}/libr
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}/libr
        )
set(CMAKE_INSTALL_PREFIX "/usr/local/")
install(FILES hello.h DESTINATION include/)


