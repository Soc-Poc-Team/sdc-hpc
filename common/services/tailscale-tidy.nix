{
  userConfig,
  ...
}:
{
  systemd.services.tailscale-tidy = {
    description = "clear machine entry on tailscale api";

    requiredBy = [
      "tailscale-autoconnect.service"
    ];

    requires = [
      "network-online.target"
    ];

    after = [
      "network-online.target"
    ];

    serviceConfig.Type = "oneshot";

    path = [ ];
    script = "";
  };
}
