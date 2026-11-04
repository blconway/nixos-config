{ pkgs, ... }:

# Interactive-use settings for machines Brandon sits at. Kept out of
# common.nix so ai-fw (headless endpoint) doesn't carry them.
{
  # ============================================================
  # Shell & Security
  # ============================================================
  programs.fish.enable = true;
  users.users.brandon.shell = pkgs.fish;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # ============================================================
  # Packages
  # ============================================================
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    nh
  ];
}
