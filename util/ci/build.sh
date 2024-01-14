#! /bin/bash -e

cmake -B build \
	-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-Debug} \
	-DRUN_IN_PLACE=TRUE \
	-DSDL2_DIR=lib/SDL/build/lib/cmake/SDL2/ \
	-DENABLE_GETTEXT=${CMAKE_ENABLE_GETTEXT:-TRUE} \
	-DBUILD_SERVER=${CMAKE_BUILD_SERVER:-TRUE} \
	${CMAKE_FLAGS}

cmake --build build --parallel $(($(nproc) + 1))
