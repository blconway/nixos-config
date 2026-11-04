{ pkgs, ... }:

{
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Remove GNOME default apps that aren't useful on a developer workstation.
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-music
    gnome-maps
    gnome-weather
    gnome-contacts
    gnome-clocks
    gnome-calendar
    gnome-characters
    gnome-logs
    epiphany # GNOME Web
    totem # video player
    yelp # GNOME Help
    geary # email client
    gnome-software # replaced by Bazaar Flatpak
  ];
}
