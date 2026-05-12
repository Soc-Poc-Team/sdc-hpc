{ pkgs, ... }:
let
  website = pkgs.runCommand "website" { } ''
    mkdir $out
    echo '<!doctype html> <html lang="en"><head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>Small Data Cluster</title>
      </head>
      <body>
      <h1>Services:</h1>
      <ul>
      <li>
      Jupyterhub: <a href="http://localhost:8000">http://localhost:8000</a>
      </li>
      <li>Grafana: <a href="http://localhost:2342">http://localhost:2342</a></li>
      <li>Prometheus: <a href=http://localhost:9001">http://localhost:9001</a></li>
      <li>Prometheus exporter: <a href=http://localhost:9002">http://localhost:9002</a></li>
      <li>Loki: <a href="http://localhost:3100/api/v1/status/buildinfo">http://localhost:3100</a></li>
      <li>Promtail: <a href="http://localhost:28183">http://localhost:28183</a></li>
      <li>nfs-export: localhost:{4000,4001,4002}</li>
      </ul>
      </body>
      </html>' > $out/index.html
  '';
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
      locations."/jhub".proxyPass = "http://localhost:8000";
      locations."/grafana".proxyPass = "http://localhost:2342";
    };
  };
  networking.firewall = {
    allowedTCPPorts = [ 80 ];
  };
}
