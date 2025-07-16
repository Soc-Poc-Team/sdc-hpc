{ tomlConf, ... }:
{
  config,
  pkgs,
  ...
}:
let
  tailscaleDomain = tomlConf.tailscale.domain;
  authKey = tomlConf.tailscale.authKey;
in
{
  services.tailscale.enable = true;
  services.resolved.enable = true;

  # create a oneshot job to authenticate to Tailscale
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    after = [
      "network-online.target"
      "tailscale-headnode-tidy.service"
      "tailscaled.service"
    ];
    wants = [
      "network-online.target"
      "tailscale-headnode-tidy.service"
      "tailscaled.service"
    ];
    wantedBy = [ "multi-user.target" ];
    before = [
      "slurmctld.service"
      "slurmd.service"
    ];
    serviceConfig.Type = "oneshot";

    path = [
      pkgs.curl
      pkgs.hostname
    ];
    # have the job run this shell script
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      # do tailscale down to force and approve route if change
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi


      ${tailscale}/bin/tailscale up -authkey ${authKey} --hostname=$(hostname)
      sleep 2

      if [ "$(hostname)" = "nixos" ]; then
        echo "Running on a worker, getting hostname from headnode.."

        hn=$(curl -s http://headnode.${tailscaleDomain}:9100/get-hostname)

        if [ -z "$hn" ]; then
          echo "Failed to retrieve hostname from headnode."
          exit 1
        fi

        echo "Succesful hostname retrieval, setting $hn to hostname"

        hostnamectl set-hostname --transient "$hn"

        ${tailscale}/bin/tailscale up --hostname=$hn
        sleep 2

      else
        echo "Running on Headnode!"
      fi

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
