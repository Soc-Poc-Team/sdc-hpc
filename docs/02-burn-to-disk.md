# Burning the ISOs to boot media

## Live ISO without persistence

Next you have to burn the ISOs to seperate boot media (e.g. USB-sticks). Replace
`ID_OF_YOUR_BOOT_DEVICE_1` and `ID_OF_YOUR_BOOT_DEVICE_2` with the actual id of
your boot device you want to burn the ISO to.

⚠️ This will delete all data on the disk.

```bash
ISO=headnode.iso
# writing ISO
sudo dd if=result/iso/$ISO of=/dev/disk/by-id/ID_OF_YOUR_BOOT_DEVICE_1 status=progress && sync

ISO=workernode.iso
sudo dd if=result/iso/$ISO of=/dev/disk/by-id/ID_OF_YOUR_BOOT_DEVICE_2 status=progress && sync
```

## disko (only headnode)

The headnode Live-ISO provides a script `persist-to-disk` which turns the
Live-ISO into a fully fledged NixOS installation. It also partitions the hard
drive into bootloader, NixOS, and data partition. This enables data persistence,
worker nodes will mount this data via network (NFS). You can still use the
resulting drive on any hardware, but instead of holding data only in RAM, it is
now stored within the data partition. In other words, you can take your data
with you. This still does not affect the operating systems on your existing
hardware, but now your deployment is not stateless anymore.

Note that you can install this on the same hard drive you use to run the
headnode Live-ISO. You do not require multiple hard drives. In the booted live
iso execute the command and follow on screen instructions:

⚠️ This will delete all data on the disk.

```bash
sudo persist-to-disk /dev/disk/by-id/ID_OF_YOUR_BOOT_DEVICE
```

If you have a local nix installation, you can directly install to your hard
drive without building the isos first. The disko command will build and burn the
iso to your disk.

⚠️ This will delete all data on the disk.

```bash
sudo nix run 'github:nix-community/disko/latest#disko-install' -- --flake '/path/to/this/repo#headnode' --disk main /dev/disk/by-id/ID_OF_YOUR_BOOT_DEVICE
```

## Plug & Play

You can now plug your boot device into your existing hardware, select them via
the boot menu and wait for your cluster to boot.
