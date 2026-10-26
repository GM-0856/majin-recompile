# majin - ReXGlue Recompiled Project
#
# SDK boilerplate lives in generated/rexglue.cmake.

cmake_minimum_required(VERSION 3.25)
project(majin LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(generated/rexglue.cmake)

# Sources
set(MAJIN_SOURCES
    src/main.cpp
    src/diagnostics.cpp
    src/timing.cpp
)

if(WIN32)
    add_executable(majin WIN32 ${MAJIN_SOURCES})
else()
    add_executable(majin ${MAJIN_SOURCES})
endif()

rexglue_setup_target(majin GPU_PLUGINS xenos)

# Separate opt-in research build. Never enabled by the normal build script.
option(MAJIN_1080P_STARTUP_PROBE "Probe engine startup dimensions; not validated 1080p" OFF)
if(MAJIN_1080P_STARTUP_PROBE)
    target_sources(majin PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/../experiments/1080p/startup_probe.cpp" "${CMAKE_CURRENT_SOURCE_DIR}/../experiments/1080p/game_trace.cpp")
endif()
