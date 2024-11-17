#!/usr/bin/env bash

set -euo pipefail

cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null

build_with_compiler() {
	export CC="$1"
    export CXX="$2"

    local build_dir="build-$CXX"

    cmake -B "$build_dir" -S . \
		-DCMAKE_C_COMPILER="$1" \
		-DCMAKE_CXX_COMPILER="$2" \
		-DCMAKE_FIND_FRAMEWORK=LAST \
		-DRUN_IN_PLACE=TRUE \
		-DENABLE_SOUND=FALSE \
		-DENABLE_GETTEXT=TRUE \
		-GNinja \
		-DUSE_SDL2=ON \
		-DSANITIZER="none" \
		-DCMAKE_CXX_LINK_FLAGS="-fuse-ld=mold" \
		-DCMAKE_BUILD_TYPE=Debug \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=1 \
		-DCMAKE_COLOR_DIAGNOSTICS=ON \
		-DBUILD_SERVER=ON

    cmake --build "$build_dir" -j "$(nproc)"
}

build_with_compiler gcc-14 g++-14

build_with_compiler clang-18 clang++-18
