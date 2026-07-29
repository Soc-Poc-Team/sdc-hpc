{
  pkgs,
  render-docs,
}:
pkgs.stdenvNoCC.mkDerivation {
  pname = "small-data-cluster-docs";
  version = "1";

  src = ./.;

  nativeBuildInputs = [
    render-docs
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export HOME="$TMPDIR"
    export TEXMFHOME="$TMPDIR/.texmf"
    export XDG_CACHE_HOME="$TMPDIR/.cache"

    mkdir -p "$TEXMFHOME" "$XDG_CACHE_HOME"

    OUTPUT_ROOT="$PWD/rendered-docs" DOCS_ROOT=$src render-docs

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp rendered-docs/*.pdf "$out/"

    runHook postInstall
  '';
}
