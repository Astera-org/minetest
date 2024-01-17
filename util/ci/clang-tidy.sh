#! /bin/bash -eu

SDL2_DIR=$(pwd)/lib/SDL/build/lib/cmake/SDL2/

cmake -B build -DCMAKE_BUILD_TYPE=Debug \
	-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
	-DRUN_IN_PLACE=TRUE \
	-G Ninja \
	-DSDL2_DIR=$SDL2_DIR \
	-DENABLE_GETTEXT=FALSE \
	-DBUILD_SERVER=TRUE \
	-DBUILD_HEADLESS=FALSE
cmake --build build --target GenerateVersion

./util/ci/run-clang-tidy.py \
	-clang-tidy-binary=$CLANG_TIDY -p build \
	-quiet -config="$(cat .clang-tidy)" \
	'src/.*'
