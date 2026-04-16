{
  config,
  pkgs,
  userConfig,
  ...
}:
let
  authKey = userConfig.tailscale.authKey;
in
{
  services.tailscale.enable = true;
  services.resolved.enable = true;

  # create a oneshot job to authenticate to Tailscale
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale

    after = [
      "tailscaled.service"
    ];

    requires = [
      "network-online.target"
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
      for i in $(seq 1 30); do
        if ls /var/run/tailscale/tailscaled.sock >/dev/null 2>&1; then
          break
        fi
        sleep 1
      done

      if ! ls /var/run/tailscale/tailscaled.sock >/dev/null 2>&1; then
        echo "tailscaled is disfunctional - failing"
        exit 69 # BSD Spec: Service unavailable
      fi

      if [ "$(hostname)" = "nixos" ]; then
        echo "Running on a worker with illegal hostname - failing"
        exit 68 # BSD Spec: Hostname error
      fi

      # check if we are already authenticated to tailscale
      # do tailscale down to force and approve route if change
      # TODO: is this the behavior we want?
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi


      ${tailscale}/bin/tailscale up -authkey ${authKey} --hostname=$(hostname)

      for i in $(seq 1 30); do
        if ${tailscale}/bin/tailscale status >/dev/null 2>&1; then
          break
        fi
        sleep 1
      done

      if ! ${tailscale}/bin/tailscale status >/dev/null 2>&1; then
        echo "tailscaled failed to come up - failing"
        exit 69 # BSD Spec: Service unavailable
      fi
    '';
  };

  networking.firewall = {
    # always allow traffic from your Tailscale network
    trustedInterfaces = [ "tailscale0" ];
    # allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
}
