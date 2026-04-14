{ tomlConf, ... }:
{ config, pkgs, ... }:
let
  authKey = tomlConf.tailscale.authKey;
in
{
  services.tailscale.enable = true;
  services.resolved.enable = true;

  # create a oneshot job to authenticate to Tailscale
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    requires = [
      "network-online.target"
      "tailscale-headnode-tidy.service"
      "tailscaled.service"
    ];

    wantedBy = [ "pre-cluster.target" ];

    serviceConfig.Type = "oneshot";

    path = [
      pkgs.curl
      pkgs.hostname

    ];
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      if [ "$(hostname)" = "nixos" ]; then
        echo "Running on a worker with illegal hostname - failing"
        exit 1
      fi

      # check if we are already authenticated to tailscale
      # do tailscale down to force and approve route if change
      # TODO: is this the behavior we want?
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi


      ${tailscale}/bin/tailscale up -authkey ${authKey} --hostname=$(hostname)
      sleep 2
    '';
  };

  networking.firewall = {
    # always allow traffic from your Tailscale network
    trustedInterfaces = [ "tailscale0" ];
    # allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
}
