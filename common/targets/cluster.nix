{ ... }:
{

  systemd.targets = {
    # All cluster services should depend on this service.
    # At the point of reaching the target, we promise that we are ready to cluster
    # TODO: later we might also verify for the workers that the headnode is ready
    "pre-cluster" = {
      description = "Ready to start cluster services";

      wants = [ "time-sync.target" ];
      requires = [ "tailscale-autoconnect.service" ];
    };

    cluster = {
      description = "small-data-cluster is running";

      requires = [
        "pre-cluster.target"
      ];

      # TODO: maybe lets require us by default.target so boot stops if we are broken?
      requiredBy = [
        "default.target"
      ];
    };
  };
}
