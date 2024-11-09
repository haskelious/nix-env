#! /usr/bin/env bash

# use podman in place of docker
docker=podman

# build nix-base docker image
nix-build nix-base.nix && \

# import image
${docker} load -i ./result && \

# build nix-env image on top of nix-base
${docker} build -t nix-env:latest -f Dockerfile && \
	
# clean up nix artifact
rm ./result
