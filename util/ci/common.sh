#!/bin/bash -e

set -x

# Linux build only
install_linux_deps() {
	local pkgs=(
		cmake gettext postgresql
		libpng-dev libjpeg-dev libxi-dev libgl1-mesa-dev
		libsqlite3-dev libhiredis-dev libogg-dev libgmp-dev libvorbis-dev
		libopenal-dev libpq-dev libleveldb-dev libcurl4-openssl-dev libzstd-dev
		capnproto libcapnp-dev xvfb
		libzmq3-dev
	)

	if [[ "$1" == "--no-irr" ]]; then
		shift
	else
		local ver=$(cat misc/irrlichtmt_tag.txt)
		wget "https://github.com/minetest/irrlicht/releases/download/$ver/ubuntu-bionic.tar.gz"
		sudo tar -xaf ubuntu-bionic.tar.gz -C /usr/local
	fi

	sudo apt-get update
	sudo apt-get install -y "${pkgs[@]}" "$@"

	sudo systemctl start postgresql.service
	sudo -u postgres psql <<<"
		CREATE USER minetest WITH PASSWORD 'minetest';
		CREATE DATABASE minetest;
	"

	git submodule update --init --recursive

	pushd lib/zmqpp && make -j $(nproc) && sudo make install && popd
	pushd lib/SDL && mkdir -p build
	pushd build && ../configure --prefix=$(pwd) && make -j $(nproc) && make install && popd && popd
}

# macOS build only
install_macos_deps() {
	local pkgs=(
		cmake gettext freetype gmp jpeg-turbo jsoncpp leveldb
		libogg libpng libvorbis luajit zstd zmqpp
	)
	export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1
	export HOMEBREW_NO_INSTALL_CLEANUP=1
	# contrary to how it may look --auto-update makes brew do *less*
	brew update --auto-update
	brew install --display-times "${pkgs[@]}"
	brew unlink $(brew ls --formula)
	brew link "${pkgs[@]}"
}

install_mambaforge() {
	# Download Mambaforge installer
	wget -qO- https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh -O mambaforge.sh

	# Install Mambaforge silently
	bash mambaforge.sh -b -p $HOME/mambaforge

	# Remove installer
	rm mambaforge.sh

	# Initialize Mambaforge
	eval "$($HOME/mambaforge/bin/conda shell.bash hook)"

	# Update Mamba
	mamba update -n base -c defaults mamba
}
