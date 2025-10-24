{
  description = "elm-parcel-template";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    elm-review-tool-src = {
      url = "github:jfmengels/node-elm-review";
      flake = false;
    };
    mkElmDerivation = {
      url = "github:r-k-b/mkElmDerivation?ref=support-elm-review";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, elm-review-tool-src, mkElmDerivation }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ mkElmDerivation.overlays.makeDotElmDirectoryCmd ];
        };
        inherit (pkgs) lib stdenv callPackage;
        inherit (lib) fileset hasInfix hasSuffix;

        toSource = fsets:
          fileset.toSource {
            root = ./.;
            fileset = fileset.unions fsets;
          };

        elmVersion = "0.19.1";

        # The build cache will be invalidated if any of the files within change.
        # So, exclude files from here unless they're necessary for `elm make` et al.
        minimalElmSrc = toSource [
          (fileset.fileFilter (file: file.hasExt "elm") ./src)
          ./elm.json
        ];

        testsSrc = toSource [
          (fileset.fileFilter (file: file.hasExt "elm") ./src)
          (fileset.fileFilter (file: file.hasExt "elm") ./tests)
          ./elm.json
        ];

        reviewSrc = toSource [
          (fileset.fromSource testsSrc)
          (fileset.fileFilter (file: file.hasExt "elm") ./review)
          ./review/elm.json
        ];

        elm-review-tool = callPackage ./nix/elm-review-tool.nix {
          inherit elm-review-tool-src;
        };

        elmtests = callPackage ./nix/elm-tests.nix { inherit testsSrc; };
        elmReviewed = callPackage ./nix/elm-reviewed.nix {
          inherit elm-review-tool elmVersion reviewSrc;
        };

        peekSrc = name: src:
          stdenv.mkDerivation {
            src = src;
            name = "peekSource-${name}";
            buildPhase = "mkdir -p $out";
            installPhase = "cp -r ./* $out";
          };
      in
      {
        packages = {
          inherit elm-review-tool;
          elm-review-tool-src = pkgs.runCommand "elm-review-tool-src" { }
            "ln -s ${elm-review-tool-src} $out";
          minimalElmSrc = peekSrc "minimal-elm" minimalElmSrc;
          testsSrc = peekSrc "tests" testsSrc;
          reviewSrc = peekSrc "elm-review" reviewSrc;
        };
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Elm toolchain
            elmPackages.elm
            elmPackages.elm-format
            elmPackages.elm-test
            elmPackages.elm-review
            
            # Node.js for npm dependencies
            nodejs_22
            nodePackages.pnpm
          ];

          shellHook = ''
            echo "Elm development environment loaded"
            echo "Run 'pnpm install' to install JavaScript dependencies"
            echo "Run 'pnpm start' to start the development server"
          '';
        };
        checks = { inherit elmReviewed elmtests; };
      }
    );
}
