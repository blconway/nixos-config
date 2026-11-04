{ pkgs, ... }:

# Developer role, modelled on what Bazzite DX adds (docs/DECISIONS.md, D10).
{
  # ============================================================
  # Containers
  # ============================================================
  # Docker and Podman side by side, as in Bazzite DX. No Podman dockerCompat:
  # `docker` is the real Docker.
  virtualisation.docker.enable = true;
  virtualisation.podman.enable = true;

  # ============================================================
  # Virtual machines
  # ============================================================
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # Membership in docker is root-equivalent on this machine.
  users.users.brandon.extraGroups = [
    "docker"
    "libvirtd"
  ];

  # ============================================================
  # Running software that isn't packaged for Nix
  # ============================================================
  # Lets prebuilt binaries (toolchain downloads, language servers, uv/npm
  # binaries) find a dynamic loader and common libraries. Bazzite DX gets
  # this for free from Fedora; here it stands in for Homebrew.
  programs.nix-ld.enable = true;

  # ============================================================
  # Tracing, profiling and tools
  # ============================================================
  programs.bcc.enable = true;
  services.sysprof.enable = true;
  services.usbmuxd.enable = true; # iOS devices over USB

  environment.systemPackages = with pkgs; [
    distrobox
    podman-tui
    android-tools
    bpftrace
    bpftop
    ccache
    flatpak-builder
    numactl
    waypipe
    restic
    rclone
  ];
}
