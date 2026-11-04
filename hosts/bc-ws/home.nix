{ config, pkgs, ... }:

{
  imports = [ ../../home/common.nix ];

  home.username = "brandon";
  home.homeDirectory = "/home/brandon";
  home.stateVersion = "25.11";

  # Takes main (including CI's daily flake.lock) into /etc/nixos and switches
  # now. The lock is never updated here; that happens in CI (D5).
  programs.fish.shellAliases.update = "git -C /etc/nixos pull --ff-only && rebuild";

  # ============================================================
  # Flatpak packages
  # ============================================================
  services.flatpak.update.onActivation = true;
  services.flatpak.update.auto = {
    enable = true;
    onCalendar = "daily";
  };

  services.flatpak.packages = [
    "org.mozilla.firefox"
    "io.github.kolunmi.Bazaar"
  ];

  # ============================================================
  # GNOME extensions
  # ============================================================
  home.packages = with pkgs; [
    gnomeExtensions.hot-edge
  ];

  dconf.settings = {
    "org/gnome/shell" = {
      enabled-extensions = [ "hotedge@jonathan.jdoda.ca" ];
    };
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
