# Setup

This should work on a standard infra machine. Last tested on `quick-weevil`.

Requires conda to be installed.

```bash
set -euox pipefail

# minetest deps
sudo apt install g++ make libc6-dev cmake libpng-dev libjpeg-dev libxi-dev libgl1-mesa-dev libsqlite3-dev libogg-dev libvorbis-dev libopenal-dev libcurl4-gnutls-dev libfreetype6-dev zlib1g-dev libgmp-dev libjsoncpp-dev libzstd-dev libluajit-5.1-dev gettext capnproto libcapnp-dev xvfb libzmq3-dev -yq
# irrlicht deps
sudo apt-get install g++ cmake libsdl2-dev libpng-dev libjpeg-dev zlib1g-dev -yq

# not strictly necessary, but much faster build time
sudo apt-get install ninja-build mold -yq

git clone git@github.com:Astera-org/minetest.git
cd minetest
git checkout siboehm/gymInterface
git submodule update --init --recursive

cd lib/zmqpp
sudo make && sudo make install

cmake -B build -S . \
	-DCMAKE_FIND_FRAMEWORK=LAST \
	-DRUN_IN_PLACE=TRUE -DENABLE_GETTEXT=TRUE \
	-DBUILD_HEADLESS=1 \
	-GNinja \
	-DCMAKE_CXX_FLAGS="-fuse-ld=mold" \
	-DSDL2_DIR=lib/SDL/build/lib/cmake/SDL2/ \
	-DCMAKE_BUILD_TYPE=Debug \
	-DCMAKE_EXPORT_COMPILE_COMMANDS=1 && \
	cmake --build build

mamba env create && conda activate minetest
pushd python && pip install -e . && popd
pytest .
```
