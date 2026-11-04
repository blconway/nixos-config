{
  lib,
  pkgs,
  modulesPath,
  target,
  ...
}:

# Installer ISO for ai-fw: the NixOS minimal installer plus `install-ai-fw`,
# reachable over SSH with the same keys as ai-fw. Build it with
# `nix build .#ai-fw-installer-iso` (docs/DECISIONS.md, D12).
let
  t = target.config;
  uuidOf = fs: lib.removePrefix "/dev/disk/by-uuid/" t.fileSystems.${fs}.device;

  install-ai-fw = pkgs.writeShellApplication {
    name = "install-ai-fw";
    runtimeInputs = with pkgs; [
      parted
      dosfstools
      e2fsprogs
      util-linux
    ];
    text = ''
      ROOT_UUID=${lib.escapeShellArg (uuidOf "/")}
      BOOT_ID=${lib.escapeShellArg (lib.replaceStrings [ "-" ] [ "" ] (uuidOf "/boot"))}
      BOOT_OPTS=${lib.escapeShellArg (lib.concatStringsSep "," t.fileSystems."/boot".options)}
      FLAKE=${lib.escapeShellArg t.system.autoUpgrade.flake}
    ''
    + builtins.readFile ./install-ai-fw.sh;
  };
in
{
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

  nixpkgs.hostPlatform = "x86_64-linux";
  image.baseName = lib.mkForce "ai-fw-installer-${t.system.nixos.label}";

  # The kernel ai-fw itself runs, so its NIC and NVMe are surely supported.
  # The minimal installer's ZFS support doesn't build for the latest kernel.
  boot.kernelPackages = t.boot.kernelPackages;
  boot.supportedFilesystems.zfs = lib.mkForce false;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # sshd is on in the installer; root logs in with ai-fw's keys only.
  users.users.root.openssh.authorizedKeys.keys = t.users.users.brandon.openssh.authorizedKeys.keys;

  environment.systemPackages = [ install-ai-fw ];
}
