{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  # We dont use TPM2 features and on some hardware the tpm init failes which causes the boot to
  # be delayed by 1:30min
  # See https://git.fh-aachen.de/bigdata/cape-canaveral/small-data-cluster/-/work_items/129
  systemd.tpm2.enable = false;
}
