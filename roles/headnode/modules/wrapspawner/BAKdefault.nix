{ pkgs, ... }:
pkgs.python3Packages.buildPythonPackage rec {
  pname = "wrapspawner";
  version = "1.0.1";

  src = pkgs.fetchFromGitHub {
    owner = "jupyterhub";
    repo = pname;
    rev = "refs/tags/v${version}";
    sha256 = "sha256-Dsy3kuEZQsPU7dIvVBZyw7CWY/Jipzye20kuHJDw4ok=";
  };

  pyproject = true;

  build-system = with pkgs.python3Packages; [ setuptools wheel ];

  dependencies = with pkgs.python3Packages; [
    jupyterhub
    jupyterlab
    batchspawner
    pip
    jupyter
    jupyter-core
    notebook
  ];
  propagatedBuildInputs = with pkgs.python3Packages; [
    jupyterhub
    jupyterlab
    batchspawner
    pip
    jupyter
    jupyter-core
    notebook
  ];
  pythonImportsCheck = [ "wrapspawner" ];
}
