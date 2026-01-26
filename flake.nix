{
  inputs = {
    elm2nix = {
      url = "github:dwayne/elm2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, elm2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (elm2nix.lib.elm2nix pkgs)
          buildElmApplication
          generateRegistryDat
          prepareElmHomeScript;

        app = pkgs.callPackage ./nix/app.nix {
          inherit generateRegistryDat prepareElmHomeScript;
        };

        elm = pkgs.callPackage ./nix/elm.nix {
          inherit buildElmApplication;
        };

        serve = pkgs.callPackage ./nix/serve.nix {};

        mkApp = drv: {
          type = "app";
          program = "${drv}";
        };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "elm-countries-quiz";

          packages = [
            elm2nix.packages.${system}.default
            pkgs.elmPackages.elm
            pkgs.elmPackages.elm-format
            pkgs.elmPackages.elm-json
            pkgs.elmPackages.elm-test-rs
            pkgs.elmPackages.elm-review
            pkgs.nodejs_24
            pkgs.pnpm
          ];

          shellHook = ''
            export PROJECT_ROOT="$PWD"
            export PS1="($name)\n$PS1"

            f () {
              elm-format                   \
                "$PROJECT_ROOT"/src        \
                "$PROJECT_ROOT"/review/src \
                "$PROJECT_ROOT"/tests      \
                --yes
            }

            r () {
              elm-review
            }

            t () {
              elm-test-rs "$PROJECT_ROOT"/tests/*.elm
            }

            c () {
              rm -rf "$PROJECT_ROOT"/{.parcel-cache,dist,elm-stuff,node_modules}
            }

            s () {
              pnpm start
            }

            pnpm install --silent

            echo "Elm development environment loaded"
            echo "All your dependencies have been installed"
            echo ""
            echo "Type 'f' to run elm-format"
            echo "Type 'r' to run elm-review"
            echo "Type 't' to run elm-test-rs"
            echo "Type 'c' to remove build artifacts"
            echo "Type 's' to start the development server"
            echo ""
          '';
        };

        packages = {
          inherit app elm;
          default = app;
        };

        apps = {
          default = self.apps.${system}.app;
          app = mkApp (serve { root = app; });
        };

        checks = {
          inherit app elm;
        };
      }
    );
}
