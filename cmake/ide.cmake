# ---------------------------------------------------------------------------------------
# IDE support for headers
# ---------------------------------------------------------------------------------------
set(NING_HEADERS_DIR "${CMAKE_CURRENT_LIST_DIR}/../include")

file(GLOB NING_TOP_HEADERS "${NING_HEADERS_DIR}/*.h")

set(NING_ALL_HEADERS ${NING_TOP_HEADERS} )

source_group("Header Files\\NING" FILES ${NING_TOP_HEADERS})
