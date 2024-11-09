#! /usr/bin/env bash

# login to docker with a PAT token
echo "enter your dockerhub PAT token"
docker login -u haskelious

# tag the image to publish
docker tag localhost/nix-env:latest haskelious/nix-env:latest

# push the image
docker push haskelious/nix-env:latest
