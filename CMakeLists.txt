cmake_minimum_required(VERSION 3.9)
project(libr VERSION 1.0.1 DESCRIPTION "mylib description")
include(GNUInstallDirs)
add_library(libr SHARED hello.cpp)
set_target_properties(libr PROPERTIES
        VERSION ${PROJECT_VERSION}
        SOVERSION 1
        PUBLIC_HEADER hello.h)
configure_file(libr.pc.in libr.pc @ONLY)
target_include_directories(libr PRIVATE .)
install(TARGETS libr
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(FILES ${CMAKE_BINARY_DIR}/libr.pc
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/pkgconfig)