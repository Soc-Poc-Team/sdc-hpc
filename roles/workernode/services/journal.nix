{ pkgs, lib, ... }:

{
  # Ensure tty1 is the primary console
  boot.kernelParams = [ "console=tty1" ];

  # Disable the default getty (login shell) on tty1 only
  systemd.services."getty@tty1".enable = lib.mkForce false;
  systemd.services."autovt@tty1".enable = lib.mkForce false;

  # service to stream logs to tty1
  systemd.services.journal-on-tty1 = {
    description = "Journalctl follow on tty1";
    after = [ "systemd-user-sessions.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.systemd}/bin/journalctl -f";
      Restart = "always";
      RestartSec = 1;

      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "tty";
      TTYPath = "/dev/tty1";

      # Ensure clean terminal behavior
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;

      # Prevent spawning a shell or inheriting environment
      ExecStartPre = "${pkgs.coreutils}/bin/stty -F /dev/tty1 sane";
    };
  };
}
