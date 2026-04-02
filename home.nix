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

  # dconf — expose theme settings to Flatpak GTK apps via the portal.
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

  programs.starship = {
    enable = true;
  };

  # bat — cat with syntax highlighting and line numbers
  programs.bat = {
    enable = true;
    config.theme = "TwoDark";
  };

  # eza — modern ls replacement with icons and git status
  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
    extraOptions = [ "--group-directories-first" ];
  };

  # fzf — fuzzy finder (Ctrl+R for history, Ctrl+T for files)
  programs.fzf = {
    enable = true;
    defaultOptions = [ "--color=dark" ];
  };

  # zoxide — smart cd that learns your most-used directories
  programs.zoxide.enable = true;

  # direnv — auto-loads per-project dev environments on cd.
  # Use with `nix develop` flakes: create a .envrc with "use flake"
  # and direnv loads/unloads the environment automatically.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # cached nix evaluation for faster shell entry
  };
}
