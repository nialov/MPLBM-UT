({ inputs, ... }:

  let

    inherit (inputs.nixpkgs) lib;

  in {

    flake = {
      overlays.default = lib.composeManyExtensions [
        inputs.nix-extra.overlays.default
        (final: prev: {
          "MPLBM-UT-shell" = prev.callPackage ./shell.nix { inherit inputs; };
        })

      ];
    };
  })
