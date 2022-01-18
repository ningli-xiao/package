# ---------------------------------------------------------------------------------------
# IDE support for headers
# ---------------------------------------------------------------------------------------
file(GLOB NING_TOP_HEADERS "${CMAKE_CURRENT_LIST_DIR}/../include/*.h"
        "${CMAKE_CURRENT_LIST_DIR}/../src/*.h"
)

set(NING_ALL_HEADERS ${NING_TOP_HEADERS} )

source_group("Header Files\\NING" FILES ${NING_TOP_HEADERS})
