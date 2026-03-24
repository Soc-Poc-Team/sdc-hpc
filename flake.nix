{
  description = "Minimal NixOS installation media";
  nixConfig = {
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    systems.url = "github:nix-systems/default";

  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      systems,
      treefmt-nix,
      sops-nix,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (import ./utils/recursive-merge.nix) recursiveMerge;
      inherit  (import ./utils/secrets.nix) userConfig;
      mkBase =
        role: modules:
        nixpkgs.lib.nixosSystem ({
          inherit system;
          specialArgs = {
            inherit sops-nix userConfig;
          };
          modules =
            let
              roles = {
                "worker" = ./roles/workernode/workernode-configuration.nix;
                "headnode" = ./roles/headnode/headnode-configuration.nix;
              };
              roleConfig =
                if roles ? ${role} then roles.${role} else abort "Only roles 'worker' or 'headnode' are supported!";
            in
            [
              ./common
              roleConfig
              {
                config._module.args = {
                  flake = self;
                };
              }
            ]
            ++ modules;
        });

    in
    {

      # for `nix fmt`
      formatter =
        let
          # Small tool to iterate over each systems
          eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});

          # Eval the treefmt modules from ./treefmt.nix
          treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
        in
        eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          git
          qemu
          neovim
          alejandra
          mkpasswd
          sops
          age
        ];
      };

      nixosConfigurations = {
        headnode = mkBase "headnode" [
          disko.nixosModules.disko
          (
            { modulesPath, ... }:
            {
              imports = [
                (modulesPath + "/installer/scan/not-detected.nix")
                (modulesPath + "/profiles/all-hardware.nix")
              ];
            }
          )
          {
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;
            boot.initrd.availableKernelModules = [
              "xhci_pci"
              "ahci"
              "nvme"
              "usbhid"
              "uas"
              "sd_mod"
              "rtsx_pci_sdmmc"
            ];
            system.stateVersion = "24.05";
          }
          {
            disko.devices = {
              disk = {
                main = {
                  # When using disko-install, we will overwrite this value from the commandline
                  device = "/dev/disk/by-id/some-disk-id";
                  type = "disk";
                  content = {
                    type = "gpt";
                    partitions = {
                      MBR = {
                        type = "EF02"; # for grub MBR
                        size = "1M";
                        priority = 1; # Needs to be first partition
                      };
                      ESP = {
                        type = "EF00";
                        size = "500M";
                        content = {
                          type = "filesystem";
                          format = "vfat";
                          mountpoint = "/boot";
                          mountOptions = [ "umask=0077" ];
                        };
                      };
                      root = {
                        size = "100%";
                        content = {
                          type = "filesystem";
                          format = "ext4";
                          mountpoint = "/";
                        };
                      };
                    };
                  };
                };
              };
            };
          }
        ];

        workernode = mkBase "worker" { };
      };
      packages.x86_64-linux = rec {
        default = headnode.config.system.build.isoImage;
        head = headnode.config.system.build.isoImage;
        worker = workernode.config.system.build.isoImage;

        headnode = mkBase "headnode" [
          (
            { modulesPath, ... }:
            {
              imports = [
                (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
              ];
            }
          )
          {
            boot.kernelParams = [ "copytoram" ];
            image.baseName = nixpkgs.lib.mkForce "headnode";
          }
        ];
        workernode = mkBase "worker" [
          (
            { ... }:
            {
              networking.hostName = "";
            }
          )
        ];

        vm_headnode =
          (mkBase "headnode" [
            (nixpkgs + "/nixos/modules/virtualisation/qemu-vm.nix")
            (nixpkgs + "/nixos/modules/profiles/qemu-guest.nix")
            (
              { config, pkgs, ... }:
              let
                isoimage = pkgs.runCommandLocal "headnode.iso" { } ''
                  set -Eeuf -o pipefail
                  set -x
                  headnode=${self.outputs.packages.x86_64-linux.default}/iso/headnode.iso
                  if [ "${toString config.isoImage.compressImage}" ]; then
                    ${pkgs.zstd}/bin/zstd --decompress --keep --stdout "''${headnode}.zst" > $out
                  else
                    ln -s "$headnode" $out
                  fi
                '';
              in
              {
                virtualisation = {
                  memorySize = 8192;
                  cores = 6;
                  useDefaultFilesystems = false;
                  diskImage = "/dev/null";
                  # useBootLoader = true;
                  graphics = false;
                  fileSystems."/" = {
                    fsType = "tmpfs";
                    options = [ "mode=0755" ];
                  };
                  forwardPorts = [
                    {
                      from = "host";
                      host.port = 2222;
                      guest.port = 22;
                    }
                  ];
                  qemu = {
                    options = [ ];
                    drives = [
                      {
                        file = "${isoimage}";
                        driveExtraOpts = {
                          media = "cdrom";
                          format = "raw";
                          readonly = "on";
                        };
                      }
                    ];
                  };
                };
              }
            )
          ]).config.system.build.vm;

        vm_workernode =
          (mkBase "worker" [
            (nixpkgs + "/nixos/modules/virtualisation/qemu-vm.nix")
            (nixpkgs + "/nixos/modules/profiles/qemu-guest.nix")
            (
              { config, pkgs, ... }:
              let
                isoimage = pkgs.runCommandLocal "workernode.iso" { } ''
                  set -Eeuf -o pipefail
                  set -x
                  workernode=${self.outputs.packages.x86_64-linux.worker}/iso/workernode.iso
                  if [ "${toString config.isoImage.compressImage}" ]; then
                    ${pkgs.zstd}/bin/zstd --decompress --keep --stdout "''${workernode}.zst" > $out
                  else
                    ln -s "$workernode" $out
                  fi
                '';
              in
              {
                virtualisation = {
                  memorySize = 4096;
                  cores = 4;
                  useDefaultFilesystems = false;
                  #diskImage = "/dev/null";
                  # useBootLoader = true;
                  graphics = false;
                  fileSystems."/" = {
                    fsType = "tmpfs";
                    options = [ "mode=0755" ];
                  };
                  forwardPorts = [
                    {
                      from = "host";
                      host.port = 2223;
                      guest.port = 22;
                    }
                  ];
                  qemu = {
                    drives = [
                      {
                        file = "${isoimage}";
                        driveExtraOpts = {
                          media = "cdrom";
                          format = "raw";
                          readonly = "on";
                        };
                      }
                    ];
                  };
                };
              }
            )
          ]).config.system.build.vm;
      };
      apps.x86_64-linux = {
        default = {
          type = "app";
          program = "${self.outputs.packages.x86_64-linux.vm_headnode}/bin/run-headnode-vm";
        };

        worker = {
          type = "app";
          program = "${self.outputs.packages.x86_64-linux.vm_workernode}/bin/run-worker-vm";
        };
      };
    };
}
