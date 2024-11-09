{ pkgs ? import <nixpkgs> { } }:

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
    if [ ! -d /home/nix/.local/state/nix/profiles/channels/nixpkgs/pkgs ]; then
      nix-channel --update
    fi

    # set the environment
    source /etc/profile.d/nix.sh

    # Execute the provided command
    exec "$@"
  '';

in pkgs.dockerTools.buildImage {
  name = "nix-base";
  tag = "latest";

  # build a base image with bash, core linux tools, nix tools, and certificates
  copyToRoot = pkgs.buildEnv {
    name = "nix-base";
    paths = with pkgs; [
      bashInteractive
      busybox
      nix
      cacert
      entrypointScript
      envs
   ];
  };

  # set the entrypoint, user working folder, certificates env var
  # mount the home directory volume if it is used for persistence
  config = {
    Cmd = [ "bash" ];
    Entrypoint = [ "${entrypointScript}/bin/entrypoint.sh" ];
    WorkingDir = "/home/nix";
    Env = [
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "PAGER=cat"
    ];
    Volumes = { "/home/nix" = { }; };
  };

  # finalize the image building by adding necessary components to get
  # a functional nix environment: nixbld group, users, and nix.conf
  runAsRoot = ''
    #!${pkgs.runtimeShell}
    ${pkgs.dockerTools.shadowSetup}

    # create the necessary groups
    groupadd -g ${gid} users
    groupadd -g 30000 nixbld

    # create the nix user
    useradd -m -u ${uid} -g ${gid} -s /bin/bash -G users,nixbld nix

    # create the nixbld users
    for i in $(seq 1 10); do \
      useradd -m -d /var/empty -g nixbld -G nixbld nixbld$i; \
    done

    # configure nix
    mkdir -p /etc/nix
    cat > /etc/nix/nix.conf << EOF
    build-users-group = nixbld
    experimental-features = nix-command flakes
    EOF

    # set tmp permissions
    chmod 1777 /tmp
  '';
}
