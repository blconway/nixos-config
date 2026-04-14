{ config, pkgs, ... }:

{
  imports = [ ../../home/common.nix ];

  home.username = "brandon";
  home.homeDirectory = "/home/brandon";
  home.stateVersion = "25.11";

  programs.fish.shellAliases.update = "cd /etc/nixos && git fetch origin && git reset --hard origin/main && rebuild";

  home.packages = with pkgs; [
    btop
    ncdu
    radeontop    # monitor iGPU utilization
    tmux         # persistent SSH sessions
  ];
}
