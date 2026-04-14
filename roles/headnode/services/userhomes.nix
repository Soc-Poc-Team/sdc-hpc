{ userConfig, ... }:
{ config, ... }:
let
  userDataDir = "/homes";

  usersData = userConfig.users;

  tmpfilesRules = builtins.mapAttrs (userName: _userConfig: [
    "d ${userDataDir}/${userName}/.tmp 0755 ${userName} smalldatacluster"
    "d ${userDataDir}/${userName}/.pip-cache 0755 ${userName} smalldatacluster"
  ]) usersData;
in
{
  systemd.tmpfiles.rules = builtins.concatLists (builtins.attrValues tmpfilesRules) ++ [
    "d ${userDataDir} 0755 root root"
  ];

  services.nfs.server = {
    enable = true;
    statdPort = 4000;
    lockdPort = 4001;
    mountdPort = 4002;
    exports = ''
      ${userDataDir} *(rw,nohide,insecure,no_subtree_check)
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [
      config.services.nfs.server.statdPort
      111
      2049
      config.services.nfs.server.lockdPort
      config.services.nfs.server.mountdPort
    ];
    allowedUDPPorts = [
      111
      2049
    ];
  };
}
