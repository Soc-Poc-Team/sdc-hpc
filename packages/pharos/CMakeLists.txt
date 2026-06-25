cmake_minimum_required(VERSION 3.10)
project(pharos)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# server

file(GLOB_RECURSE SOURCESD "server/*.cpp" "server/*.h")

add_executable(pharosd ${SOURCESD})

install(TARGETS pharosd DESTINATION bin)

# client

file(GLOB_RECURSE SOURCES "client/*.cpp" "client/*.h")

add_executable(pharos ${SOURCES})

install(TARGETS pharos DESTINATION bin)
