FROM ubuntu:22.04 AS dev

# Use apt in docker best practices, see https://docs.docker.com/reference/dockerfile/#example-cache-apt-packages.
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    # ca-certificates is needed to install pixi
    ca-certificates \
    # curl is needed to install pixi
    curl \
    # add-apt-repository
    software-properties-common gpg-agent

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    add-apt-repository ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc-13 g++-13 libgl1-mesa-dev \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 60 --slave /usr/bin/g++ g++ /usr/bin/g++-13

RUN curl -fsSL https://pixi.sh/install.sh | PIXI_VERSION=v0.34.0 PIXI_HOME=/usr PIXI_NO_PATH_UPDATE=1 bash

WORKDIR /workspace



FROM dev AS build

COPY --link pixi.toml pixi.lock ./
COPY --link python/pyproject.toml python/
RUN mkdir python/minetest

RUN pixi install

COPY .git/ .git/
COPY CMakeLists.txt README.md minetest.conf.example ./
COPY builtin/ builtin/
COPY client/ client/
COPY clientmods/ clientmods/
COPY cmake/ cmake/
COPY doc/ doc/
COPY fonts/ fonts/
COPY games/ games/
COPY lib/ lib/
COPY misc/ misc/
COPY mods/ mods/
COPY po/ po/
COPY python/ python/
COPY src/ src/
COPY textures/ textures/
COPY worlds/ worlds/

RUN pixi run -- cmake -B build \
        -DCMAKE_CXX_FLAGS="-fuse-ld=mold" \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=1 \
        -DENABLE_GETTEXT=TRUE \
        -DENABLE_SOUND=FALSE \
        -DRUN_IN_PLACE=TRUE \
        -DUSE_SDL2=ON \
        -DBUILD_CLIENT=FALSE \
        -DBUILD_SERVER=TRUE \
        -DBUILD_UNITTESTS=FALSE \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_FIND_FRAMEWORK=LAST \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DENABLE_PROMETHEUS=TRUE \
        -GNinja && \
	pixi run -- cmake --build build && \
    pixi run -- cmake --install build
