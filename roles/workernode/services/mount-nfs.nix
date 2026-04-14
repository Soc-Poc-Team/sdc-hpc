{ pkgs, userConfig, ... }:
let
  tailscaleDomain = userConfig.tailscale.domain;
  # example: mkNfsMounter nfs:/export/home /home
  #https://github.com/TUM-DSE/doctor-cluster-config/blob/5043a91af26d51fce87fa4b902cd8843671b6ea2/modules/nfs/client.nix#L14
  mkNfsMounter = nfsUrl: mountpoint: {
    description = "Mount ${mountpoint}";
    after = [ "network.target" ];
    # 1. Mount nfs before making shells available to users:
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # 2. Retry try a few times on failure, before continuing with boot (1.)
      ExecStart = pkgs.writeShellScript "nfs-mount-wrapper" ''
        # TODO upgrade to nfs4 again, once linux 6.4 (e.g. clara) has working nfs4 again
        mountcmd="${pkgs.util-linux}/bin/mount -t nfs -o nofail,timeo=14 ${nfsUrl} ${mountpoint}"
        restartsec="5"

        mkdir -p ${mountpoint}
        for i in {1..10}; do
          echo "Mounting nfs. Attempt $i/10"
          echo "> $mountcmd"
          $mountcmd
          ret=$?
          if [[ $ret == 0 ]]; then
            exit 0
          else
            echo "Mounting nfs failed. Retrying in $restartsec sec"
            sleep $restartsec
          fi
        done
        exit $ret
      '';
      ExecStop = "${pkgs.util-linux}/bin/umount ${mountpoint}";
      # 3. If (2.) does not suffice, or nfs breaks during runtime, you shall still restart.
      Restart = "on-failure";
      RestartSec = 10;
    };
  };

  nfsServerMountPoint = "headnode.${tailscaleDomain}:/homes";
  workerNodeMountPoint = "/homes";
in
{
  systemd.services = {
    nfs-home = mkNfsMounter nfsServerMountPoint workerNodeMountPoint;
  };
  services.nfs.server.enable = true;
  boot.supportedFilesystems = [ "nfs" ];
  services.rpcbind.enable = true;
  boot.initrd = {
    supportedFilesystems = [ "nfs" ];
    kernelModules = [ "nfs" ];
  };
}
