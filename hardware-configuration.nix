# Hardware configuration for NixOS in VirtualBox
# This file is optimized for VirtualBox virtual machines

{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # Boot configuration for VirtualBox
  boot.initrd.availableKernelModules = [ "ata_piix" "ohci_pci" "ehci_pci" "ahci" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # File systems configuration (update UUIDs after installation)
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/your-root-uuid-here";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/your-boot-uuid-here";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/your-swap-uuid-here"; }
    ];

  # VirtualBox specific optimizations
  # Enable VirtualBox Guest Additions
  virtualisation.virtualbox.guest.enable = true;
  # Note: x11 option is deprecated in NixOS 25.05+

  # Networking for VirtualBox
  networking.useDHCP = lib.mkDefault true;

  # Hardware platform
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  
  # CPU settings for VirtualBox (usually no frequency scaling needed)
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  
  # No specific CPU microcode updates needed in VM
  # hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
