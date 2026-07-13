{ lib, ... }:
{
  systemd.services.slurmctld = {
    wantedBy = lib.mkForce [ ]; # We dont want individual cluster services to be wanted by a target other then cluster.target
    requires = [ "pre-cluster.target" ];
    after = [ "pre-cluster.target" ];
    requiredBy = [ "cluster.target" ];
  };
}
