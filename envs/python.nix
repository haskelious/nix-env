{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs.buildPackages; [
    python3
    git
    code-server
  ];

  LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib/";

  shellHook = ''
    #! /usr/bin/env bash
    cat ~/.config/code-server/config.yaml
    code-server
  '';
}
