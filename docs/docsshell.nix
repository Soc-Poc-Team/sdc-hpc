{ pkgs }:

let
  packages = with pkgs; [
    coreutils
    findutils
    gnused
    pandoc
    texliveFull
    graphviz
    imagemagick
    librsvg
    ghostscript
    poppler-utils
    nodePackages.mermaid-cli
    python3Packages.pygments
    fontconfig
    libertinus
    source-code-pro
  ];
in
{
  inherit packages;

  shell = pkgs.mkShell {
    inherit packages;

    shellHook = ''
      export TEXMFHOME="$PWD/.texmf"
      export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$PWD/.cache}"

      mkdir -p "$TEXMFHOME" "$XDG_CACHE_HOME"
    '';
  };
}
