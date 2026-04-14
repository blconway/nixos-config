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
      PermitRootLogin = "no";
    };
  };
  # users.users.brandon.openssh.authorizedKeys.keys = [
  #   "ssh-ed25519 AAAA..."  # add your public key here
  # ];

  # ============================================================
  # Tailscale VPN
  # ============================================================
  services.tailscale.enable = true;

  # ============================================================
  # Firewall
  # ============================================================
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    trustedInterfaces = [ "tailscale0" ];  # all ports open on tailnet
  };

  # ============================================================
  # AMD GPU — Strix Halo iGPU (RDNA 3.5, gfx1150)
  # ============================================================
  hardware.graphics.enable = true;
  hardware.amdgpu.opencl.enable = true;

  # ============================================================
  # Auto-upgrade
  # ============================================================
  system.autoUpgrade = {
    enable = true;
    flake = "github:blconway/nixos-config#bc-llm";
    dates = "daily";
    allowReboot = false;
  };

  system.stateVersion = "25.11";
}
