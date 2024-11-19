#!/usr/bin/env bash

set -euo pipefail

cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null

build_with_compiler() {
    local cc="$1"
    local cxx="$2"
    local san="$3"

    export CC="$cc"
    export CXX="$cxx"

    local build_dir="build-$cxx-$san"

    cmake -B "$build_dir" -S . \
        -DCMAKE_C_COMPILER="$cc" \
        -DCMAKE_CXX_COMPILER="$cxx" \
        -DCMAKE_FIND_FRAMEWORK=LAST \
        -DRUN_IN_PLACE=TRUE \
        -DENABLE_SOUND=FALSE \
        -DENABLE_GETTEXT=TRUE \
        -GNinja \
        -DUSE_SDL2=ON \
        -DSANITIZER="$3" \
        -DCMAKE_CXX_LINK_FLAGS="-fuse-ld=mold" \
        -DCMAKE_BUILD_TYPE=Debug \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=1 \
        -DCMAKE_COLOR_DIAGNOSTICS=ON \
        -DBUILD_SERVER=ON

    cmake --build "$build_dir" -j "$(nproc)"
}

build_with_compiler gcc-14 g++-14 none
# build_with_compiler gcc-14 g++-14 ubsan
# build_with_compiler gcc-14 g++-14 asan
build_with_compiler clang-18 clang++-18 none
# build_with_compiler clang-18 clang++-18 ubsan
# build_with_compiler clang-18 clang++-18 asan
