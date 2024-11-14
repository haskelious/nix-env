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
  name = "nix-env";
  tag = "latest";

  # build a base image with bash, core linux tools, nix tools, and certificates
  copyToRoot = pkgs.buildEnv {
    name = "env";
    paths = with pkgs; [
      dockerTools.caCertificates
      dockerTools.usrBinEnv
      dockerTools.binSh
      bashInteractive
      busybox
      iana-etc
      nix
      envs
    ];
    pathsToLink = [ "/bin" "/etc" "/envs" ];
  };

  inherit uid;
  inherit gid;

  # set the entrypoint, user working folder, certificates env var
  # mount the home directory volume if it is used for persistence
  config = {
    Cmd = [ "bash" "--rcfile" "/etc/profile.d/nix.sh" ];
    WorkingDir = "/home/nix";
    Volumes = { "/home/nix" = { }; };
    User = "nix";
    Env = [
      "PAGER=cat"
      "USER=nix"
      "ENV=/etc/profile.d/nix.sh"
      "BASH_ENV=/etc/profile.d/nix.sh"
      "NIX_BUILD_SHELL=/bin/bash"
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
    mkdir -p /etc/nix
    cat > /etc/nix/nix.conf << EOF
    experimental-features = nix-command flakes
    EOF

    # set tmp permissions
    chmod 1777 /tmp
  '';
}
