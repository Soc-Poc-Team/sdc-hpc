{
  pkgs,
  lib,
  ...
}:
pkgs.buildGoModule rec {
  pname = "prometheus-slurm-exporter";
  version = "1.6.10";
  rev = "refs/tags/v${version}";

  src = pkgs.fetchFromGitHub {
    inherit rev;
    owner = "rivosinc";
    repo = pname;
    sha256 = "sha256-3+/AGOXqsCiGzzrZ+aua17AVD/udN+ot1faCnOUZ76U=";
  };
  vendorHash = "sha256-qATQ47ztssQQEWSTXcPtUZnssYFtSCvh5AnldcmgO+M=";

  dependencies = with pkgs; [
    swig
  ];
  buildInputs = with pkgs; [
    swig # Ensure swig is available during the build process
  ];
  nativeBuildInputs = with pkgs; [
    swig # Ensure swig is available during the build process
  ];
}
