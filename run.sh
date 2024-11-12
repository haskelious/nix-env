#! /usr/bin/env bash

docker run -ti --rm -p 8080:8080 -v ./nix:/home/nix --userns keep-id:uid=1000,gid=100 nix-env:latest
