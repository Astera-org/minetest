ARG DOCKER_IMAGE=ubuntu:22.04

FROM $DOCKER_IMAGE AS dev

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && apt-get install -y --no-install-recommends \
        wget \
        ca-certificates \
        gnupg \
        lsb-release \
        software-properties-common \
		cmake \
		ninja-build \
		pkg-config \
		build-essential \
		mold \
		git \
		gettext \
		# postgresql POSTGRES \
		libpng-dev \
		libjpeg-dev \
		libgl1-mesa-dev \
		libxi-dev \
		libfreetype-dev \
		libsqlite3-dev \
		# libhiredis-dev REDIS \
		# libogg-dev SOUND \
		libgmp-dev \
		# libvorbis-dev SOUND \
		# libopenal-dev SOUND \
		# libpq-dev POSTGRES \
		libleveldb-dev \
		libzstd-dev \
		libcapnp-dev \
		capnproto \
		libluajit-5.1-dev \
		libcurl4-openssl-dev

# Using the llvm provided installation script so it's easy to install different/newer versions of clang.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt,sharing=locked \
	wget -qO- https://apt.llvm.org/llvm.sh | bash -s -- 18

WORKDIR /usr/src/

RUN git clone --recursive https://github.com/libspatialindex/libspatialindex \
	&& cd libspatialindex \
	&& git checkout -b build 2.1.0 \
	&& cmake -B build \
		-DCMAKE_C_COMPILER=clang-18 \
		-DCMAKE_CXX_COMPILER=clang++-18 \
		-DCMAKE_INSTALL_PREFIX=/usr/local \
	&& cmake --build build -j "$(nproc)" \
	&& cmake --install build

# ARG LUAJIT_VERSION=v2.1

# RUN git clone --recursive https://github.com/LuaJIT/LuaJIT.git luajit -b $LUAJIT_VERSION \
# 	&& cd luajit \
# 	&& make amalg CC=clang-18 -j "$(nproc)" \
# 	&& make install

FROM dev AS build

WORKDIR /usr/src/minetest

COPY .git .git
COPY CMakeLists.txt CMakeLists.txt
COPY README.md README.md
COPY minetest.conf.example minetest.conf.example
COPY builtin builtin
COPY cmake cmake
COPY doc doc
COPY fonts fonts
COPY lib lib
COPY misc misc
COPY po po
COPY src src
COPY irr irr
COPY textures textures
COPY minetest-gymnasium/minetest/proto/remoteclient.capnp minetest-gymnasium/minetest/proto/remoteclient.capnp

RUN cmake -B build -S . \
        -DCMAKE_C_COMPILER=clang-18 \
        -DCMAKE_CXX_COMPILER=clang++-18 \
        -DCMAKE_FIND_FRAMEWORK=LAST \
		# -DCMAKE_INSTALL_PREFIX=/usr/local \
		-DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_LINK_FLAGS="-fuse-ld=mold" \
        -DCMAKE_BUILD_TYPE=Debug \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=1 \
        -DCMAKE_COLOR_DIAGNOSTICS=TRUE \
        -GNinja \
        -DSANITIZER=ubsan \
		-DRUN_IN_PLACE=TRUE \
		-DBUILD_UNITTESTS=FALSE \
		-DBUILD_BENCHMARKS=FALSE \
		-DBUILD_DOCUMENTATION=FALSE \
		-DBUILD_SERVER=ON \
		# Build with (n)curses; Enables a server side terminal (command line option: --terminal)
		-DENABLE_CURSES=FALSE \
		# Build with Gettext; Allows using translations
		-DENABLE_GETTEXT=ON \
		# Build with LevelDB; Enables use of LevelDB map backend
		-DENABLE_LEVELDB=ON \
		# Build with libpq; Enables use of PostgreSQL map backend (PostgreSQL 9.5 or greater recommended)
		-DENABLE_POSTGRESQL=FALSE \
		# Build with libhiredis; Enables use of Redis map backend
		-DENABLE_REDIS=FALSE \
		# Build with LibSpatial; Speeds up AreaStores
		-DENABLE_SPATIAL=ON \
		# Build with OpenAL, libogg & libvorbis; in-game sounds
		-DENABLE_SOUND=FALSE \
		# Build with LuaJIT (much faster than non-JIT Lua)
		-DENABLE_LUAJIT=ON \
		# Build with Prometheus metrics exporter (listens on tcp/30000 by default)
		-DENABLE_PROMETHEUS=FALSE \
		# Use GMP from system (much faster than bundled mini-gmp)
		-DENABLE_SYSTEM_GMP=ON \
    && cmake --build build -j "$(nproc)"

FROM $DOCKER_IMAGE AS runtime

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && apt-get install -y --no-install-recommends \
        # wget \
        ca-certificates \
        # gnupg \
        # lsb-release \
        # software-properties-common \
		# cmake \
		# ninja-build \
		# pkg-config \
		# build-essential \
		# mold \
		# git \
		gettext \
		# postgresql POSTGRES \
		libpng-dev \
		libjpeg-dev \
		libgl1-mesa-dev \
		libxi-dev \
		libfreetype-dev \
		libsqlite3-dev \
		# libhiredis-dev REDIS \
		# libogg-dev SOUND \
		libgmp-dev \
		# libvorbis-dev SOUND \
		# libopenal-dev SOUND \
		# libpq-dev POSTGRES \
		libleveldb-dev \
		libzstd-dev \
		libcapnp-dev \
		# capnproto \
		libluajit-5.1-dev \
		libcurl4-openssl-dev \
		libatomic1

# COPY doesn't preserve symlinks
COPY --from=build /usr/local/lib/libspatialindex.so.8.0.0 /usr/local/lib/
COPY --from=build /usr/local/lib/libspatialindex_c.so.8.0.0 /usr/local/lib/
RUN ln -s ./libspatialindex.so.8.0.0 /usr/local/lib/libspatialindex.so.8 \
	&& ln -s ./libspatialindex_c.so.8.0.0 /usr/local/lib/libspatialindex_c.so.8

WORKDIR /usr/src/minetest

COPY --from=build /usr/src/minetest/bin bin

# COPY .git .git
# COPY CMakeLists.txt CMakeLists.txt
COPY README.md README.md
COPY minetest.conf.example minetest.conf.example
COPY builtin builtin
# COPY cmake cmake
COPY doc doc
COPY fonts fonts
# COPY lib lib
COPY misc misc
COPY po po
# COPY src src
# COPY irr irr
COPY textures textures
# COPY minetest-gymnasium/minetest/proto/remoteclient.capnp minetest-gymnasium/minetest/proto/remoteclient.capnp
COPY mods mods
COPY games games
COPY worlds worlds

