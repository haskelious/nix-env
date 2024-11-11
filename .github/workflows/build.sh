name: Build image

on:
    push:
        branches:
            - main

jobs:
    build:
        runs-on: ubuntu-latest

        steps:
        - name: Checkout repository
            uses: actions/checkout@v2

        - name: Set up Nix
            uses: cachix/install-nix-action@v13

        - name: Build with nix-build
            run: nix-build nix-base.nix && mv result result.tar.gz

        - name: Upload artifact
            uses: actions/upload-artifact@v2
            with:
                name: build-artifact
                path: result.tar.gz
