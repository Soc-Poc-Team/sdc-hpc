{
  pkgs ? import <nixpkgs> { },
}:
### TESTING THE BUILDING OF PACKAGE
# Create a Python environment where the `wrapspawner` package will be installed
pkgs.mkShell {
  buildInputs = with pkgs; [
    go
    (pkgs.callPackage ./slurm-node-exporter/default.nix { }) # Your custom package
  ];

  # shellHook = ''
  #   # Set up virtualenv
  #   if [ ! -d "$HOME/my-venv" ]; then
  #     python3 -m venv ./my-venv
  #   fi
  #   source ./my-venv/bin/activate
  #   echo "Activated virtual environment with wrapspawner"
  # '';
}
