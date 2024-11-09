#! /usr/bin/env bash

# use podman in place of docker
podman run -ti --rm -p 8080:8080 -v ./nix:/home/nix --userns keep-id:uid=1000,gid=100 haskelious/nix-env:latest
