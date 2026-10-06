{ fetchPnpmDeps
, lib
, nodejs
, pnpm
, pnpmConfigHook
, stdenv
, generateRegistryDat
, prepareElmHomeScript
}:

let
  fs = lib.fileset;

  elmLock = ../elm.lock;
  registryDat = generateRegistryDat { inherit elmLock; };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "elm-parcel-template";
  version = "1.0.0";

  src = fs.toSource {
    root = ../.;
    fileset = fs.unions [
      ../src
      ../.postcssrc
      ../elm.json
      ../index.html
      ../package.json
      ../pnpm-lock.yaml
      ../tailwind.config.ts
    ];
  };

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 1;
    hash = "sha256-/UN0Fu3acWWtnItMcA/fA0lMoLBmHIoqQCFCgI+WxYE=";
  };

  buildPhase = ''
    runHook preBuild

    ${prepareElmHomeScript { inherit elmLock registryDat; }}
    pnpm build index.html
    cp -R dist/ "$out"/

    runHook postBuild
  '';
})
