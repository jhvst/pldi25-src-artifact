{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      inherit (self) outputs;

      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      forAllSystems = nixpkgs.lib.genAttrs systems;

      getSystem =
        system:
        if builtins.getEnv "USE_MUSL" == "true" then
          inputs.nixpkgs-unstable.legacyPackages.${system}.pkgsMusl.stdenv.hostPlatform.config
        else
          inputs.nixpkgs-unstable.legacyPackages.${system}.stdenv.hostPlatform.config;

      packages = forAllSystems (
        system:
        let
          pkgs = (import inputs.nixpkgs-unstable) {
            localSystem = getSystem system;
          };
        in
        rec
        {
          z3 = inputs.nixpkgs-unstable.legacyPackages.${system}.z3.overrideAttrs (old: rec {
            version = "4.13.3";
            src = pkgs.fetchFromGitHub {
              owner = "z3prover";
              repo = "z3";
              rev = "z3-${version}";
              sha256 = "sha256-odwalnF00SI+sJGHdIIv4KapFcfVVKiQ22HFhXYtSvA=";
            };
          });

          fstar = pkgs.ocaml-ng.ocamlPackages_4_14.buildDunePackage rec {
            pname = "fstar";
            version = "2025.03.25";

            src = pkgs.fetchFromGitHub {
              owner = "FStarLang";
              repo = "FStar";
              rev = "v${version}";
              hash = "sha256-PhjfThXF6fJlFHtNEURG4igCnM6VegWODypmRvnZPdA=";
            };

            nativeBuildInputs = [
              pkgs.installShellFiles
              pkgs.makeWrapper
              pkgs.ocaml-ng.ocamlPackages_4_14.menhir
            ];

            buildInputs = with pkgs.ocaml-ng.ocamlPackages_4_14; [
              batteries
              memtrace
              menhir
              menhirLib
              mtime
              pprint
              ppx_deriving
              ppx_deriving_yojson
              ppxlib
              process
              sedlex
              stdint
              yojson
              zarith
            ];

            enableParallelBuilding = true;

            prePatch = ''
              patchShebangs .scripts/*.sh
              patchShebangs ulib/ml/app/ints/mk_int_file.sh
            '';

            buildPhase = ''
              export PATH="${z3}/bin:$PATH"
              make -j$(nproc)
            '';

            installPhase = ''
              PREFIX=$out make install
            '';
          };

          defaultShell = pkgs.mkShell {
            buildInputs = [
              pkgs.dune_3
              pkgs.ocaml-ng.ocamlPackages_4_14.ocaml
              pkgs.cargo
              pkgs.rustc
              pkgs.musl
              inputs.nixpkgs.legacyPackages.${system}.pkgsStatic.gmp
              pkgs.ocaml-ng.ocamlPackages_4_14.findlib
            ] ++ fstar.buildInputs;
            OCAMLPATH = "${fstar}/lib";
          };

        }
      );

    in
    {
      inherit packages;
      devShells.x86_64-linux.default = packages.x86_64-linux.defaultShell;
    };
}