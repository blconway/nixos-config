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
  ];

  # ============================================================
  # GTK theming — make Flatpak GTK apps match COSMIC's look
  # ============================================================
  gtk = {
    enable = true;
    gtk4.theme = null;
    theme = {
      name = "Pop-dark";
      package = pkgs.pop-gtk-theme;
    };
    iconTheme = {
      name = "Pop";
      package = pkgs.pop-icon-theme;
    };
    cursorTheme = {
      name = "cosmic";
      package = pkgs.cosmic-icons;
    };
  };

  # Expose theme settings to Flatpak GTK apps via the portal.
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-theme = "Pop-dark";
      icon-theme = "Pop";
      color-scheme = "prefer-dark";
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
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
