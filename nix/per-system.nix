({ inputs, self, ... }:

  {
    perSystem = { config, system, pkgs, lib, ... }:
      let
        mkNixpkgs = nixpkgs:
          import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
            config = { allowUnfree = true; };
          };

      in {
        _module.args.pkgs = mkNixpkgs inputs.nixpkgs;
        devShells = {
          default = pkgs.mkShell {
            buildInputs = lib.attrValues { inherit (pkgs) fhs; };
            shellHook = config.pre-commit.installationScript + ''
              export PROJECT_DIR="$PWD"
              echo "FHSenv available with 'fhs' (${pkgs.fhs}/bin/fhs) command"
            '';
          };

        };

        pre-commit = {
          check.enable = true;
          settings.hooks = {
            nixfmt.enable = true;
            black.enable = true;
            black-nb.enable = true;
            nbstripout.enable = true;
            isort = { enable = true; };
            shellcheck.enable = true;
            statix.enable = true;
            deadnix.enable = true;
            rstcheck.enable = true;
            yamllint = { enable = false; };
            commitizen.enable = true;
            ruff = { enable = true; };
          };

        };
        legacyPackages = pkgs;

      };

  })
