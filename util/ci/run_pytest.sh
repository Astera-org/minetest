#!/bin/bash -e

set -x

mamba activate minetest
echo $(which python)
python -m pytest -v .
