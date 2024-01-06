#!/bin/bash -e

# Linux build only
install_linux_deps() {
	# ZMQ is not available in the default repos for 22.04
	echo 'deb http://download.opensuse.org/repositories/network:/messaging:/zeromq:/release-stable/xUbuntu_22.04/ /' | sudo tee /etc/apt/sources.list.d/network:messaging:zeromq:release-stable.list
	curl -fsSL https://download.opensuse.org/repositories/network:messaging:zeromq:release-stable/xUbuntu_22.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/network_messaging_zeromq_release-stable.gpg > /dev/null

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
