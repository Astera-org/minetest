#! /bin/bash -e

set -x

SDL2_DIR=$(pwd)/lib/SDL/build/lib/cmake/SDL2/

cmake -B build -S . \
	-DCMAKE_FIND_FRAMEWORK=LAST \
	-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-Debug} \
	-DRUN_IN_PLACE=TRUE \
	-DSDL2_DIR=$SDL2_DIR \
	-G Ninja \
	-DENABLE_GETTEXT=${CMAKE_ENABLE_GETTEXT:-TRUE} \
	-DBUILD_SERVER=${CMAKE_BUILD_SERVER:-TRUE} \
	${CMAKE_FLAGS}

cmake --build build
