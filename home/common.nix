{ config, pkgs, ... }:

{
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
  # Packages (shared)
  # ============================================================
  home.packages = with pkgs; [
    claude-code
  ];

  # ============================================================
  # Shell & terminal tools
  # ============================================================
  programs.fish = {
    enable = true;
    shellAliases = {
      rebuild = "nh os switch /etc/nixos";
    };
  };

  programs.starship.enable = true;
  programs.bat = {
    enable = true;
    config.theme = "TwoDark";
  };
  programs.fzf = {
    enable = true;
    defaultOptions = [ "--color=dark" ];
  };
  programs.zoxide.enable = true;
  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
    extraOptions = [ "--group-directories-first" ];
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
