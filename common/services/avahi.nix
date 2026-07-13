{ ... }:
{
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
  };

  systemd.services.avahi-daemon = {
    requires = [ "pre-cluster.target" ];
    after = [ "pre-cluster.target" ];
  };
}
