{
  lib,
  pkgs,
  modulesPath,
  target,
  ...
}:

# Installer ISO for ai-fw: the NixOS minimal installer plus `install-ai-fw`,
# run at its console. Build it with `nix build .#ai-fw-installer-iso`
# (docs/DECISIONS.md, D12). To run it over SSH instead, set a temporary root
# password at the console (`sudo passwd root`); the installer's sshd accepts it.
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

  environment.systemPackages = [ install-ai-fw ];
}
