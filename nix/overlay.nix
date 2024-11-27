({ inputs, ... }:

  let

    inherit (inputs.nixpkgs) lib;

  in {

    flake = {
      overlays.default = lib.composeManyExtensions [
        inputs.nix-extra.overlays.default
        (_: prev: { "fhs" = prev.callPackage ./shell.nix { inherit inputs; }; })

      ];
    };
  })
