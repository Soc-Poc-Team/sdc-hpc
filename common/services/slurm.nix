{
  config,
  pkgs,
  lib,
  userConfig,
  ...
}:
let
  tailscaleDomain = userConfig.tailscale.domain;
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
      SelectTypeParameters=CR_Core_Memory
    '';
  };

  environment.systemPackages = with pkgs; [ slurm ];

  systemd.services.slurm-dynamic = {
    description = "Service to add a node dynamically to slurm";

    after = [
      "slurmctld.service"
      "systemd-tmpfiles-clean.service"
      "munge.service"
      "remote-fs.target"
      "pre-cluster.target"
    ];

    requires = [ "pre-cluster.target" ];

    requiredBy = [ "cluster.target" ];

    path = [
      pkgs.bash
      pkgs.slurm
      pkgs.hostname
      pkgs.libcgroup
      pkgs.coreutils
    ];

    serviceConfig = {
      ExecStart = "/bin/sh -c 'sleep 3 && ${pkgs.slurm}/bin/slurmd -Z --conf NodeAddr=$(hostname).${tailscaleDomain} --conf-server headnode.${tailscaleDomain}'";
      # ExecStartPost =
      #   let
      #     resumeslurm = pkgs.writeShellScriptBin "resume-slurm" ''
      #       STATE=$(${pkgs.slurm}/bin/scontrol show node $(hostname) 2>/dev/null | grep -oP "State=\K[^ ]+")
      #       if [ -z "$STATE" ] || [ "$STATE" = "DOWN" ] || [ "$STATE" = "DRAIN" ]; then
      #         ${pkgs.slurm}/bin/scontrol update NodeName=$(hostname) State=RESUME
      #       fi
      #     '';
      #   in
      #   "${pkgs.lib.getExe resumeslurm}";
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
