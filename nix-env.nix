{ pkgs ? import <nixpkgs> { overlays = [ (import ./overlay.nix) ]; } }:

let
  # define the nix user UID and GID
  uid = "1000";
  gid = "100";

  envs = pkgs.lib.fileset.toSource {
    root = ./.;
    fileset = ./envs;
  };

in pkgs.dockerTools.buildImage {
  inherit uid;
  inherit gid;

  name = "nix-env";
  tag = "latest";

  # build a base image with bash, core linux tools, nix tools, and certificates
  copyToRoot = pkgs.buildEnv {
    name = "env";
    pathsToLink = [ "/bin" "/etc" "/envs" ];
    paths =

      # dockerTools helper packages
      (with pkgs.dockerTools; [
        caCertificates
        usrBinEnv
        binSh
      ]) ++

      # minimal set of common shell requirements
      (with pkgs; [
        iana-etc
        bashInteractive
        busybox
        nix
      ]) ++

      # include example scripts to build dev environments
      [ envs ];
  };

  # set the entrypoint, user working folder, certificates env var
  # mount the home directory volume if it is used for persistence
  config = {
    # container will run as nix user
    WorkingDir = "/home/nix";
    Volumes = { "/home/nix" = { }; };
    User = "nix";

    # load the nix scripts at startup so that PATH is set
    Cmd = [ "bash" "--rcfile" "/etc/profile.d/nix.sh" ];

    # other common environment variables
    Env = [
      "PAGER=cat"
      "USER=nix"
      "NIX_PATH=nixpkgs=channel:nixos-unstable"
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
    mkdir -p /etc/nix && cat > /etc/nix/nix.conf << EOF
    experimental-features = nix-command flakes
    EOF

    # ensure tmp exists with correct permissions
    mkdir -p /tmp
    chmod 1777 /tmp
  '';
}
