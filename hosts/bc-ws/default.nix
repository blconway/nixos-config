{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/workstation.nix
    ../../modules/nvidia.nix
    ../../modules/gnome.nix
    ../../modules/audio.nix
    ../../modules/gaming.nix
    ../../modules/dev.nix
  ];

  # ============================================================
  # Networking
  # ============================================================
  networking.hostName = "bc-ws";
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false; # no benefit on a desktop

  # ============================================================
  # Hardware (desktop-specific)
  # ============================================================
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;

  # OpenRGB — controls LEDs on Gigabyte motherboards, GPUs, RAM, etc.
  services.hardware.openrgb.enable = true;

  # ============================================================
  # Fonts
  # ============================================================
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    jetbrains-mono
    nerd-fonts.jetbrains-mono
  ];

  # ============================================================
  # Services (desktop-specific)
  # ============================================================
  services.printing.enable = true;

  services.flatpak.enable = true;
  services.flatpak.remotes = [
    {
      name = "flathub";
      location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    }
  ];

  # ============================================================
  # Users (desktop-specific groups)
  # ============================================================
  users.users.brandon.extraGroups = [ "networkmanager" ];

  # ============================================================
  # Packages (desktop-specific)
  # ============================================================
  environment.systemPackages = with pkgs; [
    vscode.fhs
  ];

  # ============================================================
  # Auto-upgrade
  # ============================================================
  # Builds main's flake.lock, which CI bumps daily (D5); nothing updates the
  # lock on this machine, so it never drifts from main. "boot" stages the new
  # generation for the next reboot instead of switching under a running
  # session: switching to a new NVIDIA driver while the old kernel module is
  # loaded breaks GL and CUDA ("API mismatch") until a reboot anyway.
  system.autoUpgrade = {
    enable = true;
    flake = "github:blconway/nixos-config#bc-ws";
    operation = "boot";
    dates = "daily";
    allowReboot = false;
  };

  system.stateVersion = "25.11";
}
