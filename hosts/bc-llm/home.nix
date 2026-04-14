{ config, pkgs, ... }:

{
  imports = [ ../../home/common.nix ];

  home.username = "brandon";
  home.homeDirectory = "/home/brandon";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    btop
    ncdu
  ];
}
