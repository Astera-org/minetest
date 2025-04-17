ARG DOCKER_IMAGE=ubuntu:22.04

FROM $DOCKER_IMAGE AS dev

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && apt-get install -y --no-install-recommends \
        wget \
        ca-certificates \
        cmake \
        ninja-build \
        pkg-config \
        build-essential \
        git \
        gettext \
        libpng-dev \
        libjpeg-dev \
        libgl1-mesa-dev \
        libxi-dev \
        libfreetype-dev \
        libsqlite3-dev \
        libgmp-dev \
        libzstd-dev \
        libcapnp-dev \
        capnproto \
        libcurl4-openssl-dev

# Install virtualgl for vglrun
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    wget https://sourceforge.net/projects/virtualgl/files/3.1/virtualgl_3.1_amd64.deb \
    && apt install -y --no-install-recommends ./virtualgl_3.1_amd64.deb \
    && rm virtualgl_3.1_amd64.deb

WORKDIR /usr/src/

# There is no apt package.
RUN git clone --recursive https://github.com/libspatialindex/libspatialindex \
    && cd libspatialindex \
    && git checkout -b build 2.1.0 \
    && cmake -B build \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
    && cmake --build build -j "$(nproc)" \
    && cmake --install build

ARG LUAJIT_VERSION=v2.1

# The apt package is old, so build from source.
RUN git clone --recursive https://github.com/LuaJIT/LuaJIT.git luajit -b $LUAJIT_VERSION \
    && cd luajit \
    && make amalg -j "$(nproc)" \
    && make install

# The apt package libsdl2-dev is not compiled with SDL_OFFSCREEN=TRUE, so build from source.
RUN git clone https://github.com/libsdl-org/SDL sdl \
    && cd sdl \
    && cmake -B build -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build -j "$(nproc)" \
    && cmake --install build

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
        -DCMAKE_FIND_FRAMEWORK=LAST \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_BUILD_TYPE=Debug \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=1 \
        -DCMAKE_COLOR_DIAGNOSTICS=TRUE \
        -DSANITIZER=ubsan \
        -DRUN_IN_PLACE=TRUE \
        -DBUILD_UNITTESTS=FALSE \
        -DBUILD_BENCHMARKS=FALSE \
        -DBUILD_DOCUMENTATION=FALSE \
        -DUSE_SDL2=ON \
        -DENABLE_CURSES=OFF \
        -DENABLE_GETTEXT=ON \
        -DENABLE_LEVELDB=OFF \
        -DENABLE_POSTGRESQL=OFF \
        -DENABLE_REDIS=OFF \
        -DENABLE_SPATIAL=ON \
        -DENABLE_SOUND=OFF \
        -DENABLE_LUAJIT=ON \
        -DENABLE_PROMETHEUS=OFF \
        -DENABLE_SYSTEM_GMP=ON \
        -GNinja \
    && cmake --build build -j "$(nproc)"

FROM $DOCKER_IMAGE AS runtime

# build-essential for bin/minetest: error while loading shared libraries: libubsan.so.1: cannot open shared object file: No such file or directory

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && apt-get install -y --no-install-recommends \
        ca-certificates \
        gettext \
        build-essential \
        libpng-dev \
        libjpeg-dev \
        libgl1-mesa-dev \
        libxi-dev \
        libfreetype-dev \
        libsqlite3-dev \
        libgmp-dev \
        libleveldb-dev \
        libzstd-dev \
        libcapnp-dev \
        libcurl4-openssl-dev \
        libatomic1

# COPY doesn't preserve symlinks
COPY --from=build /usr/local/lib/libspatialindex.so.8.0.0 /usr/local/lib/
COPY --from=build /usr/local/lib/libspatialindex_c.so.8.0.0 /usr/local/lib/
RUN ln -s ./libspatialindex.so.8.0.0 /usr/local/lib/libspatialindex.so.8 \
    && ln -s ./libspatialindex_c.so.8.0.0 /usr/local/lib/libspatialindex_c.so.8

COPY --from=build /usr/local/lib/libluajit-5.1.a /usr/local/lib/
COPY --from=build /usr/local/lib/libluajit-5.1.so.2.1* /usr/local/lib/libluajit-5.1.so.2.1
RUN ln -s ./libluajit-5.1.so.2 /usr/local/lib/libluajit-5.1.so \
    && ln -s ./libluajit-5.1.so.2.1 /usr/local/lib/libluajit-5.1.so.2

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
