{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "sdc-hitman";

  runtimeInputs = [
    pkgs.openssh
    pkgs.slurm
  ];

  text = builtins.readFile ./sdc-hitman.sh;
}
