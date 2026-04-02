{
  description = "Brandon's NixOS workstation";

  inputs = {
    # Unstable channel — rolling release with the latest packages.
    # Switch back to a stable release (e.g. nixos-26.05) when it ships.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager — tracks master to match nixpkgs-unstable.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-flatpak — declarative Flatpak management via Home Manager.
    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  outputs = { self, nixpkgs, home-manager, nix-flatpak, ... }: {
    nixosConfigurations.bc-ws = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./configuration.nix

        # nix-flatpak NixOS module — manages system-level remotes declaratively.
        nix-flatpak.nixosModules.nix-flatpak

        # Home Manager as a NixOS module so it activates on nixos-rebuild.
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.sharedModules = [
            nix-flatpak.homeManagerModules.nix-flatpak
          ];
          home-manager.users.brandon = import ./home.nix;
        }
      ];
    };
  };
}
