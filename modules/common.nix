{ config, pkgs, lib, ... }:

{
  # ============================================================
  # Boot
  # ============================================================
  boot.loader.systemd-boot.enable = true;
  # Both hosts upgrade daily without a person in the loop: a new entry that
  # fails to boot 3 times is skipped in favour of the previous one, and 10
  # generations (about 10 days) stay available to roll back to. A boot counts
  # as good once boot-complete.target is reached, which is early: this catches
  # kernel and boot failures, not a service that starts and misbehaves.
  boot.loader.systemd-boot.bootCounting.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
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
  # Security
  # ============================================================
  # sudo-rs — memory-safe Rust drop-in replacement for sudo.
  security.sudo.enable = false;
  security.sudo-rs.enable = true;

  # ============================================================
  # Users
  # ============================================================
  users.users.brandon = {
    isNormalUser = true;
    description = "Brandon Conway";
    extraGroups = [ "wheel" ];
  };

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

  # Keep as many system generations as the boot menu shows, GC everything
  # else weekly.
  nix.gc = {
    automatic = true;
    dates = "weekly";
  };
  systemd.services.nix-gc.script = lib.mkForce ''
    ${pkgs.nix}/bin/nix-env --delete-generations +${toString config.boot.loader.systemd-boot.configurationLimit} -p /nix/var/nix/profiles/system
    ${pkgs.nix}/bin/nix-store --gc
  '';

  nix.optimise.automatic = true;
}
