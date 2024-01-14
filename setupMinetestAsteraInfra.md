# Setup

This should work on a standard infra machine. Last tested on `quick-weevil`.

Requires conda to be installed.

```bash
set -euox pipefail

git clone git@github.com:Astera-org/minetest.git
cd minetest
git checkout siboehm/gymInterface
git submodule update --init --recursive

sudo apt install clang
export CXX=clang

# minetest deps
sudo apt install g++ make libc6-dev cmake libpng-dev libjpeg-dev libxi-dev libgl1-mesa-dev libsqlite3-dev libogg-dev libvorbis-dev libopenal-dev libcurl4-gnutls-dev libfreetype6-dev zlib1g-dev libgmp-dev libjsoncpp-dev libzstd-dev libluajit-5.1-dev gettext capnproto libcapnp-dev xvfb
# irrlicht deps
sudo apt-get install g++ cmake libsdl2-dev libpng-dev libjpeg-dev zlib1g-dev

# zmq, follow [README](https://github.com/zeromq/libzmq#installation)
# For 22.04:
# unclear if add this repo is necessary
echo 'deb http://download.opensuse.org/repositories/network:/messaging:/zeromq:/release-stable/xUbuntu_22.04/ /' | sudo tee /etc/apt/sources.list.d/network:messaging:zeromq:release-stable.list
curl -fsSL https://download.opensuse.org/repositories/network:messaging:zeromq:release-stable/xUbuntu_22.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/network_messaging_zeromq_release-stable.gpg > /dev/null
sudo apt update && sudo apt install libzmq3-dev

cd ~

# zmqpp
git clone https://github.com/zeromq/zmqpp.git
cd zmqpp && make && make install

cd ~/minetest

mkdir -p ./build
cmake -B build -S . \
	-DCMAKE_FIND_FRAMEWORK=LAST \
	-DRUN_IN_PLACE=TRUE -DENABLE_GETTEXT=TRUE \
	-DBUILD_HEADLESS=1 \
	-DSDL2_DIR=lib/SDL/build/lib/cmake/SDL2/ \
	-DCMAKE_BUILD_TYPE=Debug \
	-DCMAKE_EXPORT_COMPILE_COMMANDS=1 && \
	cmake --build build

mamba env create && conda activate minetest
pushd python && pipe install -e . && popd
pytest .
```
