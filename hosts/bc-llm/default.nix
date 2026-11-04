{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/llm-server.nix
  ];

  # ============================================================
  # Networking
  # ============================================================
  networking.hostName = "bc-llm";
  networking.useDHCP = lib.mkDefault true;

  # ============================================================
  # SSH
  # ============================================================
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Brute-force protection for SSH.
  services.fail2ban.enable = true;

  # Copied from https://github.com/blconway.keys on 2026-11-04.
  users.users.brandon.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGJ4B8Q/IX1O5F9O2HysY9Q5JB4oVLtoeBNRTCPAASGe"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEE1vma8Ns/m8PjIVA+GwYDvp+aCVmvB62m0OLGisflF"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINoIDuNrI0kPi6jgVQF4OFzSBgQeWW1zDp9tjhG+UzYO"
  ];

  # ============================================================
  # Tailscale VPN
  # ============================================================
  services.tailscale.enable = true;

  # ============================================================
  # Firewall
  # ============================================================
  # Only SSH is open on the LAN, kept as a way in if Tailscale breaks.
  # The llama.cpp API is reachable over the tailnet only.
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    trustedInterfaces = [ "tailscale0" ];  # all ports open on tailnet
  };

  # ============================================================
  # AMD GPU — Strix Halo iGPU (Radeon 8060S, RDNA 3.5, gfx1151)
  # ============================================================
  hardware.graphics.enable = true;  # Mesa RADV, used by llama.cpp's Vulkan backend

  # Let the iGPU map up to 112 GiB as GTT (unified memory) so the ~94 GB model
  # plus its KV cache fits. Assumes the 128 GB board; lower it on a 64 GB one.
  # Units are 4 KiB pages: 112 * 262144.
  # Check after boot: cat /sys/class/drm/card*/device/mem_info_gtt_total
  boot.kernelParams = [
    "ttm.pages_limit=29360128"
    "ttm.page_pool_size=29360128"
  ];

  # ============================================================
  # Auto-upgrade
  # ============================================================
  # Persist journal across reboots for debugging.
  services.journald.settings.Journal.Storage = "persistent";

  # Builds whatever flake.lock is on main; it never updates the lock itself.
  # The weekly lock-update PR (.github/workflows/flake.yml) is what brings in
  # new packages.
  system.autoUpgrade = {
    enable = true;
    flake = "github:blconway/nixos-config#bc-llm";
    # Must start inside rebootWindow: when the kernel changes, an upgrade that
    # runs outside the window neither switches nor reboots.
    dates = "04:10";
    allowReboot = true;
    rebootWindow = { lower = "04:00"; upper = "06:00"; };
  };

  system.stateVersion = "25.11";
}
