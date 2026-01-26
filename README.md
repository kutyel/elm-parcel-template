# elm-parcel-template

[![NixCI Badge](https://nix-ci.com/badge/gh:kutyel:elm-countries-quiz)](https://nix-ci.com/account/repo/gh:kutyel:elm-countries-quiz/suite/main)

- [x] Add `elm-test-rs`
- [x] Add `elm-review`
- [x] Add `tailwindcss`
- [x] Add Nix ❄️
- [x] Add NixCI ✅

Commands to generate `elm.lock` file:

```sh
nix develop
elm2nix lock elm.json review/elm.json review/elm.extra.json
```
