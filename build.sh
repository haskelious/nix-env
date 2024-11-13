#! /usr/bin/env bash

docker=podman

# build nix-base docker image
nix-build --quiet --log-format bar nix-env.nix && \

# import image
${docker} load -i ./result && \

# clean up nix artifact
rm ./result
