{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:

# Headless inference endpoint, kept to what that needs (docs/DECISIONS.md, D8).
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/llm-server.nix
    # Drops docs, default packages, logrotate, udisks2 and desktop XDG bits.
    # Not profiles/headless.nix: it sets nomodeset (no amdgpu) and removes the
    # tty1 console, the last way in if the network is down.
    (modulesPath + "/profiles/minimal.nix")
  ];

  # ============================================================
  # Packages
  # ============================================================
  environment.systemPackages = with pkgs; [
    llama-cpp-vulkan # llama-bench, to measure models on this box
    radeontop # iGPU utilization
    sbctl # `sbctl status`: Secure Boot keys and enrollment
    tmux # long downloads and benchmarks over SSH
  ];

  # Deploy main now, from the same flake the nightly upgrade uses.
  environment.shellAliases.update = "sudo nixos-rebuild switch --refresh --flake ${config.system.autoUpgrade.flake}";

  # ============================================================
  # Networking
  # ============================================================
  networking.hostName = "ai-fw";
  networking.useDHCP = lib.mkDefault true;

  # ============================================================
  # SSH
  # ============================================================
  # Password login for brandon only; no SSH keys are in use (D14). Root can't
  # log in over SSH and has no password anyway (D12).
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ "brandon" ];
    };
  };

  # With a password to guess, ban addresses that keep failing (D14).
  services.fail2ban.enable = true;

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
    trustedInterfaces = [ "tailscale0" ]; # all ports open on tailnet
  };

  # ============================================================
  # AMD GPU — Strix Halo iGPU (Radeon 8060S, RDNA 3.5, gfx1151)
  # ============================================================
  hardware.graphics.enable = true; # Mesa RADV, used by llama.cpp's Vulkan backend

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
  # The daily lock bump in .github/workflows/flake.yml is what brings in new
  # packages, so this follows nixos-unstable about a day behind.
  system.autoUpgrade = {
    enable = true;
    flake = "github:blconway/nixos-config#ai-fw";
    # Must start inside rebootWindow: when the kernel changes, an upgrade that
    # runs outside the window neither switches nor reboots.
    dates = "04:10";
    allowReboot = true;
    rebootWindow = {
      lower = "04:00";
      upper = "06:00";
    };
  };

  # ============================================================
  # Secure Boot (D15)
  # ============================================================
  # Lanzaboote installs signed systemd-boot entries in place of the plain
  # systemd-boot module. First boot creates the keys in /var/lib/sbctl and
  # stages them, Microsoft's included (the GPU's option ROM is signed with
  # them); systemd-boot enrolls them on the next boot if the firmware is in
  # Setup Mode. Then turn Secure Boot on in the BIOS (runbook).
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    autoGenerateKeys.enable = true;
    autoEnrollKeys.enable = true;
    # Same rollback as common.nix's systemd-boot settings: 3 tries, and the
    # 10-generation limit (inherited from systemd-boot.configurationLimit).
    bootCounting.initialTries = 3;
  };

  system.stateVersion = "25.11";
}
