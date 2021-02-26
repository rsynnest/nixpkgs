#!/usr/bin/env bash

# build VM
nixos-rebuild build-vm --fast -I nixos-config=./configuration.nix -I nixpkgs=.

# run VM
QEMU_NET_OPTS="hostfwd=tcp::2222-:22" ./result/bin/run-nixos-vm -display none &

# connect to VM
ssh -p 2222 rsynnest@localhost
