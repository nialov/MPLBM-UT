{ inputs, buildFHSUserEnv, lib, writeScript, system, writeShellApplication, ...
}:
buildFHSUserEnv {
  name = "MPLBM-UT-shell";

  targetPkgs = fhsPkgs:

    let
      pythons = builtins.map (python:
        python.withPackages (p: [ p.setuptools p.pip p.wheel p.virtualenv ]))
        (lib.attrValues { inherit (fhsPkgs) python3; });
    in lib.attrValues {
      inherit (fhsPkgs)
        fish cacert gcc expat zlib pkg-config wget openmpi mpich cmake gnumake
        libGL;
      glibDev = fhsPkgs.glib.dev;
      libffiDev = fhsPkgs.libffi.dev;
      inherit (fhsPkgs.xorg) libX11 libXrender;
      # cmake-2 = let pkgs = import inputs.nixpkgs-cmake-2 { inherit system; };
      # in pkgs.cmake;

    } ++ pythons;
  runScript = let
    app = writeShellApplication {
      name = "entrypoint";
      text = ''
        exec /usr/bin/env fish "$@"
      '';

    };
  in "${app}/bin/entrypoint";
  #writeScript "entrypoint.sh" ''
  #  #!/usr/bin/env bash

  #  exec /usr/bin/env fish "$@"
  #'';

  profile =

    "";
}
