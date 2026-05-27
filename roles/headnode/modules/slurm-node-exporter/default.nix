{ pkgs, ... }:

let
  # https://github.com/SchedMD/slurm/commit/c728b40c6f97bce2e1a02250c08b0d58e90b9dc9
  slurm = pkgs.slurm.overrideAttrs (_old: rec {
    version = "slurm-24-05-0-0rc1";
    src = pkgs.fetchFromGitHub {
      owner = "SchedMD";
      repo = "slurm";
      rev = "slurm-${version}";
      sha256 = "sha256-sviXuRJOpuSoOMNjGPRe11qlphk0Y1/YV/Y5M+QkWys=";
    };
  });
in

pkgs.buildGoModule rec {
  pname = "prometheus-slurm-exporter";
  version = "1.8.0";

  src = pkgs.fetchFromGitHub {
    owner = "rivosinc";
    repo = pname;
    rev = "refs/tags/v${version}";
    sha256 = "sha256-XWUjaCQBlMzWJoQzo+v7EcKGWNU3LR3betP35tNPB1w=";
  };

  vendorHash = "sha256-qATQ47ztssQQEWSTXcPtUZnssYFtSCvh5AnldcmgO+M=";

  nativeBuildInputs = with pkgs; [
    swig
    slurm
    makeWrapper
  ];

  buildInputs = [
    slurm
  ];

  postFixup = ''
    wrapProgram $out/bin/prometheus-slurm-exporter \
      --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [ slurm ]}
  '';
  doCheck = false;

  CGO_CFLAGS = "-I${slurm.dev}/include";
  CGO_LDFLAGS = "-L${slurm.out}/lib -lslurm";
  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ slurm ];

}
