{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs.buildPackages; [
    clang
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
    cat ~/.config/code-server/config.yaml
    code-server
  '';
}