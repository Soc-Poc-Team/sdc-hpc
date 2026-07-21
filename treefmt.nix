{ pkgs, ... }:
{
  projectRootFile = "flake.nix";
  settings = {
    excludes = [
      "*.toml"
      "check_stage.yml"
    ];
  };
  programs.deadnix.enable = true;
  programs.deno.enable = pkgs.stdenv.hostPlatform.system != "riscv64-linux";
  programs.mdsh.enable = true;
  programs.nixfmt.enable = true;
  programs.shellcheck.enable = pkgs.stdenv.hostPlatform.system != "riscv64-linux";
  programs.shfmt.enable = pkgs.stdenv.hostPlatform.system != "riscv64-linux";
  programs.yamlfmt.enable = true;
}
