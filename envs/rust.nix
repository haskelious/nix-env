{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs.buildPackages; [
    rustc
    cargo
    clippy
    rustfmt
    rust-analyzer
    git
    code-server
  ];

  RUST_SRC_PATH="${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

  shellHook = ''
    #! /usr/bin/env bash

    # see https://nixos.wiki/wiki/Development_environment_with_nix-shell#Troubleshooting
    export NIX_ENFORCE_PURITY=0

    code-server --install-extension rust-lang.rust-analyzer && \
    ln -sf /nix/store/*-rust-analyzer-*/bin/rust-analyzer ~/.local/share/code-server/extensions/rust-lang.rust-analyzer-*/server/

    (sleep 2; cat ~/.config/code-server/config.yaml) &
    code-server
  '';
}
