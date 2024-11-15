{
  description = "Description for the project";

  inputs = {
    nix-extra = { url = "github:nialov/nix-extra"; };
    nixpkgs.follows = "nix-extra/nixpkgs";
    flake-parts.follows = "nix-extra/flake-parts";
    nixpkgs-cmake-2 = {
      url = "github:nixos/nixpkgs/aa75bb25d8a681d971aefe9bcd263c9dbf8acf50";
      flake = false;
    };

  };

  outputs = inputs:
    let
      flakePart = inputs.flake-parts.lib.mkFlake { inherit inputs; }
        ({ inputs, ... }: {
          systems = [ "x86_64-linux" ];
          imports = [
            inputs.nix-extra.flakeModules.custom-pre-commit-hooks
            ./nix/per-system.nix
            ./nix/overlay.nix
          ];
        });

    in flakePart;

}
