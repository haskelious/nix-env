{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs.buildPackages; [
    nodejs
    yarn
    git
    code-server
  ];

  shellHook = ''
    #! /usr/bin/env bash
    cat ~/.config/code-server/config.yaml
    code-server
  '';
}
