{
  description = "Brandon's NixOS machines";

  inputs = {
    # Unstable channel — rolling release with the latest packages.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager — tracks master to match nixpkgs-unstable.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-flatpak — declarative Flatpak management via Home Manager.
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    # nixos-hardware — vendor-specific hardware quirks and optimisations.
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-flatpak,
      nixos-hardware,
      ...
    }:
    let
      # Each host's platform comes from nixpkgs.hostPlatform in its
      # hardware-configuration.nix; this is only for the flake's own outputs.
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {

      # ── Workstation ─────────────────────────────────────────
      nixosConfigurations.bc-ws = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/bc-ws

          nix-flatpak.nixosModules.nix-flatpak

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.sharedModules = [
              nix-flatpak.homeManagerModules.nix-flatpak
            ];
            home-manager.users.brandon = import ./hosts/bc-ws/home.nix;
          }
        ];
      };

      # ── LLM Server (Framework Desktop) ─────────────────────
      nixosConfigurations.ai-fw = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/ai-fw

          nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
          # No Home Manager: nothing on this box is configured per user.
        ];
      };

      # ── ai-fw installer ISO ───────────────────────────────
      # Takes disk UUIDs, SSH keys and the flake to install from ai-fw itself.
      nixosConfigurations.ai-fw-installer = nixpkgs.lib.nixosSystem {
        specialArgs.target = self.nixosConfigurations.ai-fw;
        modules = [ ./hosts/ai-fw-installer ];
      };

      # `nix build .#ai-fw-installer-iso` → result/iso/*.iso
      packages.x86_64-linux.ai-fw-installer-iso =
        self.nixosConfigurations.ai-fw-installer.config.system.build.isoImage;

      # `nix flake check` evaluates every host and the invariants; without
      # --no-build it also builds each host's system. The installer is a
      # host here too, so it is evaluated on every PR.
      checks.x86_64-linux =
        nixpkgs.lib.mapAttrs' (
          name: host: nixpkgs.lib.nameValuePair "nixos-${name}" host.config.system.build.toplevel
        ) self.nixosConfigurations
        // {
          invariants = import ./tests/invariants.nix {
            inherit pkgs;
            hosts = self.nixosConfigurations;
          };
        };

      # `nix fmt` formats every .nix file; CI runs it with --ci.
      formatter.x86_64-linux = pkgs.nixfmt-tree;
    };
}
