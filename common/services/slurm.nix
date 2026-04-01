{ tomlConf, ... }:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  tailscaleDomain = tomlConf.tailscale.domain;
  isHeadnode = config.networking.hostName == "headnode"; # Check if defined hostname is "headnode"
in
{
  disabledModules = [ "services/security/munge.nix" ];
  imports = [ ./custom/munge.nix ];
  services.munge = {
    enable = true;
  };
  services.slurm = {
    server.enable = isHeadnode;
    client.enable = false;
    clusterName = "bigdata";
    controlMachine = "headnode";
    controlAddr = "headnode.${tailscaleDomain}";
    partitionName = [ "debug Nodes=ALL Default=YES MaxTime=INFINITE State=UP" ];

    extraConfig = ''
      SlurmdTimeout=30
      SlurmctldParameters=enable_configless
      TreeWidth=65533
      MaxNodeCount=300
      SrunPortRange=60001-63000
      TaskPlugin=task/cgroup

      SelectType=select/cons_tres
    '';
  };

  environment.systemPackages = with pkgs; [ slurm ];

  systemd.services.slurm-dynamic = {
    description = "Service to add a node dynamically to slurm";

    # make sure tailscale is running before trying to connect to tailscale
    after = [
      "tailscale-autoconnect.service"
      "tailscaled.service"
      "slurmctld.service"
      "systemd-tmpfiles-clean.service"
      "munge.service"
      "network-online.target"
      "remote-fs.target"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    path = [
      pkgs.bash
      pkgs.slurm
      pkgs.hostname
      pkgs.libcgroup
      pkgs.coreutils
    ];

    unitConfig = {
      # https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html
      # We dont add ourself to slurm if our hostname is "nixos" - failsafe
      ConditionHost = "!nixos";
    };

    serviceConfig = {
      ExecStart = "/bin/sh -c 'sleep 3 && ${pkgs.slurm}/bin/slurmd -Z --conf NodeAddr=$(hostname).${tailscaleDomain} --conf-server headnode.${tailscaleDomain}'";
      ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      PIDFile = "/run/slurmd.pid";
      KillMode = "process";
      Type = "forking"; # the slurmd -Z command forks
      LimitMEMLOCK = "infinity";
      Delegate = "Yes";
    };
  };
  #slurm wants to set this to true, the iso wants it false. we have to set a priority via lib.mkForce
  programs.ssh.setXAuthLocation = lib.mkForce true;
  networking.firewall = {
    allowedTCPPortRanges = [
      {
        from = 60001;
        to = 63000;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 60001;
        to = 63000;
      }
    ];
    allowedTCPPorts = [
      6817 # slurmctld
      6818 # slurmd
      6819 # slurmdbd
      6820 # slurmdbd
    ];
  };
}
