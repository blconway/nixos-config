{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/nvidia.nix
    ./modules/gnome.nix
    ./modules/audio.nix
  ];

  # ============================================================
  # Boot
  # ============================================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 3;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Compressed RAM swap — lightweight safety net for 64GB of RAM.
  zramSwap = {
    enable = true;
    memoryPercent = 12;
  };

  # ============================================================
  # Networking
  # ============================================================
  networking.hostName = "bc-ws";
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false; # no benefit on a desktop

  # DNS-over-TLS via systemd-resolved. Uses DHCP-assigned DNS servers
  # but upgrades to TLS when the server supports it.
  services.resolved = {
    enable = true;
    settings.Resolve.DNSOverTLS = "opportunistic";
  };

  # ============================================================
  # Locale
  # ============================================================
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # ============================================================
  # Hardware
  # ============================================================
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;

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

  # udev rules for Steam controllers, Valve hardware, and gaming peripherals.
  hardware.steam-hardware.enable = true;

  # OpenRGB — controls LEDs on Gigabyte motherboards, GPUs, RAM, etc.
  services.hardware.openrgb.enable = true;

  # ============================================================
  # Shell & Security
  # ============================================================
  programs.fish.enable = true;

  # sudo-rs — memory-safe Rust drop-in replacement for sudo.
  security.sudo.enable = false;
  security.sudo-rs.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # ============================================================
  # Services
  # ============================================================
  services.printing.enable = true;

  services.flatpak.enable = true;
  services.flatpak.remotes = [{
    name = "flathub";
    location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
  }];

  # ============================================================
  # Users
  # ============================================================
  users.users.brandon = {
    isNormalUser = true;
    description = "Brandon Conway";
    shell = pkgs.fish;
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # ============================================================
  # Packages
  # ============================================================
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vscode.fhs
    nh          # nicer nixos-rebuild wrapper with colored diffs
  ];

  # ============================================================
  # Nix settings
  # ============================================================
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Deprioritize the nix daemon so background builds don't stutter
  # audio or make the desktop laggy (especially with daily auto-upgrades).
  systemd.services.nix-daemon.serviceConfig = {
    CPUSchedulingPolicy = lib.mkForce "batch";
    IOSchedulingClass = lib.mkForce "idle";
    IOSchedulingPriority = lib.mkForce 7;
  };

  # Keep the last 3 system generations, GC everything else weekly.
  nix.gc = {
    automatic = true;
    dates = "weekly";
  };
  systemd.services.nix-gc.script = lib.mkForce ''
    ${pkgs.nix}/bin/nix-env --delete-generations +3 -p /nix/var/nix/profiles/system
    ${pkgs.nix}/bin/nix-store --gc
  '';

  nix.optimise.automatic = true;

  # Daily auto-upgrade — updates flake inputs and rebuilds.
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
