{ pkgs, ... }:

let

  pharos = pkgs.callPackage ../../../../packages/pharos { };
  version_file = ../../../../VERSION;
in
{

  systemd.services.pharosd = {
    enable = true;

    description = "Pharosd";

    requires = [ "cluster.target" ];
    after = [ "cluster.target " ];
    requiredBy = [ "default.target" ];

    path = [
      pharos
    ];

    serviceConfig = {
      ExecStart = "pharosd 1010 ${version_file}";
    };
  };

}
