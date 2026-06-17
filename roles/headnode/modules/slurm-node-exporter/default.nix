{ pkgs, lib, ... }:

let
  slurm = pkgs.slurm;
in

pkgs.buildGoModule rec {
  pname = "slurm_exporter";
  version = "1.8.3";

  src = pkgs.fetchFromGitHub {
    owner = "SckyzO";
    repo = pname;
    rev = "refs/tags/v${version}";
    sha256 = "sha256-efV4sgq0SgMFyjobx6tC79IlzDf4GaHQ/DFFfLlnJmM=";
  };

  vendorHash = "sha256-1FjIEM1JILBVchoWDFtl2t9cUduvzsFPWsXUSmdL+BE=";

  nativeBuildInputs = with pkgs; [
    # swig
    slurm
    makeWrapper
  ];

  buildInputs = [
    slurm
  ];

  doCheck = false;

  meta = {
    description = "Slurm Exporter is a Prometheus exporter designed to scrape and expose a comprehensive range of performance and scheduling metrics from Slurm-managed clusters.";
    license = lib.licenses.gpl3Only;
    homepage = "https://github.com/SckyzO/slurm_exporter";
    maintainers = with lib.maintainers; [ turebentzin ];
    mainProgram = "slurm_exporter";
  };

}
