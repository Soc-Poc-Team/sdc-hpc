{ pkgs, ... }:
pkgs.stdenv.mkDerivation {
  name = "pharos";
  version = "1.0";

  src = ./.;

  meta = {
    description = "Pharos is a simple application to check compatibility with a cluster before joining it";
    mainProgram = "pharos"; # use the client as mmainProgram
  };

  buildInputs = with pkgs; [
    cmake
    gcc
  ];

  configurePhase = ''
    cmake -B build -S $src \
      -DCMAKE_BUILD_TYPE=Release
  '';

  buildPhase = ''
    cmake --build build \
      -j$NIX_BUILD_CORES
  '';

  installPhase = ''
    cmake --install build --prefix=$out

  '';
}
