{
  lib,
  fetchFromGitHub,
  python3Packages,
  ...
}:
python3Packages.buildPythonPackage rec {
  pname = "wrapspawner";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "pandalanax";
    repo = pname;
    rev = "2a366cdce1ada90630e6ac38e8461e508ba7106a";
    sha256 = "sha256-PuCHN2qfBghjyv2OCc57kPCRyJk4wthRSeAO9HbilLQ=";
  };

  build-system = with python3Packages; [
    setuptools
    wheel
  ];

  dependencies = with python3Packages; [ jupyterhub ];
  propagatedBuildInputs = [ python3Packages.jupyterhub ];
  pythonImportsCheck = [ "wrapspawner" ];
  meta = with lib; {
    description = "Wrapspawner: A spawner for Jupyterhub to wrap other spawners and allow the user to choose among them.";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
