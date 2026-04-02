{ pkgs, lib, ... }:

{
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  # COSMIC's Settings portal doesn't implement org.gnome.desktop.interface,
  # so Flatpak GTK apps get no font config and render squares. Route the
  # Settings interface through the GTK portal instead.
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
