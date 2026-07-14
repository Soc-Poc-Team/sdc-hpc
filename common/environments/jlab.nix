{ pkgs, ... }:
pkgs.python3.withPackages (
  p: with p; [
    jupyterhub
    jupyterlab
    batchspawner
    (callPackage ../../roles/headnode/modules/wrapspawner/BAKdefault.nix { })
    jupyter
    jupyter-core
    notebook
  ]
)
