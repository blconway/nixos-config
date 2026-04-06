{ config, pkgs, ... }:

{
  home.username = "brandon";
  home.homeDirectory = "/home/brandon";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  # Gracefully reload user services on rebuild instead of hard-restarting.
  systemd.user.startServices = "sd-switch";

  # ============================================================
  # Git
  # ============================================================
  programs.git = {
    enable = true;
    settings = {
      user.name = "Brandon Conway";
      user.email = "23000270+blconway@users.noreply.github.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

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

  # ============================================================
  # Shell & terminal tools
  # ============================================================
  programs.fish = {
    enable = true;
    shellAliases = {
      rebuild = "nh os switch /etc/nixos";
      update  = "sudo nix flake update --flake /etc/nixos && rebuild";
    };
  };

  programs.starship.enable = true;                  # cross-shell prompt with git status
  programs.bat = { enable = true; config.theme = "TwoDark"; }; # cat with syntax highlighting
  programs.fzf = { enable = true; defaultOptions = [ "--color=dark" ]; }; # fuzzy finder (Ctrl+R/Ctrl+T)
  programs.zoxide.enable = true;                     # smart cd — use `z` instead
  programs.eza = {                                   # modern ls with icons and git status
    enable = true;
    icons = "auto";
    git = true;
    extraOptions = [ "--group-directories-first" ];
  };
  programs.direnv = {                                # auto-loads per-project dev environments
    enable = true;
    nix-direnv.enable = true;
  };
}
