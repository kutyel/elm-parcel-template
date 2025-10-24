{ elm-review-tool-src, elmPackages, pkgs, stdenv }:
pkgs.buildNpmPackage {
  name = "elm-review-tool";
  src = elm-review-tool-src;
  # to update this hash, see `../bin/update-npmDepsHashes`
  npmDepsHash = "sha256-mI94fYNKZ9Jx1Iyo/VjZqaXQ64tZA2S8mtn5l6TtCSc=";
  patches = [ ];
  nativeBuildInputs = with pkgs; [ coreutils ];
  buildInputs = with elmPackages; [ elm elm-format ];
  buildPhase = ''
    substituteInPlace ./package.json \
      --replace-fail '"elm-tooling install"' '"echo skipping elm-tooling"'

    # Leaving this at 1.1.3 causes build failures, with:
    # `Error: Because there is no version of elm/json in 1.1.3 and root/ 0.0.0 depends on elm/json 1.1.3, root/ 0.0.0 is forbidden.`
    # To avoid this issue, `makeDotElmDirectoryCmd` needs changes, to support
    # including multiple versions of packages.
    substituteInPlace ./parseElm/elm.json \
      --replace-fail '"elm/json": "1.1.3"' '"elm/json": "1.1.4"'

    mkdir -p "$out"
    cp -r * "$out"/
    mv $out/bin/elm-review $out/bin/elm-review.js
    cat << EOF > $out/bin/elm-review
    #!${pkgs.bash}/bin/bash
    ${pkgs.nodejs}/bin/node ./elm-review.js \
      --namespace="elm-review-nix-from-src" \
      --compiler="${elmPackages.elm}/bin/elm \
      --elm-format-path="${elmPackages.elm-format}/bin/elm-format \
      "$@"
    EOF
    chmod +x $out/bin/elm-review
  '';
}
