{ pkgs ? import <nixpkgs> { overlays = [ (import ./overlay.nix) ]; } }:

let
  # define the nix user UID and GID
  uid = "1000";
  gid = "100";

  envs = pkgs.lib.fileset.toSource {
    root = ./.;
    fileset = ./envs;
  };

  # container entrypoint to load the latest nix-unstable channel and
  # adds nix binaries to user path
  entrypointScript = pkgs.writeScriptBin "entrypoint.sh" ''
    #!/bin/bash
    set -e

    # Add the nixpkgs-unstable channel
    nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs

    # set the environment
    source /etc/profile.d/nix.sh

    # Execute the provided command
    exec "$@"
  '';

  system  = with pkgs; [ dockerTools.caCertificates bashInteractive busybox nix ];
  extra   = with pkgs; [ entrypointScript envs ];

in pkgs.dockerTools.buildImage {
  name = "nix-env";
  tag = "latest";

  compressor = "gz";

  # build a base image with bash, core linux tools, nix tools, and certificates
  copyToRoot = pkgs.buildEnv {
    name = "env";
    paths = system ++ extra;
  };

  inherit uid;
  inherit gid;

  # set the entrypoint, user working folder, certificates env var
  # mount the home directory volume if it is used for persistence
  config = {
    Cmd = [ "bash" ];
    Entrypoint = [ "${entrypointScript}/bin/entrypoint.sh" ];
    WorkingDir = "/home/nix";
    Volumes = { "/home/nix" = { }; };
    User = "nix";
    Env = [
      "PAGER=cat"
      "USER=nix"
    ];
  };

  # finalize the image building by adding necessary components to get
  # a functional nix environment: nixbld group, users, and nix.conf
  runAsRoot = ''
    #!${pkgs.runtimeShell}
    ${pkgs.dockerTools.shadowSetup}

    # create the necessary groups
    groupadd -g ${gid} users

    # create the nix user
    useradd -m -u ${uid} -g ${gid} -s /bin/bash -G users nix

    # configure nix
    mkdir -p /etc/nix
    cat > /etc/nix/nix.conf << EOF
    experimental-features = nix-command flakes
    EOF

    # set tmp permissions
    chmod 1777 /tmp
  '';
}
