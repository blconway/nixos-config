{ pkgs, lib, ... }:

{
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  # GTK portal — needed for Flatpak GTK apps (Remmina, etc.) to access
  # host fonts and theme settings. COSMIC's Settings portal doesn't implement
  # org.gnome.desktop.interface, so GTK apps get no font config and render squares.
  # We override the portal config to route Settings through the GTK portal.
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.configPackages = lib.mkForce [
    (pkgs.writeTextDir "share/xdg-desktop-portal/cosmic-portals.conf" ''
      [preferred]
      default=cosmic;gtk;
      org.freedesktop.impl.portal.Settings=gtk;
      org.freedesktop.impl.portal.Secret=gnome-keyring;
    '')
  ];
}
