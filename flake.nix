{
  description = "elm-parcel-template";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
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
            elm-review
            echo "Elm development environment loaded"
            echo "Run 'pnpm install' to install JavaScript dependencies"
            echo "Run 'pnpm start' to start the development server"
          '';
        };
      }
    );
}
