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

option(NING_BUILD_ALL "Build all artifacts" OFF)

# build shared option
option(NING_BUILD_SHARED "Build shared library" OFF)

# precompiled headers option
option(NING_ENABLE_PCH "Build static or shared library using precompiled header to speed up compilation time" OFF)

# example options
option(NING_BUILD_EXAMPLE "Build example" ${NING_MASTER_PROJECT})
option(NING_BUILD_EXAMPLE_HO "Build header only example" OFF)

# testing options
option(NING_BUILD_TESTS "Build tests" OFF)
option(NING_BUILD_TESTS_HO "Build tests using the header only version" OFF)

# bench options
option(NING_BUILD_BENCH "Build benchmarks (Requires https://github.com/google/benchmark.git to be installed)" OFF)

# sanitizer options
option(NING_SANITIZE_ADDRESS "Enable address sanitizer in tests" OFF)

# warning options
option(NING_BUILD_WARNINGS "Enable compiler warnings" OFF)

# install options
option(NING_INSTALL "Generate the install target" ${NING_MASTER_PROJECT})
option(NING_USE_STD_FORMAT "Use std::format instead of fmt library. No compile-time format string checking." OFF)
option(NING_FMT_EXTERNAL "Use external fmt library instead of bundled" OFF)
option(NING_FMT_EXTERNAL_HO "Use external fmt header-only library instead of bundled" OFF)
option(NING_NO_EXCEPTIONS "Compile with -fno-exceptions. Call abort() on any ning exceptions" OFF)

if(NING_FMT_EXTERNAL AND NING_FMT_EXTERNAL_HO)
    message(FATAL_ERROR "NING_FMT_EXTERNAL and NING_FMT_EXTERNAL_HO are mutually exclusive")
endif()

if(NING_USE_STD_FORMAT AND NING_FMT_EXTERNAL_HO)
    message(FATAL_ERROR "NING_USE_STD_FORMAT and NING_FMT_EXTERNAL_HO are mutually exclusive")
endif()

if(NING_USE_STD_FORMAT AND NING_FMT_EXTERNAL)
    message(FATAL_ERROR "NING_USE_STD_FORMAT and NING_FMT_EXTERNAL are mutually exclusive")
endif()

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

option(NING_PREVENT_CHILD_FD "Prevent from child processes to inherit log file descriptors" OFF)
option(NING_NO_THREAD_ID "prevent ning from querying the thread id on each log call if thread id is not needed" OFF)
option(NING_NO_TLS "prevent ning from using thread local storage" OFF)
option(
        NING_NO_ATOMIC_LEVELS
        "prevent ning from using of std::atomic log levels (use only if your code never modifies log levels concurrently"
        OFF)
option(NING_DISABLE_DEFAULT_LOGGER "Disable default logger creation" OFF)

# clang-tidy
if(${CMAKE_VERSION} VERSION_GREATER "3.5")
    option(NING_TIDY "run clang-tidy" OFF)
endif()

if(NING_TIDY)
    set(CMAKE_CXX_CLANG_TIDY "clang-tidy")
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
    message(STATUS "Enabled clang-tidy")
endif()

find_package(Threads REQUIRED)
message(STATUS "Build type: " ${CMAKE_BUILD_TYPE})
# ---------------------------------------------------------------------------------------
# Static/Shared library (shared not supported in windows yet)
# ---------------------------------------------------------------------------------------
set(NING_SRCS src/hello.cpp)

add_library(ning STATIC ${NING_SRCS} ${NING_ALL_HEADERS})

add_library(ning::ning ALIAS ning)

target_compile_definitions(ning PUBLIC NING_COMPILED_LIB)
target_include_directories(ning PUBLIC "$<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/include>"
        "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>")
target_link_libraries(ning PUBLIC Threads::Threads)
ning_enable_warnings(ning)

set_target_properties(ning PROPERTIES VERSION ${NING_VERSION} SOVERSION ${NING_VERSION_MAJOR})
set_target_properties(ning PROPERTIES DEBUG_POSTFIX d)

if(COMMAND target_precompile_headers AND NING_ENABLE_PCH)
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/pch.h.in ${PROJECT_BINARY_DIR}/ning_pch.h @ONLY)
    target_precompile_headers(ning PRIVATE ${PROJECT_BINARY_DIR}/ning_pch.h)
endif()

# ---------------------------------------------------------------------------------------
# Misc definitions according to tweak options
# ---------------------------------------------------------------------------------------
set(NING_WCHAR_TO_UTF8_SUPPORT ${NING_WCHAR_SUPPORT})
foreach(
        NING_OPTION
        NING_WCHAR_TO_UTF8_SUPPORT
        NING_WCHAR_FILENAMES
        NING_NO_EXCEPTIONS
        NING_CLOCK_COARSE
        NING_PREVENT_CHILD_FD
        NING_NO_THREAD_ID
        NING_NO_TLS
        NING_NO_ATOMIC_LEVELS
        NING_DISABLE_DEFAULT_LOGGER
        NING_USE_STD_FORMAT)
    if(${NING_OPTION})
        target_compile_definitions(ning PUBLIC ${NING_OPTION})
        target_compile_definitions(ning_header_only INTERFACE ${NING_OPTION})
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

    # ---------------------------------------------------------------------------------------
    # Support creation of installable packages
    # ---------------------------------------------------------------------------------------
    include(cmake/ningCPack.cmake)
endif()
