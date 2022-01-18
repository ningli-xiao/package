# Copyright(c) 2019 ning authors Distributed under the MIT License (http://opensource.org/licenses/MIT)

cmake_minimum_required(VERSION 3.10...3.21)

# ---------------------------------------------------------------------------------------
# Start ning project
# ---------------------------------------------------------------------------------------
include(cmake/utils.cmake)
include(cmake/ide.cmake)

ning_extract_version()

project(ning VERSION ${NING_VERSION} LANGUAGES CXX)

message(STATUS "Build ning: ${NING_VERSION}")

include(GNUInstallDirs)
include_directories(
        include/
)

# ---------------------------------------------------------------------------------------
# Set default build to release
# ---------------------------------------------------------------------------------------
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Choose Release or Debug" FORCE)
endif()

# ---------------------------------------------------------------------------------------
# Compiler config
# ---------------------------------------------------------------------------------------
if(NOT CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 11)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()

# make sure __cplusplus is defined when using msvc and enable parallel build
if(MSVC)
    string(APPEND CMAKE_CXX_FLAGS " /Zc:__cplusplus /MP")
endif()

set(CMAKE_CXX_EXTENSIONS OFF)

if(CMAKE_SYSTEM_NAME MATCHES "CYGWIN" OR CMAKE_SYSTEM_NAME MATCHES "MSYS")
    set(CMAKE_CXX_EXTENSIONS ON)
endif()

# ---------------------------------------------------------------------------------------
# Set NING_MASTER_PROJECT to ON if we are building ning
# ---------------------------------------------------------------------------------------
# Check if ning is being used directly or via add_subdirectory, but allow overriding
if(NOT DEFINED NING_MASTER_PROJECT)
    if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
        set(NING_MASTER_PROJECT ON)
    else()
        set(NING_MASTER_PROJECT OFF)
    endif()
endif()

# precompiled headers option
option(NING_ENABLE_PCH "Build static or shared library using precompiled header to speed up compilation time" OFF)

# install options
option(NING_INSTALL "Generate the install target" ${NING_MASTER_PROJECT})

# misc tweakme options
if(WIN32)
    option(NING_WCHAR_SUPPORT "Support wchar api" OFF)
    option(NING_WCHAR_FILENAMES "Support wchar filenames" OFF)
else()
    set(NING_WCHAR_SUPPORT OFF CACHE BOOL "non supported option" FORCE)
    set(NING_WCHAR_FILENAMES OFF CACHE BOOL "non supported option" FORCE)
endif()

if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
    option(NING_CLOCK_COARSE "Use CLOCK_REALTIME_COARSE instead of the regular clock," OFF)
else()
    set(NING_CLOCK_COARSE OFF CACHE BOOL "non supported option" FORCE)
endif()

find_package(Threads REQUIRED)

# 此处应有掌声
# ---------------------------------------------------------------------------------------
# Static/Shared library (shared not supported in windows yet)
# ---------------------------------------------------------------------------------------
set(NING_SRCS src/hello.cpp)
add_library(ning STATIC ${NING_SRCS} ${NING_ALL_HEADERS})
add_library(ning::ning ALIAS ning)

target_include_directories(ning PUBLIC "$<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/include>"
        "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>")
target_link_libraries(ning PUBLIC Threads::Threads)

ning_enable_warnings(ning)

set_target_properties(ning PROPERTIES VERSION ${NING_VERSION} SOVERSION ${NING_VERSION_MAJOR})
set_target_properties(ning PROPERTIES DEBUG_POSTFIX d)

if(COMMAND target_precompile_headers AND NING_ENABLE_PCH)
    #configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/pch.h.in ${PROJECT_BINARY_DIR}/ning_pch.h @ONLY)
    #target_precompile_headers(ning PRIVATE ${PROJECT_BINARY_DIR}/ning_pch.h)
endif()

# ---------------------------------------------------------------------------------------
# Misc definitions according to tweak options
# ---------------------------------------------------------------------------------------
foreach(
        NING_OPTION
        NING_NO_EXCEPTIONS
)
    if(${NING_OPTION})
        target_compile_definitions(ning PUBLIC ${NING_OPTION})
    endif()
endforeach()

if(NING_NO_EXCEPTIONS AND NOT MSVC)
    target_compile_options(ning PRIVATE -fno-exceptions)
endif()

# ---------------------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------------------
if(NING_INSTALL)
    message(STATUS "Generating install")
    set(project_config_in "${CMAKE_CURRENT_LIST_DIR}/cmake/ningConfig.cmake.in")
    set(project_config_out "${CMAKE_CURRENT_BINARY_DIR}/ningConfig.cmake")
    set(config_targets_file "ningConfigTargets.cmake")
    set(version_config_file "${CMAKE_CURRENT_BINARY_DIR}/ningConfigVersion.cmake")
    set(export_dest_dir "${CMAKE_INSTALL_LIBDIR}/cmake/ning")
    set(pkgconfig_install_dir "${CMAKE_INSTALL_LIBDIR}/pkgconfig")
    set(pkg_config "${CMAKE_BINARY_DIR}/${PROJECT_NAME}.pc")

    # ---------------------------------------------------------------------------------------
    # Include files
    # ---------------------------------------------------------------------------------------
    install(
            TARGETS ning
            EXPORT ning
            LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
            ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
            RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

    # ---------------------------------------------------------------------------------------
    # Install pkg-config file
    # ---------------------------------------------------------------------------------------
    get_target_property(PKG_CONFIG_DEFINES ning INTERFACE_COMPILE_DEFINITIONS)
    string(REPLACE ";" " -D" PKG_CONFIG_DEFINES "${PKG_CONFIG_DEFINES}")
    string(CONCAT PKG_CONFIG_DEFINES "-D" "${PKG_CONFIG_DEFINES}")
    configure_file("cmake/${PROJECT_NAME}.pc.in" "${pkg_config}" @ONLY)
    install(FILES "${pkg_config}" DESTINATION "${pkgconfig_install_dir}")

    # ---------------------------------------------------------------------------------------
    # Install CMake config files
    # ---------------------------------------------------------------------------------------
    install(EXPORT ning DESTINATION ${export_dest_dir} NAMESPACE ning:: FILE ${config_targets_file})

    include(CMakePackageConfigHelpers)
    configure_package_config_file("${project_config_in}" "${project_config_out}"
            INSTALL_DESTINATION ${export_dest_dir})

    write_basic_package_version_file("${version_config_file}" COMPATIBILITY SameMajorVersion)
    install(FILES "${project_config_out}" "${version_config_file}" DESTINATION "${export_dest_dir}")
endif()
