#!/bin/bash
exec bin/minetest --name me --password whyisthisnecessary --address 0.0.0.0 --port 30000 --go --dumb --dumb-port "tcp://*:9000"  # --record --record-port "tcp://*:9001"
