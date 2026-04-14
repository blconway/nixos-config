{ config, pkgs, lib, ... }:

{
  # ============================================================
  # Boot
  # ============================================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 3;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Compressed RAM swap — lightweight safety net.
  zramSwap = {
    enable = true;
    memoryPercent = 12;
  };

  # ============================================================
  # Networking (shared)
  # ============================================================
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
  # Users
  # ============================================================
  users.users.brandon = {
    isNormalUser = true;
    description = "Brandon Conway";
    shell = pkgs.fish;
    extraGroups = [ "wheel" ];
  };

  # ============================================================
  # Packages
  # ============================================================
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    nh
  ];

  # ============================================================
  # Nix settings
  # ============================================================
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Deprioritize the nix daemon so background builds don't stutter
  # audio or make the desktop laggy.
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
}
