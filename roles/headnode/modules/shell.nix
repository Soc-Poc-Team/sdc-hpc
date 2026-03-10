{
  pkgs ? import <nixpkgs> { },
}:
### TESTING THE BUILDING OF PACKAGE
# Create a Python environment where the `wrapspawner` package will be installed
pkgs.mkShell {
  buildInputs = with pkgs; [
    python3
    python3Packages.virtualenv
    python3Packages.batchspawner
    python3Packages.pip
    (pkgs.python3Packages.callPackage ./wrapspawner/wrapspawner.nix { }) # Your custom package
  ];

  shellHook = ''
    # Set up virtualenv
    if [ ! -d "$HOME/my-venv" ]; then
      python3 -m venv ./my-venv
    fi
    source ./my-venv/bin/activate
    echo "Activated virtual environment with wrapspawner"
  '';
}
