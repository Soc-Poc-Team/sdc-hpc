{ config, pkgs, ... }:
let
  website = pkgs.stdenvNoCC.mkDerivation {
    name = "sdc-dashboard";

    src = ./root;

    installPhase = ''
      mkdir -p $out
      cp -r ./* $out/
    '';
  };
in
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."localhost" = {
      root = website;
      listen = [
        {
          addr = "0.0.0.0";
          port = 80;
        }
      ];
      locations."/" = {
        index = "index.html";
        extraConfig = ''
          sub_filter 'localhost' '$host';
          sub_filter_once off;
          sub_filter_types text/html application/json;
        '';
      };
      locations."/jhub".proxyPass = "http://localhost:${toString config.services.jupyterhub.port}";
      locations."/grafana".proxyPass =
        "http://localhost:${toString config.services.grafana.settings.server.http_port}";
    };
  };
  networking.firewall = {
    allowedTCPPorts = [ 80 ];
  };
}
