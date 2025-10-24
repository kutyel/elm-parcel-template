{ elmPackages, pkgs, stdenv, testsSrc }:
stdenv.mkDerivation {
  name = "elm-test-results";
  src = testsSrc;

  nativeBuildInputs = with elmPackages; [ elm elm-test ];

  installPhase = ''
    ${pkgs.makeDotElmDirectoryCmd { elmJson = ../elm.json; }}
    set -e
    elm-test
    echo "passed" > $out
  '';
}
