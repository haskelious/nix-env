#! /usr/bin/env bash

# build nix-base docker image
nix-build --log-format bar nix-base.nix && \

# import image
docker load -i ./result && \

# build nix-env image on top of nix-base
docker build -t nix-env:latest -f Dockerfile && \
	
# clean up nix artifact
rm ./result
