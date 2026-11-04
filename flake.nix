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

  outputs = { self, nixpkgs, home-manager, nix-flatpak, nixos-hardware, ... }: {

    # ── Workstation ─────────────────────────────────────────
    nixosConfigurations.bc-ws = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

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
      system = "x86_64-linux";

      modules = [
        ./hosts/ai-fw

        nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.brandon = import ./hosts/ai-fw/home.nix;
        }
      ];
    };

    # Old name of ai-fw, kept so the machine (still hostnamed bc-llm) can
    # switch to the renamed config with `update`. Remove once it reports
    # hostname ai-fw (docs/DECISIONS.md, D6).
    nixosConfigurations.bc-llm = self.nixosConfigurations.ai-fw;
  };
}
