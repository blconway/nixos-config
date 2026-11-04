#!/usr/bin/env bash
# Evaluates each nixosConfiguration's system derivation without building it.
# Fails on unknown or removed options, failed assertions, and missing packages.
set -euo pipefail

hosts=$(nix eval --raw .#nixosConfigurations --apply 'c: builtins.concatStringsSep " " (builtins.attrNames c)')
[ -n "$hosts" ] || { echo "no nixosConfigurations found" >&2; exit 1; }

for host in $hosts; do
  echo "== $host"
  nix eval --raw ".#nixosConfigurations.$host.config.system.build.toplevel.drvPath"
  echo
done
