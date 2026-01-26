{ caddy, writeShellScript }:

{ root # The derivation that contains the files to be served
, port ? 8000
}:

writeShellScript "serve" ''
  ${caddy}/bin/caddy file-server --browse \
    --listen :${builtins.toString port}   \
    --root "${root}"
''
