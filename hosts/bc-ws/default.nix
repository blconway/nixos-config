{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/workstation.nix
    ../../modules/nvidia.nix
    ../../modules/gnome.nix
    ../../modules/audio.nix
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

  # udev rules for Steam controllers, Valve hardware, and gaming peripherals.
  hardware.steam-hardware.enable = true;

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
  services.flatpak.remotes = [{
    name = "flathub";
    location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
  }];

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
  system.autoUpgrade = {
    enable = true;
    flake = "/etc/nixos#bc-ws";
    flags = [
      "--update-input" "nixpkgs"
      "--update-input" "home-manager"
      "--update-input" "nix-flatpak"
    ];
    dates = "daily";
    allowReboot = false;
  };

  system.stateVersion = "25.11";
}
