FROM localhost/nix-base:latest

# make necessary folders for a fully functional nix environment
# set permissions of nix folder to the nix user
RUN mkdir -p /nix/var/nix && \
    chown -R nix:users /nix && \
    chmod -R u+w /nix

# run container as non-privileged nix user
USER nix
ENV USER=nix
