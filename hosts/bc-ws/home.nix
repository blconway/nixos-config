{ config, pkgs, ... }:

{
  imports = [ ../../home/common.nix ];

  home.username = "brandon";
  home.homeDirectory = "/home/brandon";
  home.stateVersion = "25.11";

  programs.fish.shellAliases.update = "sudo nix flake update --flake /etc/nixos && rebuild";

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
