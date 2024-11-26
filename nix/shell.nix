{ buildFHSUserEnv, lib, appimageTools, ... }:

let

  base = appimageTools.defaultFhsEnvArgs;

  customConfig = {
    name = "MPLBM-UT-shell";

    targetPkgs = fhsPkgs:

      let
        pythons = builtins.map (python:
          python.withPackages (p: [ p.setuptools p.pip p.wheel p.virtualenv ]))
          (lib.attrValues { inherit (fhsPkgs) python3; });
        basePkgs = base.targetPkgs fhsPkgs;
      in lib.attrValues {
        inherit (fhsPkgs)
          fish cacert gcc pkg-config wget openmpi mpich cmake gnumake libffi;

      } ++ pythons ++ basePkgs;
    extraOutputsToInstall = [ "dev" ];
    runScript = ''
      bash "$@"
    '';
    # let
    #   app = writeShellApplication {
    #     name = "entrypoint";
    #     text = ''
    #       exec ${fish}/bin/fish "$@"
    #     '';

    #   };
    # in "${app}/bin/entrypoint";
    #writeScript "entrypoint.sh" ''
    #  #!/usr/bin/env bash

    #  exec /usr/bin/env fish "$@"
    #'';

    profile =

      ''
        test ! -f ".venv/bin/activate" && python -m venv .venv
        test -f ".venv/bin/activate" && source ".venv/bin/activate"
      '';
  };

in buildFHSUserEnv (lib.recursiveUpdate base customConfig)
