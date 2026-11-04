{ pkgs, ... }:

# Gaming role, modelled on what Bazzite ships (docs/DECISIONS.md, D10).
{
  # ============================================================
  # Steam
  # ============================================================
  # Also installs the udev rules for Steam controllers and Valve hardware.
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;  # "Steam (Gamescope)" session at the login screen
    extest.enable = true;            # Steam Input on Wayland
    protontricks.enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  programs.gamescope.enable = true;
  programs.gamemode.enable = true;

  # ============================================================
  # Controllers and input
  # ============================================================
  hardware.xone.enable = true;     # Xbox wireless dongle
  hardware.xpadneo.enable = true;  # Xbox controllers over Bluetooth
  services.input-remapper.enable = true;

  # ============================================================
  # Overlays, capture and tools
  # ============================================================
  programs.obs-studio = {
    enable = true;
    plugins = [ pkgs.obs-studio-plugins.obs-vkcapture ];
  };

  environment.systemPackages = with pkgs; [
    mangohud
    vkbasalt
    protonup-qt
  ];
}
